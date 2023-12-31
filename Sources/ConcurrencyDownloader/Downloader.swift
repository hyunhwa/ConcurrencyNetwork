//
//  Downloader.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/08.
//

import Foundation

/// 다운로더
///
/// 백그라운드 다운로드와 다운로드 진행률, 다운로드 일시정지를 지원하기 위해 downloadTask로 구현하였습니다.
///
/// 단일 다운로드와 멀티 다운로드를 모두 지원합니다.
///
/// Downloadable을 만족하는 파일 객체를 다음과 같이 정의합니다.
/// ```swift
/// struct DownloadableObject {
///     let fileURL: URL
/// }
///
/// extension DownloadableObject: Downloadable {
///     var directoryURL: URL {
///         let directoryPaths = NSSearchPathForDirectoriesInDomains(
///             .libraryDirectory,
///             .userDomainMask,
///             true
///         )
///
///         let directoryURL = URL(fileURLWithPath: directoryPaths.first!)
///         return directoryURL.appendingPathComponent("ConcurrencyDownload")
///     }
///
///     var sourceURL: URL {
///         fileURL
///     }
/// }
/// ```
///
/// 단일 다운로드 이벤트를 수신하기 위해서 다음과 같이 호출 가능합니다.
/// ```swift
/// let downloader = Downloader(
///     progressInterval: 10 // 진행률 업데이트 이벤트를 수신 간격 (0으로 설정 시 byte 정보가 변경될 때마다 이벤트 수신)
/// let fileInfo = mockupDownloadableImageInfo1
/// for try await event in try await downloader.events(fileInfo: fileInfo) {
///     switch event {
///     case let .update(currentBytes, totalBytes): // 다운로드 진행률 갱신
///     case let .completed(data, downloadInfo): // 다운로드 완료
/// }
/// ```
///
/// 멀티 다운로드 이벤트를 수신하실 때는 다음과 같이 호출 가능합니다.
/// ```swift
/// let downloader = Downloader()
/// let fileInfos = [
///     mockupDownloadableVideoInfo1,
///     mockupDownloadableVideoInfo2
/// ]
/// for try await event in try await downloader.events(
///     fileInfos: fileInfos
/// ) {
///     switch event {
///     case let .allCompleted(downloadInfos): // 전체 파일 다운로드 완료
///     case let .unit(events): // 단일 다운로드 이벤트 수신
///     }
/// }
/// ```
///
/// 전역에서 싱글톤 객체로 사용하려는 경우 프로젝트에서 @globalActor 키워드를 붙여 Class나 Struct를 생성합니다.
/// ```swift
/// @globalActor
/// struct GlobalDownloader {
///     static var shared = Downloader()
/// }
///```
///```swift
/// @globalActor
/// final class GlobalDownloader {
///     static var shared = Downloader()
/// }
/// ```
public actor Downloader: NSObject {
    /// 다운로드 받을 파일 정보
    private var downloadInfos: [DownloadInfo]?
    /// 다건 다운로드 이벤트 흐름
    private var continuation: AsyncThrowingStream<MultiDownloadEvent, Error>.Continuation?
    /// 진행률 갱신 간격 (기본 1%) - 0으로 지정한 경우 bytes 정보가 변경될 때마다 이벤트 발생
    private var progressInterval: Double
    /// 다운로드 세션
    private var session: URLSession?
    /// 세션 설정
    /// - 셀룰러 네트워크 접근 허용
    /// - 네트워크 연결 대기
    private var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.waitsForConnectivity = true
        return configuration
    }
    
    /// 다운로더 생성
    /// - Parameter progressInterval: 진행률 갱신 간격 (기본 1%) - 0으로 지정한 경우 bytes 정보가 변경될 때마다 이벤트 발생
    public init(progressInterval: Double = 1) {
        self.progressInterval = progressInterval
        super.init()
    }
    
    /// 다건 다운로드 이벤트 추적
    /// - Parameters:
    ///   - fileInfos: 다운로드 받을 파일 정보 리스트
    /// - Returns: 다건 다운로드 이벤트 흐름 (오류 발생 가능성 있음)
    public func events(
        fileInfos: [any Downloadable]
    ) -> AsyncThrowingStream<MultiDownloadEvent, Error> {
        let downloadInfos = fileInfos.map { fileInfo in
            DownloadInfo(fileInfo: fileInfo)
        }
        self.downloadInfos = downloadInfos
       
        return AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.yield(.start(downloadInfos: downloadInfos))
            
            Task {
                await withThrowingTaskGroup(
                    of: AsyncThrowingStream<DownloadEvent, Error>.self
                ) { [unowned self] group in
                    for downloadInfo in downloadInfos {
                        group.addTask {
                            let event = try await self.download(downloadInfo)
                            continuation.yield(.unit(event))
                            return event
                        }
                    }
                }
            }
        }
    }
    
    /// 단일 다운로드 이벤트 추적
    /// - Parameters:
    ///   - fileInfo: 다운로드 받을 파일 정보
    /// - Returns: 단일 다운로드 이벤트 흐름 (오류 발생 가능성 있음)
    public func events(
        fileInfo: any Downloadable
    ) throws -> AsyncThrowingStream<DownloadEvent, Error> {
        let downloadInfo = DownloadInfo(fileInfo: fileInfo)
        downloadInfos = [downloadInfo]
        
        return try download(downloadInfo)
    }
    
    /// 다운로드 일시정지
    public func pause() async {
        downloadInfos?
            .filter { $0.isCompleted == false && $0.isDownloading }
            .forEach { downloadInfo in
                Task {
                    await pause(downloadInfo: downloadInfo)
                }
            }
    }
    
    /// 다운로드 취소
    ///
    /// 사용자에 의한 취소
    public func cancel() {
        stop(DownloadError.canceledByUser)
    }
    
    /// 다운로드 중지
    public func stop( _ error: Error? = nil) {
        continuation?.finish(throwing: error)
        continuation = nil
        
        downloadInfos?.forEach { downloadInfo in
            stop(downloadInfo: downloadInfo, error: error)
        }
        
        if error == nil {
            downloadInfos = nil
        }
        
        session?.finishTasksAndInvalidate()
        session = nil
    }
    
    private func stop(
        downloadInfo: DownloadInfo,
        error: Error?
    ) {
        guard let index = downloadInfos?.index(of: downloadInfo) else { return }
        
        downloadInfos?[index].resumeData = nil
        downloadInfos?[index].downloadTask?.cancel()
        downloadInfos?[index].downloadTask = nil
        downloadInfos?[index].error = error
        downloadInfos?[index].continuation?.finish(throwing: error)
        downloadInfos?[index].continuation = nil
    }
    
    /// 다운로드 재시작
    /// - Note:
    /// 다음 조건이 충족되는 경우에만 다운로드를 재개할 수 있습니다.
    /// (https://developer.apple.com/documentation/foundation/urlsessiondownloadtask/1411634-cancel)
    /// - 처음 요청한 이후 리소스가 변경되지 않았습니다.
    /// - 작업이 HTTP 또는 HTTPS GET요청 입니다.
    /// - 서버는 응답에서 ETag 또는 Last-Modified 헤더(또는 둘 다)를 제공합니다.
    /// - 서버는 바이트 범위 요청을 지원합니다.
    /// - 디스크 공간 부족에 대한 응답으로 시스템에서 임시 파일을 삭제하지 않았습니다.
    public func resume() async {
        downloadInfos?
            .filter { $0.isCompleted == false }
            .forEach { downloadInfo in
                runNextIfNeeded(downloadInfo)
            }
    }
    
    /// 단일 다운로드 실행 (내부 호출용)
    private func download(
        _ downloadInfo: DownloadInfo
    ) throws -> AsyncThrowingStream<DownloadEvent, Error> {
        try createDownloadFolderIfNeeded(
            path: downloadInfo.fileInfo.directoryURL.path
        )
        createSessionIfNeeded()
        
        let downloadTask = session?.downloadTask(
            with: request(fileInfo: downloadInfo.fileInfo)
        )
        
        let sourceURL = downloadInfo.fileInfo.sourceURL
        let index = downloadInfos!.index(withURL: sourceURL)!
        downloadInfos![index].downloadTask = downloadTask
        
        return AsyncThrowingStream { continuation in
            downloadInfos![index].continuation = continuation
            runNextIfNeeded(downloadInfos![index])
        }
    }
    
    /// 다운로드 받을 폴더 경로가 없는 경우 생성
    /// - Parameter path: 다운로드 받을 폴더 path
    private func createDownloadFolderIfNeeded(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) == false
        else { return }
    
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    /// 세션 객체가 없는 경우 생성
    private func createSessionIfNeeded() {
        guard session == nil else { return }
        
        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }
    
    /// 다운로드 시작 (재시작)
    /// - Parameter task: 다운로드 테스크
    private func resume(task: URLSessionDownloadTask?) {
        guard let downloadTask = task else { return }
        downloadTask.resume()
    }
    
    /// 다운로드 정보 일시 중지
    ///
    /// - Note:
    /// - 재시작 다운로드 조건이 충족되지 않으면 cancelByProducingResumeData == nil 발생
    /// - resumedata로 다운로드를 재시작할 경우, originalRequest 정보가 없음 주의!!
    private func pause(downloadInfo: DownloadInfo) async {
        if let resumeData = await downloadInfo.downloadTask?.cancelByProducingResumeData() {
            if let index = downloadInfos?.index(of: downloadInfo) {
                let taskWithResumeData = session?.downloadTask(withResumeData: resumeData)
                downloadInfos?[index].resumeData = resumeData
                downloadInfos?[index].downloadTask = taskWithResumeData
            }
        } else {
            downloadInfo.downloadTask?.suspend()
        }
    }
    
    /// 다운로드 요청 객체
    /// - Parameter fileInfo: 다운로드받을 파일 정보
    /// - Returns: 다운로드 요청 객체
    private func request(fileInfo: Downloadable) -> URLRequest {
        var request = URLRequest(
            url: fileInfo.sourceURL,
            cachePolicy: fileInfo.cachePolicy,
            timeoutInterval: fileInfo.timeoutInterval
        )
        request.allHTTPHeaderFields = fileInfo.headers
        request.httpMethod = fileInfo.httpMethod.rawValue
        return request
    }
    
    /// 현재 처리 중인 데이터의 task의 url 정보
    /// 다운로드가 일시중지된 경우, originalRequest 에서 URL 정보를 가져올 수 없으므로 Task 로 추적
    private func urlString(withTask task: URLSessionTask) -> String {
        downloadInfos?.urlString(withTask: task) ?? ""
    }
    
    /// 다운로드 완료 시점 이벤트 호출
    private func didFinishDownloading(
        withTask task: URLSessionDownloadTask,
        data: Data
    ) {
        let index = downloadInfos?.index(withTask: task) ?? 0
        let totalIndex = downloadInfos?.count
        let currentIndex = downloadInfos?.filter { $0.isCompleted }.count
        let isAllCompleted = currentIndex == totalIndex
        
        downloadInfos?[index].continuation?.yield(
            .completed(data: data, downloadInfo: downloadInfos![index])
        )
        downloadInfos?[index].continuation?.finish()

        runNextIfNeeded()
        
        if isAllCompleted {
            continuation?.yield(.allCompleted(downloadInfos!))
            continuation?.finish()
            continuation = nil
            downloadInfos = nil
        }
    }
    
    /// 다운로드 종료 시점에 발생된 오류 처리
    private func didFinishDownloading(
        withTask task: URLSessionDownloadTask,
        error: Error
    ) {
        let index = downloadInfos?.index(withTask: task) ?? 0
        let totalIndex = downloadInfos?.count
        let currentIndex = downloadInfos?.filter { $0.isCompleted }.count
        let isAllCompleted = currentIndex == totalIndex
        
        downloadInfos?[index].error = error
        downloadInfos?[index].continuation?.finish(throwing: error)
        
        runNextIfNeeded()
        
        if isAllCompleted {
            continuation?.finish(throwing: error)
            continuation = nil
            downloadInfos = nil
        }
    }
    
    /// 다운로드 파일 데이터 저장
    private func saveToLocalFileURL(
        withTask task: URLSessionDownloadTask,
        data: Data
    ) throws {
        guard let index = downloadInfos?.index(withTask: task),
              let destinationURL = downloadInfos?[index].fileInfo.destinationURL
        else { return }
        
        guard destinationURL.isFileURL
        else { throw DownloadError.invalidFileURL }
        
        let created = FileManager.default.createFile(
            atPath: destinationURL.path,
            contents: data
        )
        
        if created == false {
            throw DownloadError.noDataInLocal
        }
    }
    
    /// 다운로드받을 수 있는 파일이 있는 경우 다운로드받음
    /// - Parameter downloadInfo: 다운로드받을 파일을 특정하고 싶은 경우 지정
    private func runNextIfNeeded( _ downloadInfo: DownloadInfo? = nil) {
        let hasActiveTask = downloadInfos?.hasActiveTask ?? false
        let nextDownloadInfo = downloadInfo ?? downloadInfos?.first { $0.isSuspended }
        
        guard hasActiveTask == false, // 다운로드 중인 컨텐츠가 없을 때
              let downloadInfo = nextDownloadInfo // 다음 컨텐츠가 있음
        else { return }
        
        if let index = downloadInfos?.index(of: downloadInfo) {
            downloadInfos?[index].continuation?.yield(
                .start(index: index, downloadInfo: downloadInfo)
            )
        }
        
        resume(task: downloadInfo.downloadTask)
    }
}

// MARK: - URLSessionDelegate
extension Downloader: URLSessionDelegate {
    public nonisolated
    func urlSession(
        session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        Task {
            await urlSession(
                session,
                task: task,
                didCompleteWithError: error
            )
        }
    }
    
    /// 다운로드 중 오류 발생을 추적하기 위한 비동기식 함수 (동일 함수명의 동기함수에서 호출됨)
    /// - Parameters:
    ///   - task: 다운로드 Task
    ///   - error: 다운로드 중 발생된 에러 (resumeData를 가져올 수 있는 경우 저장됨)
    private func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) async {
        guard let error = error else { return }
        
        if let resumeData = error.resumeData,
           let index = downloadInfos?.index(withTask: task)
        {
            downloadInfos?[index].downloadTask = session.downloadTask(withResumeData: resumeData)
            downloadInfos?[index].error = error
            downloadInfos?[index].continuation?.finish(throwing: error)
        }
        
        continuation?.finish(throwing: error)
    }
}

// MARK: - URLSessionDownloadDelegate
extension Downloader: URLSessionDownloadDelegate {
    public nonisolated
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        if let data = try? Data(contentsOf: location) {
            Task {
                await urlSession(
                    session,
                    downloadTask: downloadTask,
                    didFinishDownloaded: data
                )
            }
        } else {
            Task {
                await didFinishDownloading(
                    withTask: downloadTask,
                    error: DownloadError.noDataInLocal
                )
            }
        }
    }
    
    public nonisolated
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task {
            await urlSession(
                session,
                downloadTask: downloadTask,
                didWriteData: didWriteData,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }
    
    /// 다운로드 완료를 추적하기 위한 비동기 함수(동일함수명의 동기함수에서 호출됨)
    /// - Parameters:
    ///   - downloadTask: 다운로드 Task
    ///   - location: 다운로드받은 임시파일 데이터
    private func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloaded data: Data
    ) async {
        guard downloadTask.response?.isOK ?? false
        else { // 서버 오류 발생시 오류 반환
            didFinishDownloading(withTask: downloadTask, error: DownloadError.serverError)
            return
        }
        
        do {
            try saveToLocalFileURL(withTask: downloadTask, data: data)
            didFinishDownloading(withTask: downloadTask, data: data)
        } catch {
            didFinishDownloading(withTask: downloadTask, error: error)
        }
    }
    
    /// 다운로드 진행률을 추적하기 위한 비동기 함수 (동일한 함수명의 동기함수에서 호출됨)
    /// - Parameters:
    ///   - downloadTask: 다운로드 Task
    ///   - totalBytesWritten: 다운로드 완료된 데이터 양
    ///   - totalBytesExpectedToWrite: 예상되는 총 다운로드 데이터 양
    private func urlSession(
        _: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData _: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) async {
        guard let index = downloadInfos?.index(withTask: downloadTask)
        else { return }
        
        let beforeBytes = downloadInfos?[index].currentBytes ?? 0
        let currentBytes = Double(totalBytesWritten)
        let totalBytes = Double(totalBytesExpectedToWrite)
        
        let beforeProgress = floor(beforeBytes * 100 / totalBytes)
        let currentProgress = floor(currentBytes * 100 / totalBytes)
        let canUpdateProgress = abs(currentProgress - beforeProgress) >= progressInterval
        
        guard canUpdateProgress else { return }
        
        downloadInfos?[index].currentBytes = currentBytes
        downloadInfos?[index].totalBytes = totalBytes
        downloadInfos?[index].continuation?.yield(
            .update(
                currentBytes: currentBytes,
                totalBytes: totalBytes
            )
        )
    }
}

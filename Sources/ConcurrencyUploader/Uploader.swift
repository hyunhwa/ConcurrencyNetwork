//
//  Uploader.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/03.
//

import Foundation

/// 업로더
///
/// 백그라운드 업로드와 업로드 진행률, 추후 재개 가능한 업로드 지원을 위해 UploadTask 로 구현하였습니다.
///
/// 단일 업로드와 멀티 업로드를 모두 지원합니다.
///
/// Uploadable을 만족하는 파일 객체는 다음과 같이 정의합니다.
/// ```swift
/// struct UploadableImageFileInfo {
///     var fileName: String
///     var filePath: String
///     var fileMimeType: String
///     var fileKey: String
/// }
///
/// extension UploadableImageFileInfo: Uploadable {
///     var headers: [String : String]? {
///         ["Authorization" : "your-authorization"]
///     }
///
///     var url: URL {
///         get throws {
///             URL(string: "https://your-api-endpoint.com/upload")!
///         }
///     }
///
///     var content: UploadContent {
///         .file(
///             url: URL(string: filePath)!,
///             name: fileKey
///         )
///     }
/// }
/// ```
///
/// 단일 업로드 이벤트를 수신하기 위해서는 다음과 같이 호출 가능합니다.
/// ```swift
/// let uploader = Uploader(
///     progressInterval: 10, // 업로드 진행률 이벤트 수신 간격
///     maxActiveTask: 5    // 동시 활성화될 uploadTask 숫자 (1로 설정 시 순차 업로드)
/// )
///
/// for try await event in try await uploader.events(
///     fileInfo: mockupUploadableImageFileInfo1
/// ) {
///     switch event {
///     case let .update(currentBytes, totalBytes): // 업로드 진행률 갱신
///     case let .completed(data, uploadInfo): // 업로드 완료
/// }
/// ```
///
/// 멀티 업로드 이벤트를 수신하기 위해서는 다음과 같이 호출합니다.
/// ```swift
/// let fileInfos: [any Uploadable] = [
///     mockupUploadableImageFileInfo1,
///     mockupUploadableImageFileInfo2,
///     mockupUploadableVideoFileInfo1,
///     mockupUploadableVideoFileInfo2
/// ]
///
/// for try await event in try await uploader.events(
///     fileInfos: fileInfos
/// ) {
///     switch event {
///     case let .allCompleted(uploadInfos): // 전체 업로드 완료
///     case let .unit(unitEvents):
///         for try await unitEvent in unitEvents {
///             switch unitEvent {
///             case let .completed(data, uploadInfo):
///             case let .update(currentBytes, totalBytes):
///         }
///     }
/// }
/// ```
/// 전역에서 싱글톤 객체로 사용하려는 경우 프로젝트에서 @globalActor 키워드를 붙여 Class나 Struct를 생성합니다.
/// ```swift
/// @globalActor
/// struct GlobalUploader {
///     static var shared = Uploader()
/// }
///```
///```swift
/// @globalActor
/// final class GlobalUploader {
///     static var shared = Uploader()
/// }
/// ```
public actor Uploader: NSObject {
    /// 최대 활성화 Task 수 (성능 이슈를 감안하여 5로 제한)
    let limitActiveTask = 5
    /// 업로드 정보 리스트
    var uploadInfos: [UploadInfo]?
    /// 멀티 업로드 이벤트 흐름
    var continuation: AsyncThrowingStream<MultiUploadEvent, Error>.Continuation?
    /// 동시에 활성화 가능한 최대 Task 수
    var maxActiveTask: Int
    /// 진행률 디버깅 간격 (기본 1%) - 0으로 지정한 경우 bytes 정보가 변경될 때마다 이벤트 발생
    var progressInterval: Double
    /// 업로더에 사용될 세션
    lazy var session: URLSession = .init(
        configuration: configuration,
        delegate: self,
        delegateQueue: nil
    )
    
    /// 세션 설정
    /// - 셀룰러 네트워크 접근 허용
    /// - 네트워크 연결 대기
    private var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = true
        configuration.httpMaximumConnectionsPerHost = maxActiveTask
        configuration.networkServiceType = .background
        configuration.httpShouldUsePipelining = false
        configuration.waitsForConnectivity = true
        return configuration
    }
    
    /// 업로더 생성
    /// - Parameters:
    ///   - progressInterval: 업로드 진행률 이벤트 수신 간격 (기본: 10 %)
    ///   - maxActiveTask: 최대 활성화될 task 수 (기본: 1개)
    ///   - willResetDirectory : 업로드 폴더를 비우고 재설정할 것인지 여부 (기본 : false)
    public init(
        progressInterval: Double = 10,
        maxActiveTask: Int = 1,
        willResetDirectory: Bool = false
    ) {
        self.progressInterval = progressInterval
        self.maxActiveTask = min(max(1, maxActiveTask), limitActiveTask)
        
        super.init()
        
        Task {
            do {
                try await createUploadFolderIfNeeded(willResetDirectory)
            } catch { }
        }
    }
    
    /// 멀티 업로드 이벤트 흐름
    /// - Parameter fileInfos: 업로드할 파일 리스트
    /// - Returns: 멀티 업로드 이벤트 흐름 (단일 이벤트 포함)
    public func events(
        fileInfos: [any Uploadable]
    ) async throws -> AsyncThrowingStream<MultiUploadEvent, Error> {
        let uploadInfos = fileInfos.map { fileInfo in
            UploadInfo(fileInfo: fileInfo)
        }
        self.uploadInfos = uploadInfos
        
        return AsyncThrowingStream<MultiUploadEvent, Error> { continuation in
            self.continuation = continuation
            continuation.yield(.start(uploadInfos: uploadInfos))
            
            Task {
                await withThrowingTaskGroup(
                    of: AsyncThrowingStream<UploadEvent, Error>.self
                ) { group in
                    for uploadInfo in uploadInfos {
                        group.addTask {
                            let event = try await self.upload(uploadInfo)
                            continuation.yield(.unit(event))
                            return event
                        }
                    }
                }
            }
        }
    }
    
    /// 단일 업로드 이벤트 흐름
    /// - Parameter fileInfo: 업로드할 파일 정보
    /// - Returns: 단일 업로드 이벤트 흐름
    public func events(
        fileInfo: any Uploadable
    ) async throws -> AsyncThrowingStream<UploadEvent, Error> {
        let uploadInfo = UploadInfo(fileInfo: fileInfo)
        self.uploadInfos = [uploadInfo]
        
        return try await upload(uploadInfo)
    }
 
    /// 업로드 재시작
    ///
    /// - Note:
    /// - 2023년 WWDC(https://developer.apple.com/videos/play/wwdc2023/10006/?time=537) 에서 발표된
    /// 업로드 재개를 지원하는 서버에서는 서버 오류가 발생되어도 이어 전송하기가 가능하지만 기본적으로 이어받기가 불가하다.
    /// 사용자에 의해 task를 중단한 경우에 resume을 지원한다.
    public func resume() {
        uploadInfos?
            .filter { $0.isCompleted == false }
            .forEach { uploadInfo in
                self.runNextIfNeeded(uploadInfo)
            }
    }
    
    /// 업로드 일시정지
    ///
    /// - Note:
    /// - 2023년 WWDC(https://developer.apple.com/videos/play/wwdc2023/10006/?time=537) 에서 발표된
    /// 업로드 재개를 지원하는 서버에서는 서버 오류가 발생되어도 이어 전송하기가 가능하지만 기본적으로 이어받기가 불가하다.
    /// 사용자에 의해 task를 중단한 경우에 resume을 지원한다.
    public func pause() {
        uploadInfos?
            .filter { $0.isCompleted == false && $0.isUploading }
            .forEach { uploadInfo in
                uploadInfo.task?.suspend()
            }
    }
    
    /// 업로드 중지
    ///
    /// 사용자에 의해 업로드를 완전히 종료한다.
    public func stop() {
        continuation?.finish(throwing: UploadError.canceledByUser)
        uploadInfos?.forEach { uploadInfo in
            stop(uploadInfo: uploadInfo)
        }
        uploadInfos = nil
    }
    
    private func stop(uploadInfo: UploadInfo) {
        guard let index = uploadInfos?.index(fileInfo: uploadInfo.fileInfo)
        else { return }
        
        uploadInfos?[index].task?.cancel()
        uploadInfos?[index].task = nil
        uploadInfos?[index].error = UploadError.canceledByUser
        uploadInfos?[index].continuation?.finish(throwing: UploadError.canceledByUser)
    }
    
    /// 업로드를 위한 Root 폴더 URL
    private var uploadFolderURL: URL {
        let directoryPaths = NSSearchPathForDirectoriesInDomains(
            .libraryDirectory,
            .userDomainMask,
            true
        )
        
        let directoryURL = URL(fileURLWithPath: directoryPaths.first!)
        return directoryURL.appendingPathComponent("ConcurrencyUpload")
    }
    
    /// 데이터 요청 객체 생성 (로거 레벨에 따라 데이터를 표시하기 위해 업로더에 위치시킴)
    /// - Parameter fileInfo: 데이터 요청에 필요한 파일 정보
    /// - Returns: 데이터 요청 객체
    private func request(
        fileInfo: any Uploadable,
        boundary: String
    ) async throws -> URLRequest {
        do {
            var request = URLRequest(
                url: try fileInfo.url,
                cachePolicy: fileInfo.cachePolicy,
                timeoutInterval: fileInfo.timeoutInterval
            )
            request.allHTTPHeaderFields = fileInfo.header(with: boundary)
            request.httpMethod = fileInfo.httpMethod.rawValue
            return request
        } catch {
            throw UploadError.invalidURL(error)
        }
    }
    
    /// 다음 업로드할 파일이 있으면 업로드 진행
    /// - Parameter uploadInfo: 업로드할 파일 정보를 특정하고 싶은 경우 설정
    private func runNextIfNeeded(_ uploadInfo: UploadInfo? = nil) {
        let activeTaskCount = uploadInfos?.activeTaskCount ?? 0
        guard activeTaskCount < maxActiveTask,
              let uploadInfo = (uploadInfo ?? uploadInfos?.first { $0.isSuspended })
        else { return }
        
        if let index = uploadInfos?.index(fileInfo: uploadInfo.fileInfo) {
            uploadInfos?[index].continuation?.yield(
                .start(index: index, uploadInfo: uploadInfo)
            )
        }
        
        resume(task: uploadInfo.task)
    }
    
    /// 업로드 폴더가 필요한 경우 생성
    /// - Parameter willReset: 업로드 폴더 초기화 필요 (true 시 삭제 후 재생성)
    private func createUploadFolderIfNeeded(_ willReset: Bool) throws {
        if willReset {
            try deleteUploadFolderIfNeeded()
        }
        
        let uploadFolderURL = uploadFolderURL.path
        guard FileManager.default.fileExists(atPath: uploadFolderURL) == false
        else { return }
    
        try FileManager.default.createDirectory(
            atPath: uploadFolderURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    /// 업로드 폴더 삭제가 필요한 경우 삭제
    private func deleteUploadFolderIfNeeded() throws {
        guard FileManager.default.fileExists(atPath: uploadFolderURL.path)
        else { return }

        try FileManager.default.removeItem(atPath: uploadFolderURL.path)
    }
    
    /// 파일 업로드 이벤트 흐름 (이벤트 추적 시작)
    /// - Parameter uploadInfo: 업로드 정보
    /// - Returns: 단일 업로드 이벤트 흐름
    private func upload(
        _ uploadInfo: UploadInfo
    ) async throws -> AsyncThrowingStream<UploadEvent, Error> {
        let index = uploadInfos!.index(fileInfo: uploadInfo.fileInfo)!
        
        return AsyncThrowingStream<UploadEvent, Error> { continuation in
            uploadInfos![index].continuation = continuation
            
            Task {
                let boundary = uploadInfo.id.uuidString
                let fileURL = try await dataFileURLToUpload(uploadInfo)
                let uploadTask = try await session.uploadTask(
                    with: request(fileInfo: uploadInfo.fileInfo, boundary: boundary),
                    fromFile: fileURL
                )
                
                uploadInfos![index].fileURL = fileURL
                uploadInfos![index].task = uploadTask
                
                try checkLimitedFileSize(uploadInfos![index])
                runNextIfNeeded(uploadInfos![index])
            }
        }
    }
    
    /// 업로드를 위한 data 가 저장된 파일 경로
    ///
    /// 업로드를 위한 정보를 file 데이터로 저장하여 file 경로 반환
    /// - Parameter uploadInfo: 업로드할 정보
    /// - Returns: 업로드할 파일 경로
    private func dataFileURLToUpload(
        _ uploadInfo: UploadInfo
    ) async throws -> URL {
        let uuid = uploadInfo.id.uuidString
        let dataFileURL = uploadFolderURL.appendingPathComponent(uuid)
        
        FileManager.default.createFile(atPath: dataFileURL.path, contents: nil)
        let file = FileHandle(forWritingAtPath: dataFileURL.path)!
        
        do {
            let bodyObject = try bodyObject(
                with: uuid,
                fileURLs: try await fileURLsToUpload(uploadInfo),
                name: uploadInfo.fileInfo.content.name,
                parameters: uploadInfo.fileInfo.bodyParams
            )
            file.write(try bodyObject.data)
            file.closeFile()
            
            return dataFileURL
        } catch {
            throw UploadError.invalidFileURL(error)
        }
    }
    
    /// 업로드 body 객체 (업로드용 파일에 작성될 데이터)
    /// - Parameters:
    ///   - boundary: 업로드 컨텐츠 구분값
    ///   - fileURL: 업로드 파일 경로
    ///   - name: 업로드시 form-data key
    ///   - parameters: body 영역에 포함될 파라미터
    /// - Returns: 업로드 body 객체
    private func bodyObject(
        with boundary: String,
        fileURLs: [URL],
        name: String,
        parameters: [String: String]?
    ) throws -> UploadBodyObject {
        return UploadBodyObject(
            boundary: boundary,
            fileURLs: fileURLs,
            name: name,
            parameters: parameters
        )
    }
    
    /// 업로드할 파일 경로 (리사이징이 필요한 경우 변환됨)
    /// - Parameter uploadInfo: 업로드할 정보
    /// - Returns: 업로드할 파일 경로
    private func fileURLsToUpload(
        _ uploadInfo: UploadInfo
    ) async throws -> [URL] {
        switch uploadInfo.fileInfo.content {
        case let .data(data, _, fileName, _):
            let fileURL = uploadFolderURL.appendingPathComponent(fileName)
            try data.write(to: fileURL)
            return [fileURL]
        case let .file(url, _):
            return [url]
        case let .files(urls, _):
            return urls
        }
    }
    
    /// 업로드할 파일 사이즈 체크 (제한된 용량을 초과했는지 여부)
    /// - Parameter uploadInfo: 업로드할 파일 정보
    private func checkLimitedFileSize(_ uploadInfo: UploadInfo) throws {
        let data = try Data(contentsOf: uploadInfo.fileURL!)
        if data.count > Int(uploadInfo.fileInfo.maxBytes) {
            throw UploadError.overLimitedFileSize
        }
    }
    
    /// task에 해당되는 업로드 시작
    /// - Parameter task: 업로드를 재시작할 Task
    private func resume(task: URLSessionTask?) {
        guard let uploadTask = task else { return }
        uploadTask.resume()
    }
    
    /// 업로드 완료 (성공)
    /// - Parameter task: 업로드 완료된 Task
    private func didFinishUploading(withTask task: URLSessionTask) {
        guard let index = uploadInfos?.index(withTask: task) else { return }
        let totalIndex = uploadInfos?.count ?? 0
        let currentIndex = uploadInfos?.filter { $0.isCompleted }.count ?? 0
        let receivedData = uploadInfos?[index].receivedData ?? Data()
        
        uploadInfos?[index].continuation?.yield(
            .completed(data: receivedData, uploadInfo: uploadInfos![index])
        )
        uploadInfos?[index].continuation?.finish()
        
        runNextIfNeeded()
        
        let isAllCompleted = currentIndex == totalIndex
        if isAllCompleted {
            continuation?.yield(.allCompleted(uploadInfos!))
            continuation?.finish()
            continuation = nil
            uploadInfos = nil
        }
    }
    
    /// 업로드 오류 발생
    /// - Parameters:
    ///   - task: 업로드 중 오류가 발생된 Task
    ///   - error: 업로드 오류
    private func didFinishUploading(withTask task: URLSessionTask, error: Error) {
        if let index = uploadInfos?.index(withTask: task) {
            uploadInfos?[index].error = error
            uploadInfos?[index].continuation?.finish(throwing: error)
        }
        continuation?.finish(throwing: error)
    }
}

// MARK: - URLSessionTaskDelegate
extension Uploader: URLSessionTaskDelegate {
    public nonisolated
    func urlSession(
        _ session: URLSession,
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
    
    public nonisolated
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        Task {
            await urlSession(
                session,
                task: task,
                didSendBodyData: bytesSent,
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend
            )
        }
    }
    
    /// 업로드 중 오류 발생을 추적하기 위한 비동기식 함수 (동일 함수명의 동기함수에서 호출됨)
    /// - Parameters:
    ///   - task: 업로드 Task
    ///   - error: 업로드 중 발생된 에러
    private func urlSession(
        _: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) async {
        if let error = error {
            didFinishUploading(withTask: task, error: error)
        } else {
            if task.response?.isOK ?? false { // 업로드 완료
                didFinishUploading(withTask: task)
            } else { // 서버 오류 발생
                let statusCode = task.response?.httpStatusCode ?? 0
                didFinishUploading(
                    withTask: task,
                    error: UploadError.serverError(statusCode)
                )
            }
        }
    }
    
    /// 업로드 진행률을 추적 (동일 함수명의 비동기 함수)
    /// - Parameters:
    ///   - session: 업로드 중인 세션
    ///   - task: 업로드 중인 Task
    ///   - bytesSent: 전송중인 데이터 양
    ///   - totalBytesSent: 총 전송된 데이터 양
    ///   - totalBytesExpectedToSend: 예상되는 총 업로드 데이터 양
    private func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) async {
        let index = uploadInfos?.index(withTask: task) ?? 0
        let beforeBytes = uploadInfos?[index].currentBytes ?? 0
        let currentBytes = Double(totalBytesSent)
        let totalBytes = Double(totalBytesExpectedToSend)
        
        let beforeProgress = floor(beforeBytes * 100 / totalBytes)
        let currentProgress = floor(currentBytes * 100 / totalBytes)
        let canUpdateProgress = abs(currentProgress - beforeProgress) >= progressInterval
        
        guard canUpdateProgress else { return }
        
        uploadInfos?[index].currentBytes = currentBytes
        uploadInfos?[index].totalBytes = totalBytes
        
        uploadInfos?[index].continuation?.yield(
            .update(
                currentBytes: currentBytes,
                totalBytes: totalBytes
            )
        )
    }
}
 
// MARK: - URLSessionDataDelegate
extension Uploader: URLSessionDataDelegate {
    public nonisolated
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        Task {
            await urlSession(
                session,
                dataTask: dataTask,
                didReceive: data)
        }
    }
    
    public nonisolated
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        Task {
            await urlSession(
                session,
                dataTask: dataTask
            )
        }
        completionHandler(.allow)
    }
    
    /// 응답객체 수신
    /// - Parameters:
    ///   - session: 업로드 중인 세션
    ///   - dataTask: 업로드 중인 Task
    ///   - data: 업로드 중 추가 수신된 데이터
    private func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) async {
        guard let index = uploadInfos?.index(withTask: dataTask) else { return }
        if uploadInfos?[index].receivedData == nil {
            uploadInfos?[index].receivedData = .init()
        }
        uploadInfos?[index].receivedData?.append(data)
    }
    
    /// 응답객체 수신 시작
    /// - Parameters:
    ///   - session: 업로드 중인 세션
    ///   - dataTask: 업로드 중인 Task
    private func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask
    ) async {
        guard let index = uploadInfos?.index(withTask: dataTask) else { return }
        uploadInfos?[index].receivedData = .init()
    }
}

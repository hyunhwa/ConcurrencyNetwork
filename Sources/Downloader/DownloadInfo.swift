//
//  DownloadInfo.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/28.
//

import Foundation

/// 다운로드 상태 정보 객체 (다운로드 요청 시 파일 정보 포함)
public struct DownloadInfo: Equatable {
    /// 다운로드 받을 파일 정보
    public internal(set) var fileInfo: any Downloadable
    /// 현재 다운로드 완료된 데이터 양
    public var currentBytes: Double = 0
    /// 총 예상 다운로드 데이터 양
    public var totalBytes: Double = 0
    /// 다운로드 중 발생된 에러
    public var error: Error?
    /// 다운로드 중 여부
    public var isDownloading: Bool {
        downloadTask?.state == .running
    }
    /// 다운로드 완료 여부
    public var isCompleted: Bool {
        downloadTask?.state == .completed
    }
    /// 다운로드 정지 여부
    public var isSuspended: Bool {
        downloadTask?.state == .suspended
    }
    /// 다운로드 재시작 데이터 (다운로드 중지 시 발생됨)
    /// - 재가동을 위한 데이터로 다운로드 완료된 데이터가 아님 주의!!
    public internal(set) var resumeData: Data?
    /// 다운로드 Task
    var downloadTask: URLSessionDownloadTask?
    /// 단일 다운로드 이벤트 흐름
    var continuation: AsyncThrowingStream<DownloadEvent, Error>.Continuation?
    
    public static func == (lhs: DownloadInfo, rhs: DownloadInfo) -> Bool {
        (try? lhs.fileInfo.sourceURL) == (try? rhs.fileInfo.sourceURL)
        && lhs.fileInfo.cachePolicy == rhs.fileInfo.cachePolicy
        && lhs.fileInfo.headers == rhs.fileInfo.headers
        && lhs.fileInfo.destinationURL == rhs.fileInfo.destinationURL
        && lhs.fileInfo.timeoutInterval == rhs.fileInfo.timeoutInterval
        && lhs.currentBytes == rhs.currentBytes
        && lhs.totalBytes == rhs.totalBytes
        && lhs.resumeData == rhs.resumeData
    }
}

extension Array where Element == DownloadInfo {
    /// 활성화된 테스트 수 (다운로드 중인 파일 갯수)
    var activeTaskCount: Int {
        filter { $0.isDownloading }.count
    }
    
    /// 다운로드 받을 파일의 URL 정보가 일치하는 아이템의 순번
    /// - Parameter fileInfo: 일치여부를 확인하고자 하는 파일 정보
    /// - Returns: 파일정보가 일치하는 아이템의 순번
    func index(withURL url: URL) -> Int? {
        firstIndex(
            where: { (try? $0.fileInfo.sourceURL) == url }
        )
    }
    
    /// 다운로드 리스트 내 다운로드 정보 순번
    /// - Parameter downloadInfo: 검색할 다운로드 정보
    /// - Returns: 다운로드 리스트 내 다운로드 정보 순번
    func index(of downloadInfo: DownloadInfo) -> Int? {
        firstIndex(
            where: {
                (try? $0.fileInfo.sourceURL)
                == (try? downloadInfo.fileInfo.sourceURL)
            }
        )
    }
    
    /// 다운로드 Task 가 일치하는 아이템의 순번
    /// - Parameter task: 일치여부를 하고자하는 다운로드 Task
    /// - Returns: 다운로드 Task 가 일치하는 아이템의 순번
    func index(withTask task: URLSessionTask) -> Int? {
        firstIndex(
            where: { $0.downloadTask?.taskIdentifier == task.taskIdentifier }
        )
    }
    
    /// 댜운로드 Task url 문자열
    ///
    /// 다운로드가 중지된 이후에는 Task originalRequest 에 url 정보가 담겨있지 않으므로 fileInfo 에서 확인
    /// - Parameter task: URL 확인이 필요한 다운로드 task
    /// - Returns: 다운로드 중인 URL 문자열
    func urlString(withTask task: URLSessionTask) -> String {
        guard let index = index(withTask: task) else { return "" }
        return (try? self[index].fileInfo.sourceURL.absoluteString) ?? ""
    }
}

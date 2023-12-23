//
//  UploadInfo.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/04.
//

import Foundation

/// 업로드 상태 정보 객체 (업로드 요청 시 파일 정보 포함)
public struct UploadInfo: Identifiable, Equatable {
    /// 객체 식별자
    public internal(set) var id: UUID = UUID()
    /// 업로드할 파일 정보
    public internal(set) var fileInfo: any Uploadable
    /// 업로드할 파일 데이터 URL (업로드를 위한 data를 포함)
    public internal(set) var fileURL: URL?
    /// 응답받은 데이터
    public internal(set) var receivedData: Data?
    /// 업로드 중 발생된 에러
    public var error: Error?
    /// 업로드 중 여부
    public var isUploading: Bool {
        task?.state == .running
    }
    /// 업로드 완료 여부
    public var isCompleted: Bool {
        task?.state == .completed
    }
    /// 업로드 정지 여부
    public var isSuspended: Bool {
        task?.state == .suspended
    }
    /// 현재 업로드 완료된 데이터 양
    public var currentBytes: Double = 0
    /// 총 예상 업로드 데이터 양
    public var totalBytes: Double = 0
    /// 업로드 task (datatask delegate 메소드에서 함께 사용되므로 URLSessionTask 로 정의)
    var task: URLSessionTask?
    /// 단일 업로드 이벤트 흐름
    var continuation: AsyncThrowingStream<UploadEvent, Error>.Continuation?
    
    public static func == (lhs: UploadInfo, rhs: UploadInfo) -> Bool {
        lhs.id == rhs.id
    }
}

extension Array where Element == UploadInfo {
    /// 활성화된 테스크 여부
    var hasActiveTask: Bool {
        filter { $0.isUploading }.isEmpty == false
    }
    
    /// 업로드 받을 파일의 URL 정보가 일치하는 아이템의 순번
    /// - Parameter fileInfo: 일치여부를 확인하고자 하는 파일 정보
    /// - Returns: 파일정보가 일치하는 아이템의 순번
    func index(fileInfo: any Uploadable) -> Int? {
        firstIndex(
            where: { $0.fileInfo.content == fileInfo.content }
        )
    }
    
    /// 업로드 Task 가 일치하는 아이템의 순번
    /// - Parameter task: 일치여부를 하고자하는 업로드 Task
    /// - Returns: 업로드 Task 가 일치하는 아이템의 순번
    func index(withTask task: URLSessionTask) -> Int? {
        firstIndex(
            where: { $0.task?.taskIdentifier == task.taskIdentifier }
        )
    }
}

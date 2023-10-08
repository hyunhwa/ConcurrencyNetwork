//
//  UploadEvent.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/04.
//

import Foundation

/// 단일 업로드 이벤트
public enum UploadEvent: Equatable {
    /// 프로그레스 업데이트 시
    /// - currentBytes: 업로드 완료된 데이터 양
    /// - totalBytes: 업로드 예상되는 총 데이터 양
    case update(currentBytes: Double, totalBytes: Double)
    /// 업로드 완료
    /// - data: 업로드 완료 후 응답 데이터
    /// - uploadInfo: 업로드 정보(+파일정보)
    case completed(data: Data, uploadInfo: UploadInfo)
    /// 업로드 전 업로드 정보를 반환
    /// - index: 업로드 순번
    /// - uploadInfo: 업로드 정보(+파일정보)
    case start(index: Int, uploadInfo: UploadInfo)
}

/// 다건 업로드 이벤트
public enum MultiUploadEvent: Equatable {
    /// 모든 업로드 완료 이벤트 (업로드 완료 후 업로드정보(+파일정보) 반환)
    case allCompleted([UploadInfo])
    /// 업로드 시작 전 전체 업로드 갯수 반환
    /// - uploadInfos : 업로드 정보
    case start(uploadInfos: [UploadInfo])
    /// 단일 업로드 이벤트
    case unit(AsyncThrowingStream<UploadEvent, Error>)
    
    public static func == (lhs: MultiUploadEvent, rhs: MultiUploadEvent) -> Bool {
        switch (lhs, rhs) {
        case (.allCompleted, .allCompleted),
            (.start, .start),
            (.unit, .unit):
            return true
        default:
            return false
        }
    }
}

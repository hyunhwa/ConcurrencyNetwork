//
//  DownloadEvent.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/28.
//

import Foundation

/// 단일 다운로드 이벤트
public enum DownloadEvent: Equatable {
    /// 프로그레스 업데이트 시
    /// - currentBytes: 다운로드 완료된 데이터 양
    /// - totalBytes: 다운로드 예상되는 총 데이터 양
    case update(currentBytes: Double, totalBytes: Double)
    /// 다운로드 완료
    /// - data: 다운로드 완료된 파일 데이터 (임시저장파일에서 추출된 데이터)
    /// - downloadInfo: 다운로드 정보(+파일정보) 반환)
    case completed(data: Data, downloadInfo: DownloadInfo)
    /// 다운로드 전 다운로드 정보를 반환
    /// - index: 다운로드 순번
    /// - downloadInfo: 다운로드 정보
    case start(index: Int, downloadInfo: DownloadInfo)
}

/// 다건 다운로드 이벤트
public enum MultiDownloadEvent: Equatable {
    /// 모든 다운로드 완료 이벤트 (다운로드 완료 후 다운로드정보(+파일정보) 반환)
    case allCompleted([DownloadInfo])
    /// 다운로드 시작 전 다운로드 정보 리스트 반환
    /// - downloadInfos : 다운로드 정보
    case start(downloadInfos: [DownloadInfo])
    /// 단일 다운로드 이벤트
    case unit(AsyncThrowingStream<DownloadEvent, Error>)
    
    public static func == (lhs: MultiDownloadEvent, rhs: MultiDownloadEvent) -> Bool {
        switch (lhs, rhs) {
        case (.allCompleted, .allCompleted),
            (.unit, .unit):
            return true
        default:
            return false
        }
    }
}

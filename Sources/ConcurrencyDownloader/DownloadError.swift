//
//  DownloadError.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/22.
//

import Foundation

/// 다운로드 중 발생된 에러
public enum DownloadError: Error, Equatable {
    /// 사용자에 의해 디운로드 취소됨
    case canceledByUser
    /// sourceURL 이 유효하지 않음
    case invalideURL(Error)
    /// destinationURL 이 유효하지 않음 (file URL 이 아님)
    case invalideFileURL
    /// 로컬 파일에 저장된 데이터가 없음
    case noDataInLocal
    /// 서버에서 오류가 발생됨
    case serverError

    public static func == (lhs: DownloadError, rhs: DownloadError) -> Bool {
        switch (lhs, rhs) {
        case (.canceledByUser, .canceledByUser),
            (.invalideURL, .invalideURL),
            (.invalideFileURL, .invalideFileURL),
            (.noDataInLocal, .noDataInLocal),
            (.serverError, .serverError):
            return true
        default:
            return false
        }
    }
}

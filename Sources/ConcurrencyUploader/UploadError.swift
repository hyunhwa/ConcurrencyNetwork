//
//  UploadError.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/04.
//

import Foundation

/// 업로드 중 발생된 에러
public enum UploadError: Error, Equatable {
    /// 사용자에 의해 업로드 취소됨
    case canceledByUser
    /// 서버 오류 발생 (실패 응답 객체)
    case failureObject(Codable)
    /// URL이 유효하지 않음
    case invalidURL
    /// FileURL이 유효하지 않음 (file URL이 아님)
    case invalidFileURL
    /// 업로드 가능한 파일 용량을 초과함
    case overLimitedFileSize
    /// 서버 오류 발생 (상태코드 포함)
    case serverError(Int)
    
    public static func == (lhs: UploadError, rhs: UploadError) -> Bool {
        switch (lhs, rhs) {
        case (.canceledByUser, .canceledByUser),
            (.failureObject, .failureObject),
            (.invalidURL, .invalidURL),
            (.invalidFileURL, .invalidFileURL),
            (.overLimitedFileSize, .overLimitedFileSize),
            (.serverError, .serverError):
            return true
        default:
            return false
        }
    }
}

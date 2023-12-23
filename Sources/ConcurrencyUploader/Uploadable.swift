//
//  Uploadable.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/04.
//

import ConcurrencyAPI
import Foundation

/// 업로드할 파일의 최소한 구성되어야할 정보
public protocol Uploadable {
    /// 업로드 요청 API URL
    var url: URL { get }
    /// 요청 객체에 포함될 Post Body 파라미터 (기본 : nil)
    var bodyParams: [String: String]? { get }
    /// 캐시 정책
    var cachePolicy: URLRequest.CachePolicy { get }
    /// 데이터 요청 헤더 (Content-Type 은 업로더 내부에서 설정)
    var headers: [String: String]? { get }
    /// 세션 타임 아웃 (기본 60초)
    var timeoutInterval: TimeInterval { get }
    /// 업로드할 컨텐츠
    var content: UploadContent { get }
    /// 최대 업로드 가능한 Bytes
    var maxBytes: CGFloat { get }
}

public extension Uploadable {
    var bodyParams: [String: String]? {
        nil
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        .reloadIgnoringCacheData
    }
    
    /// 업로드용 헤더 객체
    /// - Parameters:
    ///   - boundary: 업로드 요청 아이템별 구분자
    ///   - authorization: 트랜스코딩 업로드 시 인증키
    /// - Returns: 업로드용 헤더 객체
    func header(
        with boundary: String
    ) -> [String: String] {
        let defaultHeaders = [ // 기본 멀티파트폼 객체
            "Content-Type" : "multipart/form-data; boundary=\(boundary)",
        ]
        
        if let headers = headers {
            return defaultHeaders.merging(headers) { current, _ in current }
        } else {
            return defaultHeaders
        }
    }
    
    /// 업로드 시 POST 방식 고정
    var httpMethod: HttpMethod {
        .post
    }
    
    var timeoutInterval: TimeInterval {
        60
    }
}

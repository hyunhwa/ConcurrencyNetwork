//
//  Downloadable.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/22.
//

import ConcurrencyAPI
import Foundation

/// 다운로드 가능한 파일의 최소한으로 구성되어야할 정보
public protocol Downloadable {
    /// 캐시 정책 (기본 .reloadIgnoringCacheData)
    var cachePolicy: URLRequest.CachePolicy { get }
    /// 다운로드 완료 시 저장될 폴더 URL (기본 그외 도큐먼트' > Downloads)
    var directoryURL: URL { get }
    /// 확장자를 포함한 파일명 (기본 sourceURL.lastPathComponent)
    var fileName: String { get }
    /// 데이터 요청 헤더 (기본 nil)
    var headers: [String: String]? { get }
    /// 서버에 등록된 파일 URL 문자열 (유효하지 않은 URL 인 경우 오류 발생)
    var sourceURL: URL { get throws }
    /// 세션 타임 아웃 (기본 10초)
    var timeoutInterval: TimeInterval { get }
}

public extension Downloadable {
    var cachePolicy: URLRequest.CachePolicy {
        .reloadIgnoringCacheData
    }
    
    var destinationURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }
    
    var fileName: String {
        (try? sourceURL.lastPathComponent) ?? "Empty"
    }
    
    var headers: [String: String]? {
        nil
    }
    
    var timeoutInterval: TimeInterval {
        60
    }
    
    /// 다운로드 이어받기 지원을 위해 GET 방식으로 고정
    var httpMethod: HttpMethod {
        .get
    }
    
    func isEqual(url: URL?) -> Bool {
        (try? sourceURL) == url
    }
}

extension Array where Element == Downloadable {
    /// 다운로드 받을 파일의 URL 정보가 일치하는 아이템의 순번
    /// - Parameter fileInfo: 일치여부를 확인하고자 하는 파일 정보
    /// - Returns: 파일정보가 일치하는 아이템의 순번
    func index(of fileInfo: any Downloadable) -> Int? {
        firstIndex(
            where: { $0.isEqual(url: try? fileInfo.sourceURL) }
        )
    }
}

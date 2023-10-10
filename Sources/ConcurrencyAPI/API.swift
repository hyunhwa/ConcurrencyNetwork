//
//  API.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/01.
//

import Foundation

/// 데이터 통신 방식
/// String 타입으로 case 와 동일한 rawValue 반환
public enum HttpMethod: String, Equatable {
    case get
    case post
    case put
    case delete
}

/// API 요청 시 포함될 기본 헤더
///
/// - 기본 요청타입 application/x-www-form-urlencoded
/// - 기본 응답타입 application/json
let defaultHeaders = [
    "Content-Type": "application/x-www-form-urlencoded", // 기본 request 타입
    "Accept": "application/json" // 기본 response 타입
]

/// API 통신을 위해 구현해야할 프로토콜
///
/// 기능별로 여러 케이스를 구현하는 것이 일반적이므로 enum으로 구현하시는 편을 추천드립니다.
///
/// ```swift
/// enum SampleAPI {
///     case getSampleData
///     case saveSampleData
/// }
///
/// extension SampleAPI: API {
///     var baseUrlString: String {
///         "https://your-api-endpoint.com"
///     }
///
///     var path: String {
///         switch self {
///         case .getSampleData,
///             .saveSampleData:
///             return "/SampleData"
///         }
///     }
///     ...
/// }
/// ```
///
/// Async 방식으로 응답 데이터(Codable)를 가져옵니다.
/// ```swift
/// struct SampleResponse: Codable, Equatable {
///     ...
/// }
///
/// let response = try await SampleAPI
///    .getSampleData
///    .request()
///    .response(SampleResponse.self)
/// ```
public protocol API {
    /// https 프로토콜을 포함한 기본 도메인 주소
    var baseUrlString: String { get }
    /// 요청 데이터 객체로 Codable 객체
    var body: Codable? { get }
    /// 데이터 요청 헤더 (기본 요청 urlEncoded, 기본 응답 json)
    var headers: [String: String]? { get }
    /// GET or POST 와 같이 통신 방식 설정
    var httpMethod: HttpMethod { get }
    /// 쿼리 파라미터
    var params: [String: String]? { get }
    /// 파라미터를 제외한 '/' 이하 주소
    var path: String { get }
    /// 세션 타임 아웃 (기본 60초)
    var timeoutInterval: TimeInterval { get }
}

public extension API {
    var timeoutInterval: TimeInterval {
        60
    }
    
    var endpointURL: URL {
        get throws {
            let urlString = baseUrlString + path
            
            guard let params
            else { return URL(string: urlString)! }
            
            let queryItems = params.map { key, value in
                return URLQueryItem(name: key, value: value)
            }
            
            var urlComponents = URLComponents(string: urlString)!
            urlComponents.queryItems = queryItems
            return urlComponents.url!
        }
    }
    
    func request() async throws -> URLRequest {
        var url: URL
        do {
            url = try endpointURL
        } catch {
            throw APIError.invalideURL(error)
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = mergingHeaders
        
        guard httpMethod != .get else { return urlRequest }
        
        do {
            urlRequest.httpBody = try httpBody(url: url)
            return urlRequest
        } catch {
            throw APIError.encodingError(error)
        }
    }
    
    private var mergingHeaders: [String: String] {
        if let headers {
            return defaultHeaders.merging(headers) { _, new in new }
        } else {
            return defaultHeaders
        }
    }
    
    private func httpBody(url: URL) throws -> Data? {
        guard let bodyObject = body else { return nil }
        return try bodyObject.httpBodyData(url: url)
    }
}

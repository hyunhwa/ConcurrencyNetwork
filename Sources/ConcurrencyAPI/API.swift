//
//  API.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/01.
//

import ConcurrencyNetwork
import Foundation

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
///             return "/RealData"
///         }
///     }
///     ...
/// }
/// ```
///
///
/// 헤더, 쿠키저장소, 세션 타임아웃을 재정의하여 사용 가능합니다.
/// ```swift
/// var cookieStorage: HTTPCookieStorage? {
///     switch self {
///     case .getSampleData:
///         return nil // 쿠키 영향을 받지 않음
///     default:
///         return .shared
/// }
/// ```
///
///
/// async 방식으로 응답 데이터(Codable)를 가져옵니다.
/// ```swift
/// struct SampleResponse: Codable, Equatable {
///     ...
/// }
///
/// let response = try await SampleAPI.getSampleData.request(responseAs: SampleResponse.self)
/// ```
public protocol API {
    /// https 프로토콜을 포함한 기본 도메인 주소
    var baseUrlString: String { get }
    /// 요청 데이터 객체로 Codable 객체
    var body: Codable? { get }
    /// 쿠키저장소 (기본 .shared)
    var cookieStorage: HTTPCookieStorage? { get }
    /// 데이터 요청 헤더 (기본 요청 urlEncoded, 기본 응답 json)
    var headers: [String: String]? { get }
    /// GET or POST 와 같이 통신 방식 설정
    var method: HttpMethod { get }
    /// 쿼리 파라미터
    var params: [String: String]? { get }
    /// 파라미터를 제외한 '/' 이하 주소
    var path: String { get }
    /// 세션 타임 아웃 (기본 10초)
    var timeoutInterval: TimeInterval { get }
}

public extension API {
    var cookieStorage: HTTPCookieStorage? {
        .shared
    }
    
    var headers: [String: String]? {
        defaultHeaders
    }
    
    var timeoutInterval: TimeInterval {
        10
    }
    
    /// async 방식으로 서버에 데이터를 요청합니다.
    /// - Parameters:
    ///   - dateFormat: Data 타입 변환에 쓰일 포맷 문자열
    func request(
        dateFormat: String = "yyyy-MM-dd HH:mm:ss"
    ) async throws {
        let request: URLRequest
        do {
            request = try await urlRequest(dateFormat: dateFormat)
        } catch { throw error }
        
        let responseData: Data
        let urlResponse: URLResponse
        do {
            let (data, response) = try await urlSession.data(for: request)
            responseData = data
            urlResponse = response
        } catch { throw error }
        
        guard urlResponse.isOK
        else {
            let statusCode = urlResponse.httpStatusCode
            if let contents = responseData.encodedString,
               contents.isHtmlString
            { throw APIError.serverErrorHtml(contents, statusCode)
            } else { throw APIError.serverError(statusCode) }
        }
    }
    
    /// async 방식으로 서버에 데이터를 요청하여 Codable 객체를 넘겨받습니다.
    ///
    /// - Parameters:
    ///   - codable: 응답받을 Codable 객체 타입
    ///   - dateFormat: Data 타입 변환에 쓰일 포맷 문자열
    /// - Returns: 응답받을 Codable 객체
    func request<T: Codable>(
        responseAs codable: T.Type,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss"
    ) async throws -> T {
        let request: URLRequest
        do { request = try await urlRequest(dateFormat: dateFormat)
        } catch { throw error }
        
        let responseData: Data
        let urlResponse: URLResponse
        do {
            let (data, response) = try await urlSession.data(for: request)
            responseData = data
            urlResponse = response
        } catch { throw error }
        
        guard urlResponse.isOK
        else {
            let statusCode = urlResponse.httpStatusCode
            if let contents = responseData.encodedString,
               contents.isHtmlString
            { throw APIError.serverErrorHtml(contents, statusCode) }
            else { throw APIError.serverError(statusCode) }
        }
        
        do {
            return try responseData.decodedResponse(
                codable,
                dateFormat: dateFormat
            )
        } catch { throw error }
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
    
    private var urlSession: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = cookieStorage
        return URLSession(configuration: configuration)
    }
    
    private func urlRequest(
        dateFormat _: String
    ) async throws -> URLRequest {
        var url: URL
        do {
            url = try endpointURL
        } catch {
            throw APIError.invalideURL
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: timeoutInterval)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = mergingHeaders
        
        guard method != .get else { return urlRequest }
        
        do {
            urlRequest.httpBody = try httpBody(url: url)
            return urlRequest
        } catch {
            throw APIError.encodingError
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

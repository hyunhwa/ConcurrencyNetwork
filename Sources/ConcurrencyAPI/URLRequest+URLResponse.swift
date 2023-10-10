//
//  File.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/10.
//

import Foundation

public extension URLRequest {
    /// async 방식으로 서버에 데이터를 요청합니다.
    /// - Parameters:
    ///   - session: 데이터 요청 세션
    func response(
        session: URLSession = .shared
    ) async throws -> URLResponse {
        let responseData: Data
        let urlResponse: URLResponse
        do {
            let (data, response) = try await session.data(for: self)
            responseData = data
            urlResponse = response
        } catch { throw error }
        
        guard urlResponse.isOK == false
        else { return urlResponse }
        
        let statusCode = urlResponse.httpStatusCode
        if let contents = responseData.encodedString,
           contents.isHtmlString
        { throw APIError.serverErrorHtml(contents, statusCode) }
        else { throw APIError.serverError(statusCode) }
    }
    
    /// async 방식으로 서버에 데이터를 요청하여 Codable 객체를 넘겨받습니다.
    /// - Parameters:
    ///   - codable: 응답받을 Codable 객체 타입
    ///   - session: 데이터 요청 세션
    ///   - dateFormat: Data 타입 변환에 쓰일 포맷 문자열
    /// - Returns: (응답받을 Codable 객체, 응답)
    func response<T: Codable>(
        _ codable: T.Type,
        session: URLSession = .shared,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss"
    ) async throws -> (T, URLResponse) {
        let responseData: Data
        let urlResponse: URLResponse
        do {
            let (data, response) = try await session.data(for: self)
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
            let responseObject = try responseData.decodedResponse(
                codable,
                dateFormat: dateFormat
            )
            return (responseObject, urlResponse)
        } catch { throw error }
    }
}

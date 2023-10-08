//
//  Data+Codable.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/08.
//

import Foundation

extension Data {
    /// 문자열 디코딩
    var decodedString: String {
        String(decoding: self, as: UTF8.self)
    }
    
    var encodedString: String? {
        String(data: self, encoding: .utf8)
    }
    
    /// Codable 객체 디코딩
    /// - Parameters:
    ///   - _: 변환할 디코딩 객체 타입
    ///   - dateFormat: Date 타입 포맷 문자열
    /// - Returns: 디코딩된 객체
    func decodedObject<T: Codable>(
        type _: T.Type,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss"
    ) throws -> T {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale(identifier: "ko")
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try jsonDecoder.decode(T.self, from: self)
    }
    
    /// API 내에서 사용되는 Codable 객체 디코더
    /// - Parameters:
    ///   - _: 디코딩하려는 객체 타입
    ///   - dateFormat: Data 타입 변환에 쓰일 포맷 문자열
    /// - Returns: 디코딩된 Codable 객체
    func decodedResponse<T: Codable>(
        _: T.Type,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss"
    ) throws -> T {
        let responseObject: T
        do {
            responseObject = try self.decodedObject(type: T.self, dateFormat: dateFormat)
            return responseObject
        } catch let APIError.failureObject(failureResponse) {
            throw APIError.failureObject(failureResponse)
        } catch let APIError.failureReason(failureResponse) {
            throw APIError.failureReason(failureResponse)
        } catch {
            throw APIError.decodingError
        }
    }
}

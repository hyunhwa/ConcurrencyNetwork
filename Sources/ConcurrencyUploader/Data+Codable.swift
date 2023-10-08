//
//  File.swift
//  
//
//  Created by Hyun BnS on 2023/10/09.
//

import Foundation

public extension Data {
    /// 업로더에서 사용되는 Codable 객체 디코더
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
        } catch { throw error }
    }
    
    /// Codable 객체 디코딩
    /// - Parameters:
    ///   - _: 변환할 디코딩 객체 타입
    ///   - dateFormat: Date 타입 포맷 문자열
    /// - Returns: 디코딩된 객체
    private func decodedObject<T: Codable>(
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
}

//
//  APIError.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/01.
//

import Foundation

public enum APIError: Error, Equatable {
    case invalidURL(Error)
    case decodingError(Error)
    case encodingError(Error)
    case failureObject(Codable)
    case failureReason(String)
    case serverError(Int)
    case serverErrorHtml(String, Int)
    case unKnown
    
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
            (.decodingError, .decodingError),
            (.encodingError, .encodingError),
            (.failureObject, .failureObject),
            (.failureReason, .failureReason),
            (.serverError, .serverError),
            (.serverErrorHtml, .serverErrorHtml),
            (.unKnown, .unKnown):
            return true
        default:
            return false
        }
    }
}

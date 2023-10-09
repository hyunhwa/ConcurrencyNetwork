//
//  URLResponse+StatusCode.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/10.
//

import Foundation

public extension URLResponse {
    /// 응답 상태 코드 성공 여부
    var isOK: Bool {
        200 ..< 300 ~= httpStatusCode
    }
    
    /// 응답 코드를 확인 후
    var httpStatusCode: Int {
        (self as? HTTPURLResponse)?.statusCode ?? 0
    }
}

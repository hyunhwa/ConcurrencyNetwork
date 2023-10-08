//
//  HttpMethod.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/08.
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

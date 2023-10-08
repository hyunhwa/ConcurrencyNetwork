//
//  DogAPI.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/09.
//

import Foundation
import ConcurrencyNetwork
import ConcurrencyAPI

enum DogAPI {
    case randomImage
}

extension DogAPI: API {
    var baseUrlString: String {
        "https://dog.ceo"
    }
    
    var body: Codable? {
        nil
    }
    
    var method: HttpMethod {
        return .get
    }
    
    var params: [String : String]? {
        nil
    }
    
    var path: String {
        "/api/breeds/image/random"
    }
}

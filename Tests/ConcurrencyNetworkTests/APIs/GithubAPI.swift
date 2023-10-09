//
//  GithubAPI.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/09.
//

import Foundation
import ConcurrencyAPI

enum Sort: String {
    case bestMatch = "best match"
    case stars
    case forks
    case helpWantedIssues = "help-wanted-issues"
    case updated
}

enum Order: String {
    case asc
    case desc
}

enum GithubAPI {
    /// 이모지 검색
    case emojis
    /// 저장소 검색
    case searchRepositories(
        keyword: String,
        sort: Sort = .bestMatch,
        order: Order = .desc
    )
}

extension GithubAPI: API {
    var baseUrlString: String {
        "https://api.github.com"
    }
    
    var body: Codable? {
        nil
    }
    
    var headers: [String : String]? {
        ["Accept" : "application/vnd.github+json"]
    }
    
    var httpMethod: HttpMethod {
        return .get
    }
    
    var params: [String : String]? {
        switch self {
        case .emojis:
            return nil
        case let .searchRepositories(keyword, sort, order):
            return [
                "q" : keyword,
                "sort" : sort.rawValue,
                "order" : order.rawValue
            ]
        }
    }
    
    var path: String {
        switch self {
        case .emojis:
            return "/emojis"
        case .searchRepositories:
            return "/search/repositories"
        }
    }
}

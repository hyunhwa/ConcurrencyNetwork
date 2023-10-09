//
//  APITests.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/06.
//

import XCTest
@testable import ConcurrencyAPI

final class APITests: XCTestCase {
    func testNoRequestParam() async throws {
        let request = try await GithubAPI
            .emojis
            .request()
        dump(request)
        
        let (object, response) = try await request.response([String: String].self)
        dump(response)
        XCTAssertNotNil(object)
    }
    
    func testRequestParam() async throws {
        let response = try await GithubAPI
            .searchRepositories(
                keyword: "Concurrency",
                sort: .bestMatch,
                order: .desc
            )
            .request()
            .response(
                SearchRepositoriesResponse.self,
                dateFormat: "yyyy-MM-dd'T'HH:mm:ss'Z'"
            )
        dump(response)
    }
}

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
        let response = try await GithubAPI
            .emojis
            .request(
                responseAs: [String: String].self
            )
        dump(response)
        XCTAssertNotNil(response)
    }
    
    func testRequestParam() async throws {
        let response = try await GithubAPI
            .searchRepositories(
                keyword: "Concurrency",
                sort: .bestMatch,
                order: .desc
            )
            .request(
                responseAs: SearchRepositoriesResponse.self,
                dateFormat: "yyyy-MM-dd'T'HH:mm:ss'Z'"
            )
        dump(response)
    }
}

//
//  APITests.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/06.
//

import XCTest
@testable import ConcurrencyAPI

final class APITests: XCTestCase {
    func testExample() async throws {
        let response = try await DogAPI.randomImage.request(
            responseAs: RandomImageResponse.self
        )
        dump(response)
        XCTAssertTrue(response.status == "success")
    }
}

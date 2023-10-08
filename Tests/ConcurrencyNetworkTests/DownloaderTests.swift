//
//  DownloaderTests.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/06.
//

import XCTest
@testable import ConcurrencyDownloader

final class DownloaderTests: XCTestCase {
    var downloadImageInfo: DownloadableDogImageInfo?
    
    private enum DownloadTestError: Error {
        case noImageURL
        case noDownloadInfo
    }
    
    override func setUp() async throws {
        let response = try await DogAPI.randomImage.request(
            responseAs: RandomImageResponse.self
        )
        dump(response)
        XCTAssertTrue(response.status == "success")
        if let imageURL = URL(string: response.message) {
            self.downloadImageInfo = DownloadableDogImageInfo(fileURL: imageURL)
        } else {
            XCTAssertThrowsError(DownloadTestError.noImageURL)
        }
    }

    func testExample() async throws {
        guard let downloadImageInfo = downloadImageInfo else {
            XCTAssertThrowsError(DownloadTestError.noDownloadInfo)
            return
        }
        
        let downloader = Downloader(
            progressInterval: 1,
            maxActiveTask: 1
        )
        
        for try await event in try await downloader.events(
            fileInfo: downloadImageInfo
        ) {
            switch event {
            case let .update(currentBytes, totalBytes):
                if currentBytes > totalBytes {
                    XCTAssertTrue(
                        currentBytes <= totalBytes,
                        "다운로드된 데이터가 예상 다운로드 데이터보다 큼"
                    )
                }
            case let .completed(data, downloadInfo):
                XCTAssertTrue(
                    data.count > 0,
                    "다운로드된 임시 로컬파일의 데이터가 없음"
                )
                XCTAssertTrue(downloadInfo.isCompleted, "다운로드 완료 상태")
            case let .start(index, _):
                print("index : \(index)")
            }
        }
    }
}

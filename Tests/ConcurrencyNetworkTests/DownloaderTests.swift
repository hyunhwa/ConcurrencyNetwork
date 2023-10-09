//
//  DownloaderTests.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/06.
//

import XCTest
@testable import ConcurrencyDownloader

final class DownloaderTests: XCTestCase {
    var downloadEmojiInfos: [DownloadableEmojiInfo]?
    let downloader = Downloader(
        progressInterval: 1,
        maxActiveTask: 1
    )
    
    private enum DownloadTestError: Error {
        case noDownloadInfo
        case notEnoughEmojis
    }
    
    override func setUp() async throws {
        let (object, _) = try await GithubAPI
            .emojis
            .request()
            .response([String: String].self)
        XCTAssertNotNil(object)
        
        let emojiInfos: [DownloadableEmojiInfo] = object.compactMap { (key, value) in
            guard let imageURL = URL(string: value)
            else { return nil }
            return DownloadableEmojiInfo(fileURL: imageURL)
        }
        
        downloadEmojiInfos = emojiInfos
    }

    func testUnitDownload() async throws {
        guard let downloadEmojiInfo = downloadEmojiInfos?.first else {
            XCTAssertThrowsError(DownloadTestError.noDownloadInfo)
            return
        }
        
        for try await event in try await downloader.events(
            fileInfo: downloadEmojiInfo
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
                print("Local FileURL: \(downloadInfo.fileInfo.destinationURL)")
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
    
    func testMultiDownload() async throws {
        guard let lastEmojiSlice = downloadEmojiInfos?.suffix(5)
        else {
            XCTAssertThrowsError(DownloadTestError.notEnoughEmojis)
            return
        }
        let fileInfos: [DownloadableEmojiInfo] = Array(lastEmojiSlice)
        
        for try await event in try await downloader.events(
            fileInfos: fileInfos
        ) {
            switch event {
            case let .allCompleted(downloadInfos):
                let downloadedFileInfos = downloadInfos.filter { $0.isCompleted }
                XCTAssertTrue(
                    downloadedFileInfos.count == fileInfos.count,
                    "다운로드 완료 후 파일 갯수가 요청된 파일 갯수와 다름"
                )
                return
                
            case let .unit(unitEvents):
                for try await unitEvent in unitEvents {
                    switch unitEvent {
                    case let .completed(data, downloadInfo):
                        print("Local FileURL: \(downloadInfo.fileInfo.destinationURL)")
                        XCTAssertTrue(
                            data.count > 0,
                            "다운로드된 임시 로컬파일의 데이터가 없음"
                        )
                        XCTAssertTrue(downloadInfo.isCompleted, "다운로드 완료 상태")
                    case let .update(currentBytes, totalBytes):
                        if currentBytes > totalBytes {
                            XCTAssertTrue(
                                currentBytes <= totalBytes,
                                "다운로드된 데이터가 예상 다운로드 데이터보다 큼"
                            )
                        }
                    case let .start(index, _):
                        print("index : \(index)")
                    }
                }
            case let .start(downloadInfos: downloadInfos):
                print("downloadInfos.count : \(downloadInfos.count)")
            }
        }
    }
}

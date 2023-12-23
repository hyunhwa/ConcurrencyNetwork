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
    let downloader = Downloader()
    
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

    /// 단일 다운로드 테스트
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
                log("🆙 \(currentBytes)/\(totalBytes)")
                if currentBytes > totalBytes {
                    XCTAssertTrue(
                        currentBytes <= totalBytes,
                        "다운로드된 데이터가 예상 다운로드 데이터보다 큼"
                    )
                }
                
            case let .completed(data, downloadInfo):
                let destinationURL = downloadInfo.fileInfo.destinationURL
                log("⏹️ \(destinationURL)")
                XCTAssertTrue(
                    data.count > 0,
                    "다운로드된 임시 로컬파일의 데이터가 없음"
                )
                XCTAssertTrue(downloadInfo.isCompleted, "다운로드 완료 상태")
                
            case let .start(index, downloadInfo):
                let sourceURL = downloadInfo.fileInfo.sourceURL
                log("▶️ [\(index)] \(String(describing: sourceURL))")
            }
        }
    }
    
    func testMultiDownload() async throws {
        let lastEmojiInfos = try lastEmojiInfos(maxLength: 3)
        
        for try await event in await downloader.events(
            fileInfos: lastEmojiInfos
        ) {
            switch event {
            case let .allCompleted(downloadInfos):
                log("⏬⏹️")
                let downloadedFileInfos = downloadInfos.filter { $0.isCompleted }
                XCTAssertTrue(
                    downloadedFileInfos.count == lastEmojiInfos.count,
                    "다운로드 완료 후 파일 갯수가 요청된 파일 갯수와 다름"
                )
                return
                
            case let .unit(unitEvents):
                for try await unitEvent in unitEvents {
                    switch unitEvent {
                    case let .completed(data, downloadInfo):
                        let destinationURL = downloadInfo.fileInfo.destinationURL
                        log("⏹️ \(destinationURL)")
                        XCTAssertTrue(
                            data.count > 0,
                            "다운로드된 임시 로컬파일의 데이터가 없음"
                        )
                        XCTAssertTrue(downloadInfo.isCompleted, "다운로드 완료 상태")
                        
                    case let .update(currentBytes, totalBytes):
                        log("🆙 \(currentBytes)/\(totalBytes)")
                        if currentBytes > totalBytes {
                            XCTAssertTrue(
                                currentBytes <= totalBytes,
                                "다운로드된 데이터가 예상 다운로드 데이터보다 큼"
                            )
                        }
                        
                    case let .start(index, downloadInfo):
                        let sourceURL = downloadInfo.fileInfo.sourceURL
                        log("▶️ [\(index)] \(String(describing: sourceURL))")
                    }
                }
            case let .start(downloadInfos: downloadInfos):
                log("⏬▶️ \(downloadInfos.count)")
            }
        }
    }
    
    /// 다운로드 일시정지 후 다운로드
    func testPauseDownload() async throws {
        let lastEmojiInfos = try lastEmojiInfos(maxLength: 10)
        
        for try await event in await downloader.events(
            fileInfos: lastEmojiInfos
        ) {
            switch event {
            case let .allCompleted(downloadInfos):
                log("⏬⏹️")
                let downloadedFileInfos = downloadInfos.filter { $0.isCompleted }
                XCTAssertTrue(
                    downloadedFileInfos.count == lastEmojiInfos.count,
                    "다운로드 완료 후 파일 갯수가 요청된 파일 갯수와 다름"
                )
                return
                
            case let .unit(unitEvents):
                for try await unitEvent in unitEvents {
                    switch unitEvent {
                    case let .completed(data, downloadInfo):
                        let destinationURL = downloadInfo.fileInfo.destinationURL
                        log("⏹️ \(destinationURL)")
                        XCTAssertTrue(
                            data.count > 0,
                            "다운로드된 임시 로컬파일의 데이터가 없음"
                        )
                        XCTAssertTrue(downloadInfo.isCompleted, "다운로드 완료 상태")
                        
                    case let .update(currentBytes, totalBytes):
                        log("🆙 \(currentBytes)/\(totalBytes)")
                        if currentBytes > totalBytes {
                            XCTAssertTrue(
                                currentBytes <= totalBytes,
                                "다운로드된 데이터가 예상 다운로드 데이터보다 큼"
                            )
                        }
                        
                    case let .start(index, downloadInfo):
                        let sourceURL = downloadInfo.fileInfo.sourceURL
                        log("▶️ [\(index)] \(String(describing: sourceURL))")
                    }
                }
            case let .start(downloadInfos: downloadInfos):
                log("⏬▶️ \(downloadInfos.count)")
            }
        }
        try await Task.sleep(nanoseconds: NSEC_PER_SEC)
        
        await downloader.pause()
        log("pause")
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        
        await downloader.resume()
        log("resume")
        try await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)
    }
    
    /// 다운로드 일시정지 후 다운로드
    func testStopDownload() async throws {
        let firstEmojiInfos = try firstEmojiInfos(maxLength: 10)
        let lastEmojiInfos = try lastEmojiInfos(maxLength: 10)
        
        _ = await downloader.events(fileInfos: firstEmojiInfos)
        
        try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
        
        await downloader.stop()
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        
        await downloader.resume()
        
        try await Task.sleep(nanoseconds: 2 * NSEC_PER_SEC)
        
        _ = await downloader.events(fileInfos: lastEmojiInfos)
        
        try await Task.sleep(nanoseconds: 3 * NSEC_PER_SEC)
    }
}

// MARK: - Helper
extension DownloaderTests {
    /// 전체 이모지 리스트에서 앞에서 추출한 일부 이모지 리스트
    /// - Parameter maxLength: 자를 문자열 길이
    /// - Returns: 다운로드 받을 이모지 리스트
    private func firstEmojiInfos(maxLength: Int) throws -> [DownloadableEmojiInfo] {
        guard let firstEmojiSlice = downloadEmojiInfos?.prefix(maxLength)
        else { throw DownloadTestError.notEnoughEmojis }
        
        return Array(firstEmojiSlice)
    }
    
    /// 전체 이모지 리스트에서 ㅇ에서 추출한 일부 이모지 리스트
    /// - Parameter maxLength: 자를 문자열 길이
    /// - Returns: 다운로드 받을 이모지 리스트
    private func lastEmojiInfos(maxLength: Int) throws -> [DownloadableEmojiInfo] {
        guard let lastEmojiSlice = downloadEmojiInfos?.suffix(maxLength)
        else { throw DownloadTestError.notEnoughEmojis }
        
        return Array(lastEmojiSlice)
    }
    
    private func log(_ message: String) {
        print("\(Date().timestamp) 🔽\(message)")
    }
}

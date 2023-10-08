//
//  DownloadableDogImage.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/09.
//

import Foundation
import ConcurrencyDownloader

struct DownloadableDogImageInfo {
    let fileURL: URL
}

extension DownloadableDogImageInfo: Downloadable {
    var directoryURL: URL {
        let directoryPaths = NSSearchPathForDirectoriesInDomains(
            .libraryDirectory,
            .userDomainMask,
            true
        )
        
        let directoryURL = URL(fileURLWithPath: directoryPaths.first!)
        return directoryURL.appendingPathComponent("ConcurrencyDownload")
    }
    
    var sourceURL: URL {
        get throws {
            fileURL
        }
    }
}

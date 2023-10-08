//
//  URL+MIME.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/08.
//

import UniformTypeIdentifiers

extension URL {
    var mimeType: String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        else {
            return "application/octet-stream"
        }
    }
}

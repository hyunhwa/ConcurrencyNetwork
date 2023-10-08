//
//  UploadBodyObject.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/08/21.
//

import Foundation

/// Request Body 에 포함될 데이터 생성 객체
struct UploadBodyObject {
    /// form-data 구분을 위한 데이터 (UUID 를 일반적으로 사용함)
    var boundary: String
    /// 업로드할 파일 경로 리스트
    var fileURLs: [URL]
    /// form-data 의 키 값
    var name: String
    /// body 에 포함될 파라미터
    var parameters: [String: String]?
    
    /// body 데이터
    var data: Data {
        get throws {
            var data = Data()
            if let parametersData = parametersData {
                data.append(parametersData)
            }
            fileURLs.forEach { url in
                guard let fileData = try? Data(contentsOf: url)
                else { return }
                
                let fileName = url.lastPathComponent
                let mimeType = url.mimeType
                
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; ".data(using: .utf8)!)
                data.append("name=\"\(name)\"; ".data(using: .utf8)!)
                data.append("filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(fileData)
                data.append("\r\n".data(using: .utf8)!)
            }
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
            return data
        }
    }
    
    /// body 데이터에 포함될 파라미터 데이터
    private var parametersData: Data? {
        var data = Data()
        parameters?.forEach { key, value in
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; ".data(using: .utf8)!)
            data.append("name=\"\(key)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        return data
    }
}

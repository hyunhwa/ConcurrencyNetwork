//
//  UploadContent.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/07/17.
//

import Foundation

/// 업로드할 컨텐츠 타입
/// Data, URL, Stream 을 지원하며 name 은 미설정 시 공백 처리한다
public enum UploadContent: Equatable {
    /// Data 타입
    /// - data : 업로드할 data
    /// - name: form-data의 key (파라미터 키) (기본 multipartFile)
    /// - fileName: 업로드할 파일명
    /// - mimeType: 업로드할 파일의 MIME 타입 (기본 application/octet-stream)
    case data(
        _ data: Data,
        name: String = "multipartFile",
        fileName: String,
        mimeType: String = "application/octet-stream"
    )
    
    /// 로컬 파일 타입
    /// - url: 업로드할 파일 URL
    /// - name: form-data의 key (파라미터 키) (기본 multipartFile)
    case file(
        url: URL,
        name: String = "multipartFile"
    )
    
    /// 로컬 파일 타입 리스트
    /// - url: 업로드할 파일 URL 리스트
    /// - name: form-data의 key (파라미터 키) (기본 multipartFile)
    case files(
        url: [URL],
        name: String = "multipartFile"
    )
    
    // TODO: 추후 제공 예정
    /*case stream(
        InputStream,
        name: String = "multipartFile"
    )*/
}

extension UploadContent {
    /// form-data key
    var name: String {
        switch self {
        case let .data(_, name, _, _):
            return name
        case let .file(_, name):
            return name
        case let .files(_, name):
            return name
        }
    }
}

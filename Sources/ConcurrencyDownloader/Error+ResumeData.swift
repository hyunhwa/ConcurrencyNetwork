//
//  Error+resumeData.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/28.
//

import Foundation

extension Error {
    /// 다운로드 재개 데이터
    var resumeData: Data? {
        let userInfo = (self as NSError).userInfo
        return userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    }
}

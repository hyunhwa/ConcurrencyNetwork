//
//  Date+Timestamp.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/16.
//

import Foundation

extension Date {
    var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }
}

//
//  String+HtmlString.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/10/06.
//

import Foundation

extension String {
    /// HTML 문자열 여부
    var isHtmlString: Bool {
        if isEmpty {
            return false
        }
        
        return (range(
            of: "<(\"[^\"]*\"|'[^']*'|[^'\">])*>",
            options: .regularExpression
        ) != nil)
    }
}

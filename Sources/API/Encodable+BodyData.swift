//
//  Encodable+BodyData.swift
//  ConcurrencyNetwork
//
//  Created by hyunhwa on 2023/06/29.
//

import Foundation

extension Encodable {
    /// data 통신 시 body 영역에 포함될 데이터
    func httpBodyData(url: URL) throws -> Data? {
        let data = try JSONEncoder().encode(self)
        let jsonObject = try JSONSerialization.jsonObject(
            with: data,
            options: .allowFragments
        )
        
        guard let dictionary = jsonObject as? [String: Any]
        else { return data }
        
        // 쿼리 형식으로 값을 변경
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = dictionary.map { key, value in
            if JSONSerialization.isValidJSONObject(value) {
                let valueData = (try? JSONSerialization.data(withJSONObject: value)) ?? Data()
                let valueString = String(data: valueData, encoding: .utf8) ?? ""
                return URLQueryItem(name: key, value: "\(valueString)")
            } else { // nsobject 를 상속받는 객체가 아닌 경우
                return URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        return Data(components.url!.query!.utf8)
    }
}

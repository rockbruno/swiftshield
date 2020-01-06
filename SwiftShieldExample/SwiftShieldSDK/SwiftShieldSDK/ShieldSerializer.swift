//
//  Serializer.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 5/1/20.
//  Copyright © 2020 rockbruno. All rights reserved.
//

import Foundation

open class ShieldSerializer {
    
    public init() {}
    
    open func jsonContactsList() -> String? {
        let list = ContactsList()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(list)
        let jsonList = String(data: data, encoding: .utf8)
        print(jsonList ?? "encoding error")
        return jsonList
    }
    
    open func parseContactsList(json: String) -> ContactsList? {
        let data = json.data(using: .utf8)!
        let list = try! JSONDecoder().decode(ContactsList.self, from: data)
        return list
    }
}

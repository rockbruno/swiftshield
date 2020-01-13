//
//  Person.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 22/12/19.
//  Copyright © 2019 rockbruno. All rights reserved.
//

import Foundation

class Person: Codable {
    var firstName: String
    var lastName: String
    
    private enum _personCodingKeys: String, CodingKey {
        case firstName
        case lastName
    }
    
    init(_ firstName: String, _ lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
    
    func fullName() -> String {
        return "\(firstName) \(lastName)"
    }
    
    func getName(part: NameEnum) -> String? {
        switch part {
        case NameEnum.FIRST_NAME:
            return firstName
        case NameEnum.LAST_NAME:
            return lastName
        default:
            return nil
        }
    }
}


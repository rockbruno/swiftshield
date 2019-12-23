//
//  Person.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 22/12/19.
//  Copyright © 2019 rockbruno. All rights reserved.
//

import Foundation

class Person {
    var firstName: String
    var lastName: String
    
    init(_ firstName: String, _ lastName: String) {
        self.firstName = firstName
        self.lastName = lastName
    }
    
    func fullName() -> String {
        return "\(firstName) \(lastName)"
    }
}


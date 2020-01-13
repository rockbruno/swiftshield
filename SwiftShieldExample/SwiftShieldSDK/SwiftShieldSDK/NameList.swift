//
//  ContactsList.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 22/12/19.
//  Copyright © 2019 rockbruno. All rights reserved.
//

import Foundation


open class NameList {
    var names = Array<Person>()
    
    public init() {
        var person = Person("Bruce", "Lee")
        names.append(person)
        person = Person("Jackie", "Chan")
        names.append(person)
    }
    
    open func printNames() -> String {
        return privatePrintNames()
    }
    
    private func privatePrintNames() -> String {
        var contactsList = ""
        for person in names {
            contactsList += contactsList + person.fullName()
        }
        return contactsList
    }
}


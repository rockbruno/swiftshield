//
//  ContactsList.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 22/12/19.
//  Copyright © 2019 rockbruno. All rights reserved.
//

import Foundation


public class ContactsList {
    var contacts = Array<Person>()
    
    public init() {
        var person = Person("Bruce", "Lee")
        contacts.append(person)
        person = Person("Jackie", "Chan")
        contacts.append(person)
    }
    
    public func printContacts() -> String {
        return privatePrintContacts()
    }
    
    private func privatePrintContacts() -> String {
        var contactsList = ""
        for person in contacts {
            contactsList += contactsList + person.fullName()
        }
        return contactsList
    }
}


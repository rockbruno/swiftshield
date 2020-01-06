//
//  ContactsList.swift
//  SwiftShieldSDK
//
//  Created by Weidian on 22/12/19.
//  Copyright © 2019 rockbruno. All rights reserved.
//

import Foundation


public class ContactsList: Codable {
    var contacts = Array<Person>()
    
    private enum CodingKeys: String, CodingKey {
        case contacts
    }
    
    required public init(from decoder:Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var contacts = [Person]()
        if let count = container.count {
            contacts.reserveCapacity(count)
        }

        while !container.isAtEnd {
            let person = try container.decode(Person.self)
            contacts.append(person)
        }

        self.contacts = contacts
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(contacts)
    }
    
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


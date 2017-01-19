//
//  Regex.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

typealias RegexClosure = ((NSTextCheckingResult) -> String?)

extension String {
    var isNotAnEmptyCharacter: Bool {
        return self != " " && self != "\n"
    }
    var isNotUsingClassAsAParameterNameOrProtocol: Bool {
        return self != "`" && self != "{" && self != ":" && self != "_"
    }
    var isNotScopeIdentifier: Bool {
        return self != "public" && self != "open" && self != "private" && self != "dynamic" && self != "internal" && self != "var" && self != "let" && self != "final" && self != "func"
    }
}

extension String {
    func matchRegex(regex: String, mappingClosure: RegexClosure) -> [String] {
        let regex = try! NSRegularExpression(pattern: regex, options: [])
        let nsString = self as NSString
        let results = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map(mappingClosure).flatMap{$0}
    }
    
    static func random(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers : NSString = "0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        for i in 0 ..< length {
            let rand = arc4random_uniform(len)
            let characters: NSString = i == 0 ? letters : letters.appending(numbers as String) as NSString
            var nextChar = characters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        return randomString
    }
}

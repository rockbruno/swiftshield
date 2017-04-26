//
//  Regex.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

typealias RegexClosure = ((NSTextCheckingResult) -> String?)

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range)}
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

extension String {
    
    func match(regex: String) -> [NSTextCheckingResult] {
        let regex = try! NSRegularExpression(pattern: regex, options: [.caseInsensitive])
        let nsString = self as NSString
        return regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
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

extension String {
    
    static var swiftRegex: String {
        //TODO: Need a better way of getting everything, but keeping words together
        let comments = "(?:\\/\\/)|(?:\\/\\*)|(?:\\*\\/)"
        let words = "[a-zA-Z0-9\\u00C0-\\u017F]{1,99}"
        let quotes = "\\]\\[\\-\"\'"
        let swiftSymbols = "[" + ":{}(),.<_>/`?!@#©$%&~*+-^|=; \n\t" + quotes + "]"
        return comments + "|" + words + "|" + swiftSymbols
    }
    
    static func swiftRegexFor(tag: String) -> String {
        let words = "[a-zA-Z0-9_$]"
        return "\(words){0,99}\(tag)\(words){0,99}"
    }
    
    static var storyboardClassNameRegex: String {
        return "(?<=customClass=\").*?(?=\")"
    }
    
    static var helpText: String {
        return "\n\n-- Instructions --\n\nAUTOMATIC MODE:\n\nExample: swiftshield -auto -projectroot /app/MyApp -projectfile /app/MyApp/MyApp.xcodeproj -scheme 'MyApp-AppStore' -v\n\nRequired parameters:\n\n-auto -projectroot PATH (Path to your project root, like /app/MyApp \n\n-projectfile PATH (Path to your project file, like /app/MyApp/MyApp.xcodeproj or /app/MyApp/MyApp.xcworkspace)\n\n-scheme 'SCHEMENAME' (Main scheme to build)\n\nOptional parameters:\n\n-v (Verbose mode)" +
        "\n\nMANUAL MODE:\n\nExample: swiftshield -projectroot /app/MyApp -v -tag 'myTag'\n\nRequired parameters:\n\n-projectroot PATH (Path to your project root, like /app/MyApp \n\nOptional parameters:\n\n-tag 'myTag' (Custom tag. Default is 'shielded')\n\n-v (Verbose mode)"
    }
}

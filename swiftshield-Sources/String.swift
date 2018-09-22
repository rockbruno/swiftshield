//
//  Regex.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

typealias RegexClosure = ((NSTextCheckingResult) -> String?)

func firstMatch(for regex: String, in text: String) -> String? {
    return matches(for: regex, in: text).first
}

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

    static func random(length: Int, excluding: Set<String>) -> String {
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
        return excluding.contains(randomString) ? random(length: length, excluding: excluding) : randomString
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

    static func regexFor(tag: String) -> String {
        let words = "[a-zA-Z0-9_$]"
        return "\(words){0,99}\(tag)\\b"
    }

    static var storyboardClassNameRegex: String {
        return "((?<=customClass=\").*?(?=\" customModule)|(?<=action selector=\").*?(?=:\"))"
    }

    static var helpText: String {
        return "\n\n-- Instructions (See the rockbruno/swiftshield for more details) --\n\nAUTOMATIC MODE:\n\nExample: swiftshield -automatic -project-root /app/MyApp -automatic-project-file /app/MyApp/MyApp.xcworkspace -automatic-project-scheme MyApp-AppStore \n\nRequired parameters:\n\n-automatic -project-root PATH_TO_PROJECTS_ROOT_FOLDER \n\n-automatic-project-file PATH_TO_PROJECT_FILE \n\n-automatic-project-scheme SCHEME_NAME_TO_BUILD\n\nOptional parameters:\n\n-verbose (Uses verbose mode)\n\n-show-sourcekit-queries (Prints queries made to SourceKit)\n\n-ignore-modules MyLib,MyAppExtension (Prevents obfuscation of certain modules)\n\n-obfuscation-character-count 32 (Obfuscated name size)" +
        "\n\nMANUAL MODE:\n\nExample: swiftshield -project-root /app/MyApp -tag myTag\n\nRequired parameters:\n\n-project-root PATH_TO_PROJECTS_ROOT_FOLDER \n\nOptional parameters:\n\n-tag myTag (Custom tag to use. If not provided, '__s' will be used.)\n\n-verbose (Uses verbose mode)\n\n-obfuscation-character-count 32 (Obfuscated name size)"
    }
}

extension String {
    var trueName: String {
        return components(separatedBy: "(").first ?? self
    }
}

extension String {
    private var spacedFolderPlaceholder: String {
        return "\u{0}"
    }

    var replacingEscapedSpaces: String {
        return replacingOccurrences(of: "\\ ", with: spacedFolderPlaceholder)
    }

    var removingPlaceholder: String {
        return replacingOccurrences(of: spacedFolderPlaceholder, with: " ")
    }
}

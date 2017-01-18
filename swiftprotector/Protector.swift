//
//  Protect.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class Protector {
    private typealias ProtectedClassHash = [String:String]
    private let regex = "(?:\\/\\/)|(?:\\/\\*)|(?:\\*\\/)|[a-zA-Z0-9]{1,99}|[:{}(),._>/`?!@#$%&*+-^|=; \n" + "\\]\\[\\-\"\'" + "]"
    private let files : [SwiftFile]
    
    init(files: [SwiftFile]) {
        self.files = files
    }
    
    open func protect() {
        defer {
            exit(0)
        }
        let classHash = generateClassHash(from: files)
        guard classHash.isEmpty == false else {
            return
        }
       // protectClassReferences(hash: classHash)
        return
    }
    
    private func generateClassHash(from files: [SwiftFile]) -> ProtectedClassHash {
        
        print("Scanning class declarations")
        
        guard files.isEmpty == false else {
            return [:]
        }
        var classes: ProtectedClassHash = [:]
        let protectedClassNameSize = 15
        
        var shouldProtectNextWord = false
        var forbiddenZone: ForbiddenZone? = nil
        var previousWord = ""
        
        func regexMapClosure(fromData nsString: NSString) -> ((NSTextCheckingResult) -> String) {
            return { result in
                guard result.rangeAt(0).location != NSNotFound else {
                    return ""
                }
                let word = nsString.substring(with: result.rangeAt(0))
                defer {
                    previousWord = word
                }
                guard forbiddenZone == nil else {
                    if word == forbiddenZone?.zoneEnd {
                        forbiddenZone = nil
                    }
                    return ""
                }
                if shouldProtectNextWord == false {
                    if word == "class" {
                        if previousWord != "." && forbiddenZone == nil {
                            shouldProtectNextWord = true
                        }
                    } else {
                        forbiddenZone = ForbiddenZone(rawValue: word)
                    }
                    return ""
                } else {
                    guard word.isNotAnEmptyCharacter else {
                        return ""
                    }
                    shouldProtectNextWord = false
                    return word.isNotUsingClassAsAParameterNameOrProtocol && word.isNotScopeIdentifier ? word : ""
                }
            }
        }
        
        for file in swiftFiles {
            print("--- Checking \(file.name) ---")
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let newClasses = data.matchRegex(regex: regex, mappingClosure: regexMapClosure(fromData: data as NSString)).filter { word in
                return word != ""
            }
            newClasses.forEach {
                let protectedClassName = String.random(length: protectedClassNameSize)
                classes[$0] = protectedClassName
                print("\($0) -> \(protectedClassName)")
            }
            shouldProtectNextWord = false
        }
        return classes
    }
    
    private func protectClassReferences(hash: ProtectedClassHash) {
        func regexMapClosure(fromData nsString: NSString) -> ((NSTextCheckingResult) -> String) {
            return { result in
                let word = nsString.substring(with: result.rangeAt(0))
                guard let protectedWord = hash[word] else {
                    return word
                }
                return protectedWord
            }
        }
        for file in swiftFiles {
            print("--- Protecting \(file.name) ---")
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let protectedClassData = data.matchRegex(regex: regex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
            do {
                try protectedClassData.write(toFile: file.path, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                print("FATAL: \(error.localizedDescription)")
                exit(-1)
            }
        }
    }
}

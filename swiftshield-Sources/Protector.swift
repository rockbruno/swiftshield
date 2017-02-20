//
//  Protect.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

private let comments = "(?:\\/\\/)|(?:\\/\\*)|(?:\\*\\/)"
private let words = "[a-zA-Z0-9\\u00C0-\\u017F]{1,99}"
private let quotes = "\\]\\[\\-\"\'"
private let swiftSymbols = "[" + ":{}(),.<_>/`?!@#©$%&*+-^|=; \n" + quotes + "]"

private let swiftRegex = comments + "|" + words + "|" + swiftSymbols

class Protector {
    private let swiftFiles : [File]
    private let storyboardFiles: [File]
    
    init() {
        self.swiftFiles = []
        self.storyboardFiles = []
    }
    
    init(swiftFiles: [File], storyboardFiles: [File]) {
        self.swiftFiles = swiftFiles
        self.storyboardFiles = storyboardFiles
    }
    
    func getProtectionHash(projectPaths: [String]) -> ProtectedClassHash {
        Logger.log("-- Scanning declarations --")
        guard swiftFiles.isEmpty == false else {
            return ProtectedClassHash(hash: [:])
        }
        var classes: [String:String] = [:]
        var scanData = SwiftFileScanData()
        
        let modules = self.retrieveModuleNames(projectPaths: projectPaths)
        Logger.log("Found these modules: \(modules)", verbose: true)
        
        modules.forEach {
            classes[$0] = $0
        }
        
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                scanData.currentWord = nsString.substring(with: result.rangeAt(0))
                defer {
                    scanData.prepareForNextWord()
                }
                guard scanData.shouldIgnoreCurrentWord == false else {
                    scanData.stopIgnoringWordsIfNeeded()
                    return scanData.currentWord
                }
                guard scanData.shouldProtectNextWord else {
                    scanData.protectNextWordIfNeeded()
                    scanData.startIgnoringWordsIfNeeded()
                    return scanData.currentWord
                }
                guard scanData.currentWord.isNotAnEmptyCharacter else {
                    return scanData.currentWord
                }
                scanData.shouldProtectNextWord = false
                guard scanData.wordSuccedingClassStringIsActuallyAProtectableClass else {
                    return scanData.currentWord
                }
                let protectedClassName = (classes[scanData.currentWord] != nil ? classes[scanData.currentWord] : String.random(length: protectedClassNameSize))!
                classes[scanData.currentWord] = protectedClassName
                Logger.log("\(scanData.currentWord) -> \(protectedClassName)", verbose: true)
                return protectedClassName
            }
        }
        for file in swiftFiles {
            Logger.log("--- Checking \(file.name) ---", verbose: true)
            autoreleasepool {
                do {
                    let data = try String(contentsOfFile: file.path, encoding: .utf8)
                    let newClasses = data.matchRegex(regex: swiftRegex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
                    try newClasses.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
                    scanData = SwiftFileScanData()
                } catch {
                    Logger.log("FATAL: \(error.localizedDescription)")
                    exit(error: true)
                }
            }
        }
        return ProtectedClassHash(hash: classes)
    }
    
    func protectStoryboards(data: ObfuscationData) {
        let storyboardClassNameRegex = "(?<=customClass=\").*?(?=\")"
        Logger.log("--- Overwriting Storyboards ---")
        for file in storyboardFiles {
            Logger.log("--- Checking \(file.name) ---", verbose: true)
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let retrievedClasses = data.matchRegex(regex: storyboardClassNameRegex) { result in
                (data as NSString).substring(with: result.rangeAt(0))
                }.removeDuplicates()
            var overwrittenData = data
            for `class` in retrievedClasses {
                guard let protectedClass = hash.hash[`class`] else {
                    continue
                }
                Logger.log("\(`class`) -> \(protectedClass)", verbose: true)
                overwrittenData = overwrittenData.replacingOccurrences(of: Storyboard.customClass(class: `class`), with: Storyboard.customClass(class: protectedClass))
            }
            guard overwrittenData != data else {
                Logger.log("--- \(file.name) was not modified, continuing ---", verbose: true)
                continue
            }
            Logger.log("--- Saving \(file.name) ---", verbose: true)
            do {
                try overwrittenData.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log("FATAL: \(error.localizedDescription)")
                exit(error: true)
            }
        }
    }
    
    func protectClassReferences(output: BuildOutput, protectedHash: ProtectedClassHash) {
        var line = 1
        var column = 1
        
        var currentErrors: [ErrorData] = []
        
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                let word = nsString.substring(with: result.rangeAt(0))
                var wordToReturn = word
                if currentErrors.isEmpty == false && line == currentErrors[0].line && column == currentErrors[0].column {
                    currentErrors.remove(at: 0)
                    wordToReturn = (protectedHash.hash[word] ?? word)
                }
                if word == "\n" {
                    line += 1
                    column = 1
                    return wordToReturn
                } else {
                    column += word.characters.count
                    return wordToReturn
                }
            }
        }
        for (file,errorData) in output {
            autoreleasepool {
                func lesserPosition(_ e1: ErrorData, _ e2: ErrorData) -> Bool {
                    if e1.line != e2.line {
                        return e1.line < e2.line
                    } else {
                        return e1.column < e2.column
                    }
                }
                let sortedData = errorData.filterDuplicates { $0.line == $1.line && $0.column == $1.column }.sorted(by: lesserPosition)
                line = 1
                column = 1
                let data = try! String(contentsOfFile: file.path, encoding: .utf8)
                currentErrors = sortedData
                Logger.log("--- Overwriting \(file.name) (\(errorData.count) changes) ---")
                let protectedClassData = data.matchRegex(regex: swiftRegex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
                do {
                    try protectedClassData.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    Logger.log("FATAL: \(error.localizedDescription)")
                    exit(error: true)
                }
            }
        }
    }
    
    func writeToFile(hash: ProtectedClassHash) {
        Logger.log("--- Generating conversion map ---")
        var output = ""
        output += "//\n"
        output += "//  SwiftShield\n"
        output += "//  Conversion Map\n"
        output += "//\n"
        output += "\n"
        output += "Classes:"
        output += "\n"
        for (k,v) in hash.hash {
            output += "\n\(k) ===> \(v)"
        }
        let path = basePath + (basePath.characters.last == "/" ? "" : "/") + "swiftshield-output"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        do {
            try output.write(toFile: path + "/conversionMap.txt", atomically: false, encoding: String.Encoding.utf8)
        } catch {
            Logger.log("FATAL: Failed to generate conversion map: \(error.localizedDescription)")
        }
    }
}

//
//  Protect.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

private let comments = "(?:\\/\\/)|(?:\\/\\*)|(?:\\*\\/)"
private let words = "[a-zA-Z0-9]{1,99}"
private let quotes = "\\]\\[\\-\"\'"
private let swiftSymbols = "[" + ":{}(),.<_>/`?!@#$%&*+-^|=; \n" + quotes + "]"

private let swiftRegex = comments + "|" + words + "|" + swiftSymbols
private let storyboardClassNameRegex = "(?<=customClass=\").*?(?=\")"

typealias BuildOutput = [File:[ErrorData]]

class Protector {
    private let swiftFiles : [File]
    private let storyboardFiles: [File]
    
    init(swiftFiles: [File], storyboardFiles: [File]) {
        self.swiftFiles = swiftFiles
        self.storyboardFiles = storyboardFiles
    }
    
    func protect() {
        defer {
            exit(0)
        }
       // let classHash = generateClassHash()
       /* guard classHash.isEmpty == false else {
            Logger.log("No class files to obfuscate.")
            return
        } */
       /* protectClassReferences(hash: classHash)
        if storyboardFiles.isEmpty == false {
            protectStoryboards(hash: classHash)
        }
        writeToFile(hash: classHash) */
        return
    }
    
    func getProtectionHash() -> ProtectedClassHash {
        Logger.log("Scanning class/method declarations")
        guard swiftFiles.isEmpty == false else {
            return ProtectedClassHash(hash: [:])
        }
        var classes: [String:String] = [:]
        var scanData = SwiftFileScanData(phase: .reading)
        
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
                Logger.log("\(scanData.currentWord) -> \(protectedClassName)")
                return protectedClassName
            }
        }
        for file in swiftFiles {
            Logger.log("--- Checking \(file.name) ---")
            autoreleasepool {
                do {
                    let data = try String(contentsOfFile: file.path, encoding: .utf8)
                    let newClasses = data.matchRegex(regex: swiftRegex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
                    try newClasses.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
                    scanData = SwiftFileScanData(phase: .reading)
                } catch {
                    Logger.log("FATAL: \(error.localizedDescription)")
                    exit(1)
                }
            }
        }
        return ProtectedClassHash(hash: classes)
    }
    
    func protectStoryboards(hash: ProtectedClassHash) {
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
                exit(1)
            }
        }
    }
    
    func protectClassReferences(output: BuildOutput, protectedHash: ProtectedClassHash) {
        Logger.log("--- Overwriting .swift class references ---")
        
        var line = 1
        var column = 1
        
        var currentErrors: [ErrorData] = []
        
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                let word = nsString.substring(with: result.rangeAt(0))
                var wordToReturn = word/*
                if currentErrors.isEmpty == false {
                    print("Current error at line \(currentErrors[0].line) and column \(currentErrors[0].column). File at line \(line) and column \(column). Error target is \(currentErrors[0].target) and retrieved word was \(word) Full error \(currentErrors[0].fullError).")
                } else {
                    print("No more errors for this file")
                }*/
                if currentErrors.isEmpty == false && line == currentErrors[0].line && column == currentErrors[0].column {
                    /*print("Reached line \(currentErrors[0].line) and column \(currentErrors[0].column). Error target is \(currentErrors[0].target) and retrieved word was \(word). Full error: \(currentErrors[0].fullError)")*/
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
                Logger.log("--- Overwriting \(file.name) ---")
                let protectedClassData = data.matchRegex(regex: swiftRegex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
                do {
                    try protectedClassData.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    Logger.log("FATAL: \(error.localizedDescription)")
                    exit(1)
                }
            }
        }
    }
    
    func getSchemes() -> [String] {
        Logger.log("Getting schemes")
        let path = "/usr/bin/xcodebuild"
        let arguments: [String] = ["-list", "-workspace", basePath+workspaces[0]]
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        var output = String(data: outdata, encoding: .utf8)?.components(separatedBy: "Schemes:")
        output?.remove(at: 0)
        output = output![0].replacingOccurrences(of: "\n", with: "").components(separatedBy: "        ")
        output?.remove(at: 0)
        return output!
    }
    
    func runFakeBuild(scheme: String) -> String {
        Logger.log("Performing fake build to detect class references. This can take a few minutes...")
        let path = "/usr/bin/xcodebuild"
        let arguments: [String] = ["-quiet", "-workspace", basePath+workspaces[0], "-scheme", scheme]
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outdata, encoding: .utf8)
        //print(output!)
        return output!
    }
    
    func parse(fakeBuildOutput: String) -> [File:[ErrorData]] {
        //TODO: Get all specific errors to prevent swapping things that have nothing to do with SwiftShield
        let errorRegex = "/.* error:.*'.*'"
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                return nsString.substring(with: result.rangeAt(0))
            }
        }
        let data = fakeBuildOutput.matchRegex(regex: errorRegex, mappingClosure: regexMapClosure(fromData: fakeBuildOutput as NSString))
        var errorDataHash: BuildOutput = BuildOutput()
        for error in data {
            guard let errorData = ErrorData(fullError: error), errorData.file.name.contains(".swift") else {
                continue
            }
            if let lastError = errorDataHash[errorData.file]?.last, errorData.line == lastError.line && errorData.column == lastError.column {
                continue
            }
            errorDataHash[errorData.file] == nil ? errorDataHash[errorData.file] = [errorData] : errorDataHash[errorData.file]!.append(errorData)
        }
        return errorDataHash
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
    
    /*
    private func protectClassReferences(hash: ProtectedClassHash) {
        Logger.log("--- Overwriting .swift files ---")
        var scanData = SwiftFileScanData(phase: .overwriting)
        
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                scanData.currentWord = nsString.substring(with: result.rangeAt(0))
                defer {
                    scanData.prepareForNextWord()
                }
                guard scanData.shouldIgnoreCurrentWord == false || scanData.beginOfInterpolatedZone else {
                    scanData.stopIgnoringWordsIfNeeded()
                    return scanData.currentWord
                }
                guard scanData.currentWordIsNotAFramework && scanData.currentWordIsNotAStandardSwiftClass, let protectedWord = hash.hash[scanData.currentWord] else {
                    scanData.startIgnoringWordsIfNeeded()
                    return scanData.currentWord
                }
                return protectedWord
            }
        }
        for file in swiftFiles {
            autoreleasepool {
                let data = try! String(contentsOfFile: file.path, encoding: .utf8)
                let protectedClassData = data.matchRegex(regex: swiftRegex, mappingClosure: regexMapClosure(fromData: data as NSString)).joined()
                do {
                    Logger.log("--- Overwriting \(file.name) ---")
                    try protectedClassData.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
                    scanData = SwiftFileScanData(phase: .overwriting)
                } catch {
                    Logger.log("FATAL: \(error.localizedDescription)")
                    exit(1)
                }
            }
        }
    }
    
    private func writeToFile(hash: ProtectedClassHash) {
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
    */
}

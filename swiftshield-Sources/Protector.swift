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
                guard scanData.wordSuccedingClassStringIsActuallyAClass else {
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
    
    func runFakeBuild() -> String {
        Logger.log("Getting the location of classes and methods by performing a fake build. This can take a few minutes.")
        let path = "/usr/bin/xcodebuild"
        let arguments: [String] = {
            var array: [String] = []
            if workspaces.count == 1 {
                array.append(contentsOf: ["-workspace",basePath+"/"+workspaces[0]])
            } else {
                array.append(contentsOf: ["-project",basePath+"/"+projects[0]])
            }
            return array
        }()
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outdata, encoding: .utf8)
        return output!
    }
    
    func parse(fakeBuildOutput: String) -> [String:[ErrorData]] {
        //TODO: Get all specific errors to prevent swapping things that have nothing to do with SwiftShield
        let errorRegex = "/.* error:.*'.*'"
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                return nsString.substring(with: result.rangeAt(0))
            }
        }
        let data = fakeBuildOutput.matchRegex(regex: errorRegex, mappingClosure: regexMapClosure(fromData: fakeBuildOutput as NSString))
        var errorDataHash = [String:[ErrorData]]()
        for error in data {
            let separated = error.components(separatedBy: ":")
            let file = separated[0]
            let line = separated[1]
            let padding = separated[2]
            let separatedError = separated[4].components(separatedBy: "'")
            let error = separatedError[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let target = separatedError[1]
            let errorData = ErrorData(file: file, line: Int(line)!, padding: Int(padding)!, error: error, target: target)
            if errorDataHash[file] == nil {
                errorDataHash[file] = [errorData]
            } else {
                errorDataHash[file]!.append(errorData)
            }
        }
        return errorDataHash
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
    
    private func protectStoryboards(hash: ProtectedClassHash) {
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

//
//  Protect.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class Protector {
    
    func index(modules: [Module]) -> ObfuscationData {
        let SK = SourceKit()
        let obfuscationData = ObfuscationData()
        for module in modules {
            for file in module.files {
                guard file.path.isEmpty == false else {
                    continue
                }
                let compilerArgs = SK.array(argv: module.compilerArguments)
                Logger.log("-- Indexing \(file.name) --")
                let resp = SK.indexFile(filePath: file.path, compilerArgs: compilerArgs)
                if let error = SK.error(resp: resp) {
                    Logger.log("ERROR: Could not index \(file.name), aborting. SK Error: \(error)")
                    exit(error: true)
                }
                let dict = SKApi.sourcekitd_response_get_value(resp)
                SK.recurseOver( childID: SK.entitiesID, resp: dict, block: { dict in
                    let kind = dict.getUUIDString(key: SK.kindID)
                    guard SK.isObjectDeclaration(kind: kind),
                        let name = dict.getString(key: SK.nameID),
                        let usr = dict.getString(key: SK.usrID) else {
                        return
                    }
                    let obfuscatedName = obfuscationData.obfuscationDict[name] ?? String.random(length: protectedClassNameSize)
                    obfuscationData.obfuscationDict[name] = obfuscatedName
                    obfuscationData.usrDict[usr] = true
                    Logger.log("Found declaration of \(name) (\(usr)) -> now \(obfuscatedName)")
                })
                obfuscationData.indexedFiles.append((file,resp))
            }
        }
        return obfuscationData
    }
    
    func obfuscateReferences(obfuscationData: ObfuscationData) {
        let SK = SourceKit()
        Logger.log("-- Finding references of the retrieved USRs --")
        for (file,indexResponse) in obfuscationData.indexedFiles {
            let dict = SKApi.sourcekitd_response_get_value(indexResponse)
            SK.recurseOver( childID: SK.entitiesID, resp: dict, block: { dict in
                let kind = dict.getUUIDString(key: SK.kindID)
                guard SK.isObjectReference(kind: kind) else {
                    return
                }
                guard let usr = dict.getString(key: SK.usrID), let name = dict.getString(key: SK.nameID) else {
                    return
                }
                let line = dict.getInt(key: SK.lineID)
                let column = dict.getInt(key: SK.colID)
                if obfuscationData.usrDict[usr] == true {
                    Logger.log("Found \(name) (\(usr)) at \(file.name) (L:\(line) C: \(column)")
                    let reference = ReferenceData(name: name, line: line, column: column, file: file, usr: usr)
                    obfuscationData.add(reference: reference, toFile: file)
                }
            })
        }
        overwriteFiles(obfuscationData: obfuscationData)
    }
    
    fileprivate func overwriteFiles(obfuscationData: ObfuscationData) {
        for (file,references) in obfuscationData.referencesDict {
            var sortedReferences = references.filterDuplicates { $0.line == $1.line && $0.column == $1.column }.sorted(by: lesserPosition)
            var line = 1
            var column = 1
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            Logger.log("--- Overwriting \(file.name) ---")
            let obfuscatedFile = data.matchRegex(regex: String.swiftRegex, mappingClosure: { result in
                let word = (data as NSString).substring(with: result.rangeAt(0))
                var wordToReturn = word
                if sortedReferences.isEmpty == false && line == sortedReferences[0].line && column == sortedReferences[0].column {
                    sortedReferences.remove(at: 0)
                    wordToReturn = (obfuscationData.obfuscationDict[word] ?? word)
                }
                if word == "\n" {
                    line += 1
                    column = 1
                } else {
                    column += word.characters.count
                }
                return wordToReturn
            }).joined()
            do {
                try obfuscatedFile.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log("FATAL: \(error.localizedDescription)")
                exit(error: true)
            }
        }
    }
    
    func protectStoryboards(data obfuscationData : ObfuscationData) {
        Logger.log("--- Overwriting Storyboards ---")
        for file in getStoryboardsAndXibs() {
            Logger.log("--- Checking \(file.name) ---", verbose: true)
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let retrievedClasses = data.matchRegex(regex: String.storyboardClassNameRegex) { result in
                (data as NSString).substring(with: result.rangeAt(0))
                }.removeDuplicates()
            var overwrittenData = data
            for `class` in retrievedClasses {
                guard let protectedClass = obfuscationData.obfuscationDict[`class`] else {
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
    
    func writeToFile(data: ObfuscationData) {
        Logger.log("--- Generating conversion map ---")
        var output = ""
        output += "//\n"
        output += "//  SwiftShield\n"
        output += "//  Conversion Map\n"
        output += "//\n"
        output += "\n"
        output += "Data:"
        output += "\n"
        for (k,v) in data.obfuscationDict {
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

//MARK: Manual Mode

extension Protector {
    func findAndProtectReferencesManually(tag: String, swiftFiles: [File]) -> ObfuscationData {
        Logger.log("Scanning class/method declarations")
        let obfsData = ObfuscationData()
        for file in swiftFiles {
            Logger.log("--- Checking \(file.name) ---")
            do {
                let data = try String(contentsOfFile: file.path, encoding: .utf8)
                var currentIndex = data.startIndex
                let newFile = data.matchRegex(regex: String.swiftRegexFor(tag: tag)) { result in
                    let word = (data as NSString).substring(with: result.rangeAt(0))
                    let protectedName = (obfsData.obfuscationDict[word] != nil ? obfsData.obfuscationDict[word] : String.random(length: protectedClassNameSize))!
                    obfsData.obfuscationDict[word] = protectedName
                    Logger.log("\(word) -> \(protectedName)")
                    let range: Range = currentIndex..<data.index(data.startIndex, offsetBy: result.range.location)
                    currentIndex = data.index(range.upperBound, offsetBy: result.range.length)
                    return data.substring(with: range) + protectedName
                }.joined()
                try newFile.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log("FATAL: \(error.localizedDescription)")
                exit(1)
            }
        }
        return obfsData
    }
}

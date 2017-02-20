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
                objc_sync_enter(self)
                guard file.path.isEmpty == false else {
                    continue
                }
                let compilerArgs = SK.array(argv: module.compilerArguments)
                Logger.log("-- Indexing \(file.name) --")
                let resp = SK.editorOpen(filePath: file.path, compilerArgs: compilerArgs)
                if let error = SK.error(resp: resp) {
                    Logger.log("ERROR: Could not index \(file.name), aborting. SK Error: \(error)")
                    exit(error: true)
                }
                let dict = SKApi.sourcekitd_response_get_value(resp)
                SK.recurseOver( childID: SK.substructureID, resp: dict, block: { dict in
                    let kind = dict.getUUIDString(key: SK.kindID)
                    guard SK.isObjectDeclaration(kind: kind),
                        let name = dict.getString(key: SK.nameID),
                        let runtimeName = dict.getString(key: SK.runtimeNameID) else {
                        return
                    }
                    let obfuscatedName = obfuscationData.obfuscationDict[name] ?? String.random(length: protectedClassNameSize)
                    obfuscationData.obfuscationDict[name] = obfuscatedName
                    obfuscationData.runtimeNameDict[runtimeName] = true
                    Logger.log("Found declaration of \(name) (\(runtimeName)) -> now \(obfuscatedName)")
                })
                obfuscationData.indexedFiles.append((file,module,resp))
                objc_sync_exit(self)
            }
        }
        return obfuscationData
    }
    
    func obfuscateReferences(obfuscationData: ObfuscationData) {
        let SK = SourceKit()
        Logger.log("-- Finding references of the retrieved USRs --")
        for (file,module,indexResponse) in obfuscationData.indexedFiles {
            let dict = SKApi.sourcekitd_response_get_value(indexResponse)
            objc_sync_enter(self)
            SK.recurseOver( childID: SK.substructureID, resp: dict, block: { dict in
                let kind = dict.getUUIDString(key: SK.kindID)
                guard SK.isObjectReference(kind: kind)else {
                    return
                }
                let offset = dict.getInt(key: SK.nameOffsetID) != 0 ? dict.getInt(key: SK.nameOffsetID) : dict.getInt(key: SK.offsetID)
                let compilerArgs = SK.array(argv: module.compilerArguments)
                let resp = SK.cursorInfo(filePath: file.path, byteOffset: Int32(offset), compilerArgs: compilerArgs)
                if let error = SK.error(resp: resp) {
                    Logger.log("ERROR: Could not find cursor info of \(file.name) (offset \(offset)), aborting. SK Error: \(error)")
                    exit(error: true)
                }
                let cursorDict = SKApi.sourcekitd_response_get_value(resp)
                guard let usr = cursorDict.getString(key: SK.usrID), let name = cursorDict.getString(key: SK.nameID), let typeUsr = cursorDict.getString(key: SK.typeUsrID) else {
                    return
                }
                let runtimeName = typeUsr + usr.components(separatedBy: ":")[1]
                Logger.log("Found \(name) (\(runtimeName)) at \(file.name) (offset: \(offset)", verbose: true)
                if obfuscationData.runtimeNameDict[runtimeName] == true {
                    let reference = ReferenceData(name: name, offset: offset, file: file, runtimeName: runtimeName)
                    obfuscationData.add(reference: reference, toFile: file)
                }
            })
            objc_sync_exit(self)
        }
        overwriteFiles(obfuscationData: obfuscationData)
    }
    
    fileprivate func overwriteFiles(obfuscationData: ObfuscationData) {
        let comments = "(?:\\/\\/)|(?:\\/\\*)|(?:\\*\\/)"
        let words = "[a-zA-Z0-9\\u00C0-\\u017F]{1,99}"
        let quotes = "\\]\\[\\-\"\'"
        let swiftSymbols = "[" + ":{}(),.<_>/`?!@#©$%&*+-^|=; \n" + quotes + "]"
        let swiftRegex = comments + "|" + words + "|" + swiftSymbols
        
        for (file,references) in obfuscationData.referencesDict {
            var sortedReferences = references.filterDuplicates { $0.offset == $1.offset }.sorted(by: lesserPosition)
            var offset = 1
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            Logger.log("--- Overwriting \(file.name) ---")
            let obfuscatedFile = data.matchRegex(regex: swiftRegex, mappingClosure: { result in
                let word = (data as NSString).substring(with: result.rangeAt(0))
                var wordToReturn = word
                if sortedReferences.isEmpty == false && offset == sortedReferences[0].offset {
                    sortedReferences.remove(at: 0)
                    wordToReturn = (obfuscationData.obfuscationDict[word] ?? word)
                }
                offset += word.characters.count
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

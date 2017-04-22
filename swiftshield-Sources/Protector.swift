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
                Logger.log(.indexing(file: file))
                let resp = SK.indexFile(filePath: file.path, compilerArgs: compilerArgs)
                if let error = SK.error(resp: resp) {
                    Logger.log(.indexError(file: file, error: error))
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
                    let obfuscatedName: String = {
                        guard let protected = obfuscationData.obfuscationDict[name] else {
                            let protected =  String.random(length: protectedClassNameSize)
                            obfuscationData.obfuscationDict[name] = protected
                            return protected
                        }
                        return protected
                    }()
                    obfuscationData.usrDict.insert(usr)
                    Logger.log(.foundDeclaration(name: name, usr: usr, newName: obfuscatedName))
                })
                obfuscationData.indexedFiles.append((file,resp))
            }
        }
        return obfuscationData
    }
    
    func obfuscateReferences(obfuscationData: ObfuscationData) {
        let SK = SourceKit()
        Logger.log(.searchingReferencesOfUsr)
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
                if obfuscationData.usrDict.contains(usr) {
                    Logger.log(.foundReference(name: name, usr: usr, at: file, line: line, column: column))
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
            Logger.log(.overwriting(file: file))
            let matches = data.match(regex: String.swiftRegex)
            let obfuscatedFile = matches.flatMap { result in
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
            }.joined()
            do {
                try obfuscatedFile.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log(.fatal(error: error.localizedDescription))
                exit(error: true)
            }
        }
    }
    
    func protectStoryboards(data obfuscationData : ObfuscationData) {
        Logger.log(.overwritingStoryboards)
        for file in getStoryboardsAndXibs() {
            Logger.log(.checking(file: file))
            //TODO: We can do the index approach here as well instead of replacingOccurences.
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let matches = data.match(regex: String.storyboardClassNameRegex)
            let retrievedClasses = matches.flatMap { result in
                (data as NSString).substring(with: result.rangeAt(0))
            }
            var overwrittenData = data
            for `class` in retrievedClasses.removeDuplicates() {
                guard let protectedClass = obfuscationData.obfuscationDict[`class`] else {
                    continue
                }
                Logger.log(.protectedReference(originalName: `class`, protectedName: protectedClass))
                overwrittenData = overwrittenData.replacingOccurrences(of: Storyboard.customClass(class: `class`), with: Storyboard.customClass(class: protectedClass))
            }
            guard overwrittenData != data else {
                Logger.log(.fileNotModified(file: file))
                continue
            }
            Logger.log(.saving(file: file))
            do {
                try overwrittenData.write(toFile: file.path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log(.fatal(error: error.localizedDescription))
                exit(error: true)
            }
        }
    }
    
    func writeToFile(data: ObfuscationData) {
        Logger.log(.generatingConversionMap)
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
            Logger.log(.fatal(error: error.localizedDescription))
        }
    }
}

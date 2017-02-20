//
//  Protector++SourceKit.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

extension Protector {
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
                SK.recurseOver( childID: SK.entitiesID, resp: dict, visualiser: nil, block: { dict in
                    guard let usr = dict.getString(key: SK.usrID) else {
                        return
                    }
                    let kind = dict.getUUIDString(key: SK.kindID)
                    guard SK.isObjectDeclaration(kind: kind), let name = dict.getString(key: SK.nameID) else {
                        return
                    }
                    let obfuscatedName = obfuscationData.obfuscationDict[name] ?? String.random(length: protectedClassNameSize)
                    obfuscationData.obfuscationDict[name] = obfuscatedName
                    obfuscationData.indexedFiles.append((file,resp))
                    obfuscationData.usrDict[usr] = []
                    Logger.log("Found declaration of \(name) (\(usr)) -> now \(obfuscatedName)")
                })
            }
        }
        return obfuscationData
    }
    
    func obfuscateImplementations(obfuscationData: ObfuscationData) {
        let SK = SourceKit()
        Logger.log("-- Finding implementations of the retrieved USRs --")
        for (file,indexResponse) in obfuscationData.indexedFiles {
            let dict = SKApi.sourcekitd_response_get_value(indexResponse)
            SK.recurseOver( childID: SK.entitiesID, resp: dict, visualiser: nil, block: { dict in
                guard let usr = dict.getString(key: SK.usrID), let name = dict.getString(key: SK.nameID) else {
                    return
                }
                if obfuscationData.usrDict[usr] != nil {
                    let line = dict.getInt(key: SK.lineID)
                    let col = dict.getInt(key: SK.colID)
                    let implementation = ImplementationData(file: file, name: name, line: line, column: col)
                    obfuscationData.usrDict[usr]?.append(implementation)
                    Logger.log("Found \(name) (\(usr)) at \(file.name) (L:\(line) C:\(col))")
                }
            })
        }
    }
}

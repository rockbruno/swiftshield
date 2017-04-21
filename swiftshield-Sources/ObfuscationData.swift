//
//  ObfuscationData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

class ObfuscationData {
    var usrDict: Set<String> = []
    var referencesDict: [File:[ReferenceData]] = [:]
    var obfuscationDict: [String:String] = [:]
    var indexedFiles: [(File,sourcekitd_response_t)] = []
    
    func add(reference: ReferenceData, toFile file: File) {
        if referencesDict[file] == nil {
            referencesDict[file] = []
        }
        referencesDict[file]?.append(reference)
    }
}

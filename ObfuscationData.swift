//
//  ObfuscationData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

class ObfuscationData {
    var usrDict: [String:[ImplementationData]] = [:]
    var obfuscationDict: [String:String] = [:]
    var indexedFiles: [(File,sourcekitd_response_t)] = []
}

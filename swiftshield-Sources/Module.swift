//
//  Module.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

struct Module {
    let name: String
    let files: [File]
    let compilerArguments: [String]
    
    init(name: String, files: [File], compilerArguments: [String]) {
        self.name = name
        self.files = files
        self.compilerArguments = compilerArguments
    }
}

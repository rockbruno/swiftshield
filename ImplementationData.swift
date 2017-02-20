//
//  ObjectData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

class ImplementationData {
    let file: File
    let name: String
    let line: Int
    let column: Int
    
    init(file: File, name: String, line: Int, column: Int) {
        self.file = file
        self.name = name
        self.line = line
        self.column = column
    }
}

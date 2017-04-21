//
//  ObjectData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

class ReferenceData {
    let name: String
    let line: Int
    let column: Int
    let file: File
    let usr: String
    
    init(name: String, line: Int, column: Int, file: File, usr: String) {
        self.name = name
        self.line = line
        self.column = column
        self.file = file
        self.usr = usr
    }
}

func lesserPosition(_ e1: ReferenceData, _ e2: ReferenceData) -> Bool {
    if e1.line != e2.line {
        return e1.line < e2.line
    } else {
        return e1.column < e2.column
    }
}

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
    let offset: Int
    let file: File
    let runtimeName: String
    
    init(name: String, offset: Int, file: File, runtimeName: String) {
        self.name = name
        self.offset = offset
        self.file = file
        self.runtimeName = runtimeName
    }
}

func lesserPosition(_ e1: ReferenceData, _ e2: ReferenceData) -> Bool {
    return e1.offset < e2.offset
}

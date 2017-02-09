//
//  ErrorData.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/8/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

struct ErrorData {
    let file: String
    let line: Int
    let padding: Int
    let error: String
    let target: String
    
    init(file: String, line: Int, padding: Int, error: String, target: String) {
        self.file = file
        self.line = line
        self.padding = padding
        self.error = error
        self.target = target
    }
}

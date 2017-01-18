//
//  main.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation
/*
if CommandLine.arguments.count < 2 {
    print("Missing path to source files.")
    exit(1)
}*/

print("Swift Protector 0.1")

let argument = "/Users/bruno.rocha/Desktop/Personal Codes/vivo-learning-ios-protect-test"
print("Base path: \(argument)")
var filePaths:[String] = []
let swiftSuffix = ".swift"
if let s = findSwiftFiles(rootPath: argument, suffix: swiftSuffix) {
    filePaths = s
}

let swiftFiles = filePaths.flatMap { try? SwiftFile(filePath: $0) }
let protector = Protector(files: swiftFiles)
protector.protect()

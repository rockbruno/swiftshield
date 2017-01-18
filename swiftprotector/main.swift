//
//  main.swift
//  swiftprotector/Users/bruno.rocha/Desktop/Personal Codes/swiftprotector/SwiftProtectorExample/SwiftProtectorExample/ViewController.swift
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

let verbose = CommandLine.arguments.contains("-v")

print("Swift Protector 0.1")

let basePath = "/Users/bruno.rocha/Desktop/Personal Codes/swiftprotector/SwiftProtectorExample/SwiftProtectorExample/Toscrew/here"
let protectedClassNameSize = 15

var filePaths:[String] = []
let swiftSuffix = ".swift"
if let s = findSwiftFiles(rootPath: basePath, suffix: swiftSuffix) {
    filePaths = s
}

let swiftFiles = filePaths.flatMap { try? SwiftFile(filePath: $0) }
let protector = Protector(files: swiftFiles)
protector.protect()

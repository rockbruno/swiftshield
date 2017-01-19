//
//  main.swift
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

let basePath = UserDefaults.standard.string(forKey: "p") ?? ""

guard basePath.isEmpty == false else {
    Logger.log("Bad arguments. Syntax: 'swiftshield -p (project root) -s (encrypted class name length) -v (verbose mode, optional)'", verbose: true)
    exit(-1)
}

let verbose = CommandLine.arguments.contains("-v")
let providedSize = UserDefaults.standard.integer(forKey: "s")
let protectedClassNameSize = providedSize > 0 ? providedSize : 15

Logger.log("Swift Protector 0.1")
Logger.log("Verbose Mode", verbose: verbose)
Logger.log("Path: \(basePath)", verbose: verbose)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: verbose)

var filePaths:[String] = []
let swiftSuffix = ".swift"
if let s = findSwiftFiles(rootPath: basePath, suffix: swiftSuffix) {
    filePaths = s
}

let swiftFiles = filePaths.flatMap { try? SwiftFile(filePath: $0) }
let protector = Protector(files: swiftFiles)
protector.protect()

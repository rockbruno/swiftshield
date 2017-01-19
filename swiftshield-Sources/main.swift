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

Logger.log("Swift Protector 0.2")
Logger.log("Verbose Mode", verbose: verbose)
Logger.log("Path: \(basePath)", verbose: verbose)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: verbose)

var swiftFilePaths = findFiles(rootPath: basePath, suffix: ".swift") ?? []
var storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])

let swiftFiles = swiftFilePaths.flatMap { try? File(filePath: $0) }
let storyboardFiles = storyboardFilePaths.flatMap{ try? File(filePath: $0) }

let protector = Protector(swiftFiles: swiftFiles, storyboardFiles: storyboardFiles)
protector.protect()

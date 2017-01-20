//
//  main.swift
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

let basePath = UserDefaults.standard.string(forKey: "p") ?? ""

guard basePath.isEmpty == false else {
    Logger.log("Bad arguments. Syntax: 'swiftshield -p (project root) -size (encrypted class name length) -v (verbose mode, optional) -ignore \"$SRCROOT/Sources/A.swift|$SRCROOT/Sources/B.swift\" (Swift file paths to ignore in case of conflicts. Optional)", verbose: true)
    exit(1)
}

let verbose = CommandLine.arguments.contains("-v")
let providedSize = UserDefaults.standard.integer(forKey: "s")
let protectedClassNameSize = providedSize > 0 ? providedSize : 15

let ignoredSwiftArgument = UserDefaults.standard.string(forKey: "ignore") ?? ""
let ignoredSwift = ignoredSwiftArgument.contains("|") ? ignoredSwiftArgument.components(separatedBy: "|") : [ignoredSwiftArgument]

Logger.log("Swift Protector 0.4")
Logger.log("Verbose Mode", verbose: verbose)
Logger.log("Path: \(basePath)", verbose: verbose)
Logger.log("Ignored files: \(ignoredSwift)", verbose: verbose)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: verbose)

let swiftFilePaths = (findFiles(rootPath: basePath, suffix: ".swift") ?? []).filter(ignoredSwift)
let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])

Logger.log("Swift files to check: \(swiftFilePaths)", verbose: true)
Logger.log("Storyboard files to check: \(storyboardFilePaths)", verbose: true)

let swiftFiles = swiftFilePaths.flatMap { try? File(filePath: $0) }
let storyboardFiles = storyboardFilePaths.flatMap{ try? File(filePath: $0) }

let protector = Protector(swiftFiles: swiftFiles, storyboardFiles: storyboardFiles)
protector.protect()

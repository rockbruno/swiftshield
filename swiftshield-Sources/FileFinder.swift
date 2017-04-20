//
//  FileFinder.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

func getStoryboardsAndXibs() -> [File] {
    return getFiles(suffix: ".storyboard") + getFiles(suffix: ".xib")
}

func getSwiftFiles() -> [File] {
    return getFiles(suffix: ".swift")
}

func getFiles(suffix: String) -> [File] {
    let filePaths = findFiles(rootPath: basePath, suffix: suffix) ?? []
    return filePaths.flatMap{ File(filePath: $0) }
}

func findFiles(rootPath: String, suffix: String, ignoreDirs: Bool = true) -> [String]? {
    var result = Array<String>()
    let fileManager = FileManager.default
        if let paths = fileManager.subpaths(atPath: rootPath) {
            let swiftPaths = paths.filter({ return $0.hasSuffix(suffix)})
            for path in swiftPaths {
                var isDir : ObjCBool = false
                let fullPath = (rootPath as NSString).appendingPathComponent(path)
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if ignoreDirs == false || (ignoreDirs && isDir.boolValue == false) {
                        result.append(fullPath)
                    }
                }
            }
        }
    return result.count > 0 ? result : nil
}

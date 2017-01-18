//
//  SwiftFinder.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

func findSwiftFiles(rootPath: String, suffix: String) -> [String]? {
    var result = Array<String>()
    let fileManager = FileManager.default
    if let paths = fileManager.subpaths(atPath: rootPath) {
        let swiftPaths = paths.filter({ return $0.hasSuffix(suffix)})
        for path in swiftPaths {
            result.append((rootPath as NSString).appendingPathComponent(path))
        }
    }
    return result.count > 0 ? result : nil
}

//
//  File.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class File {
    let data: Data
    let path: String
    var name: String {
        return (path as NSString).lastPathComponent
    }
    
    init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        self.data = try Data(contentsOf: url)
        self.path = filePath
    }
}

//
//  SwiftFile.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class SwiftFile {
    
    let data: Data
    let path: String
    var name: String {
        return (path as NSString).lastPathComponent
    }
   // let storyboardName: String
   // let storyboard: Storyboard
    
    init(filePath: String) throws {
        let url = URL(fileURLWithPath: filePath)
        self.data = try Data(contentsOf: url)
        self.path = filePath
        //self.storyboardName = ((filePath as NSString).lastPathComponent as NSString).deletingPathExtension
        //self.storyboard = Storyboard(xml:SWXMLHash.parse(self.data))
    }
}

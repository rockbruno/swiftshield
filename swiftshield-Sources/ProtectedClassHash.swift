//
//  ProtectedClassHash.swift
//  swiftshield
//
//  Created by Bruno Rocha on 1/19/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

class ProtectedClassHash {
    let hash: [String:String]
    var isEmpty: Bool {
        return hash.isEmpty
    }
    
    init(hash: [String:String]) {
        self.hash = hash
    }
}

//
//  NSArray+UnboxPathNode.swift
//  Unbox
//
//  Created by John Sundell on 2017-03-27.
//  Copyright © 2017 John Sundell. All rights reserved.
//

import Foundation

#if !os(Linux)
extension NSArray: UnboxPathNode {
    func unboxPathValue(forKey key: String) -> Any? {
        return (self as Array).unboxPathValue(forKey: key)
    }
}
#endif

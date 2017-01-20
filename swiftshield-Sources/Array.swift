//
//  Array.swift
//  swiftshield
//
//  Created by Bruno Rocha on 1/19/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
    
    func filter(_ array: [Element]) -> [Element] {
        var filtered = self
        for filter in array {
            guard let indexOf = filtered.index(of: filter) else {
                continue
            }
            filtered.remove(at: indexOf)
        }
        return filtered
    }
}

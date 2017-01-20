//
//  VerboseLog.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

class Logger {
    static func log(_ text: String, verbose v: Bool = false) {
        if (v && verbose) || !v {
            print(text)
        }
    }
}

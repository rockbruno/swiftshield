//
//  Exit.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/13/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa
import Foundation

func exit(error: Bool = false) {
    //Sleep some time to prevent the terminal from eating the last log, if it exists.
    sleep(1)
    exit(error ? -1 : 0)
}

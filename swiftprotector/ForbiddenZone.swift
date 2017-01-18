//
//  ForbiddenCharacters.swift
//  swiftprotector
//
//  Created by Bruno Rocha on 1/18/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

enum ForbiddenZone: String {
    case doubleQuote = "\""
    case quote = "\'"
    case regularComment = "//"
    case blockComment = "/*"
    
    var zoneEnd: String {
        switch self {
        case .doubleQuote:
            return "\""
        case .quote:
            return "\'"
        case .regularComment:
            return "\n"
        case .blockComment:
            return "*/"
        }
    }
}

/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal enum UnboxPath {
    case key(String)
    case keyPath(String)
}

extension UnboxPath: CustomStringConvertible {
    var description: String {
        switch self {
        case .key(let key):
            return key
        case .keyPath(let keyPath):
            return keyPath
        }
    }
}

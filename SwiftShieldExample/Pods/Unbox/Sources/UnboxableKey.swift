/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to enable any type to be transformed from a JSON key into a dictionary key
public protocol UnboxableKey {
    /// Transform an unboxed key into a key that will be used in an unboxed dictionary
    static func transform(unboxedKey: String) -> Self?
}

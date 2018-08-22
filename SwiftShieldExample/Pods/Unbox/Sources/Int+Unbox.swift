/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Int` an Unboxable raw type
extension Int: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Int? {
        return unboxedNumber.intValue
    }

    public static func transform(unboxedString: String) -> Int? {
        return Int(unboxedString)
    }
}

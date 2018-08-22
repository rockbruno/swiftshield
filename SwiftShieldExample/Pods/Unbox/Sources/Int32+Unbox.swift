/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Int32` an Unboxable raw type
extension Int32: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Int32? {
        return unboxedNumber.int32Value
    }

    public static func transform(unboxedString: String) -> Int32? {
        return Int32(unboxedString)
    }
}

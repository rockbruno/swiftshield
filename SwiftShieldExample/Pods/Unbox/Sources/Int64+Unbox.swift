/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Int64` an Unboxable raw type
extension Int64: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Int64? {
        return unboxedNumber.int64Value
    }

    public static func transform(unboxedString: String) -> Int64? {
        return Int64(unboxedString)
    }
}

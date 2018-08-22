/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `UInt64` an Unboxable raw type
extension UInt64: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> UInt64? {
        return unboxedNumber.uint64Value
    }

    public static func transform(unboxedString: String) -> UInt64? {
        return UInt64(unboxedString)
    }
}

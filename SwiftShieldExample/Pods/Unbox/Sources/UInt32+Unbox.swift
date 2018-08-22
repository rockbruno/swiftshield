/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `UInt32` an Unboxable raw type
extension UInt32: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> UInt32? {
        return unboxedNumber.uint32Value
    }

    public static func transform(unboxedString: String) -> UInt32? {
        return UInt32(unboxedString)
    }
}

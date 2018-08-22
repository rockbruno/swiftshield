/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making UInt an Unboxable raw type
extension UInt: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> UInt? {
        return unboxedNumber.uintValue
    }

    public static func transform(unboxedString: String) -> UInt? {
        return UInt(unboxedString)
    }
}

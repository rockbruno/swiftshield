/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Double` an Unboxable raw type
extension Double: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Double? {
        return unboxedNumber.doubleValue
    }

    public static func transform(unboxedString: String) -> Double? {
        return Double(unboxedString)
    }
}

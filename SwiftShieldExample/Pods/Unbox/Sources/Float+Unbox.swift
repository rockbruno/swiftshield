/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Float` an Unboxable raw type
extension Float: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Float? {
        return unboxedNumber.floatValue
    }

    public static func transform(unboxedString: String) -> Float? {
        return Float(unboxedString)
    }
}

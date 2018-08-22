/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `String` an Unboxable raw type
extension String: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> String? {
        return unboxedNumber.stringValue
    }

    public static func transform(unboxedString: String) -> String? {
        return unboxedString
    }
}

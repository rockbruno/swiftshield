/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Extension making `Decimal` an Unboxable raw type
extension Decimal: UnboxableRawType {
    public static func transform(unboxedNumber: NSNumber) -> Decimal? {
        return Decimal(string: unboxedNumber.stringValue)
    }

    public static func transform(unboxedString unboxedValue: String) -> Decimal? {
        return Decimal(string: unboxedValue)
    }
}

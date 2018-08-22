/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */


import Foundation

/// Extension making `DateFormatter` usable as an UnboxFormatter
extension DateFormatter: UnboxFormatter {
    public func format(unboxedValue: String) -> Date? {
        return self.date(from: unboxedValue)
    }
}

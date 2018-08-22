/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to enable a raw type (such as `Int` or `String`) for Unboxing
public protocol UnboxableRawType: UnboxCompatible {
    /// Transform an instance of this type from an unboxed number
    static func transform(unboxedNumber: NSNumber) -> Self?
    /// Transform an instance of this type from an unboxed string
    static func transform(unboxedString: String) -> Self?
}

// Default implementation of `UnboxCompatible` for raw types
public extension UnboxableRawType {
    static func unbox(value: Any, allowInvalidCollectionElements: Bool) throws -> Self? {
        if let matchedValue = value as? Self {
            return matchedValue
        }

        if let string = value as? String {
            return self.transform(unboxedString: string)
        }

        if let number = value as? NSNumber {
            return self.transform(unboxedNumber: number)
        }

        return nil
    }
}

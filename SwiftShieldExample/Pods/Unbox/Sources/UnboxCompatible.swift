/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol that types that can be used in an unboxing process must conform to. You don't conform to this protocol yourself.
public protocol UnboxCompatible {
    /// Unbox a value, or either throw or return nil if unboxing couldn't be performed
    static func unbox(value: Any, allowInvalidCollectionElements: Bool) throws -> Self?
}

// MARK: - Internal extensions

internal extension UnboxCompatible {
    static func unbox(value: Any) throws -> Self? {
        return try self.unbox(value: value, allowInvalidCollectionElements: false)
    }
}

internal extension UnboxCompatible where Self: Collection {
    static func makeTransform(allowInvalidElements: Bool) -> UnboxTransform<Self> {
        return {
            try self.unbox(value: $0, allowInvalidCollectionElements: allowInvalidElements)
        }
    }
}

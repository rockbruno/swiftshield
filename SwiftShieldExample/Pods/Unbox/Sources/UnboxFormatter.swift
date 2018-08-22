/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used by objects that may format raw values into some other value
public protocol UnboxFormatter {
    /// The type of raw value that this formatter accepts as input
    associatedtype UnboxRawValue: UnboxableRawType
    /// The type of value that this formatter produces as output
    associatedtype UnboxFormattedType

    /// Format an unboxed value into another value (or nil if the formatting failed)
    func format(unboxedValue: UnboxRawValue) -> UnboxFormattedType?
}

// MARK: - Internal extensions

internal extension UnboxFormatter {
    func makeTransform() -> UnboxTransform<UnboxFormattedType> {
        return { ($0 as? UnboxRawValue).map(self.format) }
    }

    func makeCollectionTransform<C: UnboxableCollection>(allowInvalidElements: Bool) -> UnboxTransform<C> where C.UnboxValue == UnboxFormattedType {
        return {
            let transformer = UnboxFormatterCollectionElementTransformer(formatter: self)
            return try C.unbox(value: $0, allowInvalidElements: allowInvalidElements, transformer: transformer)
        }
    }
}

// MARK: - Utilities

private class UnboxFormatterCollectionElementTransformer<T: UnboxFormatter>: UnboxCollectionElementTransformer {
    private let formatter: T

    init(formatter: T) {
        self.formatter = formatter
    }

    func unbox(element: T.UnboxRawValue, allowInvalidCollectionElements: Bool) throws -> T.UnboxFormattedType? {
        return self.formatter.format(unboxedValue: element)
    }
}

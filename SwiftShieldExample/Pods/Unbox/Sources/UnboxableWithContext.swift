/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to declare a model as being Unboxable with a certain context, for use with the unbox(context:) function
public protocol UnboxableWithContext {
    /// The type of the contextual object that this model requires when unboxed
    associatedtype UnboxContext

    /// Initialize an instance of this model by unboxing a dictionary & using a context
    init(unboxer: Unboxer, context: UnboxContext) throws
}

// MARK: - Internal extensions

internal extension UnboxableWithContext {
    static func makeTransform(context: UnboxContext) -> UnboxTransform<Self> {
        return {
            try ($0 as? UnboxableDictionary).map {
                try unbox(dictionary: $0, context: context)
            }
        }
    }

    static func makeCollectionTransform<C: UnboxableCollection>(context: UnboxContext, allowInvalidElements: Bool) -> UnboxTransform<C> where C.UnboxValue == Self {
        return {
            let transformer = UnboxableWithContextCollectionElementTransformer<Self>(context: context)
            return try C.unbox(value: $0, allowInvalidElements: allowInvalidElements, transformer: transformer)
        }
    }
}

// MARK: - Utilities

private class UnboxableWithContextCollectionElementTransformer<T: UnboxableWithContext>: UnboxCollectionElementTransformer {
    private let context: T.UnboxContext

    init(context: T.UnboxContext) {
        self.context = context
    }

    func unbox(element: UnboxableDictionary, allowInvalidCollectionElements: Bool) throws -> T? {
        let unboxer = Unboxer(dictionary: element)
        return try T(unboxer: unboxer, context: self.context)
    }
}

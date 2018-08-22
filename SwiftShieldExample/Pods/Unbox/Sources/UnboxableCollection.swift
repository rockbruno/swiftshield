/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

// MARK: - Protocol

/// Protocol used to enable collections to be unboxed. Default implementations exist for Array & Dictionary
public protocol UnboxableCollection: Collection, UnboxCompatible {
    /// The value type that this collection contains
    associatedtype UnboxValue

    /// Unbox a value into a collection, optionally allowing invalid elements
    static func unbox<T: UnboxCollectionElementTransformer>(value: Any, allowInvalidElements: Bool, transformer: T) throws -> Self? where T.UnboxedElement == UnboxValue
}

// MARK: - Default implementations

// Default implementation of `UnboxCompatible` for collections
public extension UnboxableCollection {
    public static func unbox(value: Any, allowInvalidCollectionElements: Bool) throws -> Self? {
        if let matchingCollection = value as? Self {
            return matchingCollection
        }

        if let unboxableType = UnboxValue.self as? Unboxable.Type {
            let transformer = UnboxCollectionElementClosureTransformer<UnboxableDictionary, UnboxValue>() { element in
                let unboxer = Unboxer(dictionary: element)
                return try unboxableType.init(unboxer: unboxer) as? UnboxValue
            }

            return try self.unbox(value: value, allowInvalidElements: allowInvalidCollectionElements, transformer: transformer)
        }

        if let unboxCompatibleType = UnboxValue.self as? UnboxCompatible.Type {
            let transformer = UnboxCollectionElementClosureTransformer<Any, UnboxValue>() { element in
                return try unboxCompatibleType.unbox(value: element, allowInvalidCollectionElements: allowInvalidCollectionElements) as? UnboxValue
            }

            return try self.unbox(value: value, allowInvalidElements: allowInvalidCollectionElements, transformer: transformer)
        }

        throw UnboxPathError.invalidCollectionElementType(UnboxValue.self)
    }
}

// MARK: - Utility types

private class UnboxCollectionElementClosureTransformer<I, O>: UnboxCollectionElementTransformer {
    private let closure: (I) throws -> O?

    init(closure: @escaping (I) throws -> O?) {
        self.closure = closure
    }

    func unbox(element: I, allowInvalidCollectionElements: Bool) throws -> O? {
        return try self.closure(element)
    }
}

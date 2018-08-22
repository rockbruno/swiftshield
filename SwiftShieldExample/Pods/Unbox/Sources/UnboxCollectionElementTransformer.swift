/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to unbox an element in a collection. Unbox provides default implementations of this protocol.
public protocol UnboxCollectionElementTransformer {
    /// The raw element type that this transformer expects as input
    associatedtype UnboxRawElement
    /// The unboxed element type that this transformer outputs
    associatedtype UnboxedElement

    /// Unbox an element from a collection, optionally allowing invalid elements for nested collections
    func unbox(element: UnboxRawElement, allowInvalidCollectionElements: Bool) throws -> UnboxedElement?
}

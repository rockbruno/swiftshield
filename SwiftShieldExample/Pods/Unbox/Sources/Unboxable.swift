/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to declare a model as being Unboxable, for use with the unbox() function
public protocol Unboxable {
    /// Initialize an instance of this model by unboxing a dictionary using an Unboxer
    init(unboxer: Unboxer) throws
}

internal extension Unboxable {
    static func makeTransform() -> UnboxTransform<Self> {
        return { try ($0 as? UnboxableDictionary).map(unbox) }
    }
}

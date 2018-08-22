/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal extension Data {
    func unbox<T: Unboxable>() throws -> T {
        return try Unboxer(data: self).performUnboxing()
    }

    func unbox<T: UnboxableWithContext>(context: T.UnboxContext) throws -> T {
        return try Unboxer(data: self).performUnboxing(context: context)
    }

    func unbox<T>(closure: (Unboxer) throws -> T?) throws -> T {
        return try closure(Unboxer(data: self)).orThrow(UnboxError.customUnboxingFailed)
    }

    func unbox<T: Unboxable>(allowInvalidElements: Bool) throws -> [T] {
        let array: [UnboxableDictionary] = try JSONSerialization.unbox(data: self, options: [.allowFragments])
        return try array.map(allowInvalidElements: allowInvalidElements) { dictionary in
            return try Unboxer(dictionary: dictionary).performUnboxing()
        }
    }

    func unbox<T: UnboxableWithContext>(context: T.UnboxContext, allowInvalidElements: Bool) throws -> [T] {
        let array: [UnboxableDictionary] = try JSONSerialization.unbox(data: self, options: [.allowFragments])

        return try array.map(allowInvalidElements: allowInvalidElements) { dictionary in
            return try Unboxer(dictionary: dictionary).performUnboxing(context: context)
        }
    }
}

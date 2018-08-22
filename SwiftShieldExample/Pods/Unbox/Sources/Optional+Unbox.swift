/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal extension Optional {
    func map<T>(_ transform: (Wrapped) throws -> T?) rethrows -> T? {
        guard let value = self else {
            return nil
        }

        return try transform(value)
    }

    func orThrow<E: Error>(_ errorClosure: @autoclosure () -> E) throws -> Wrapped {
        guard let value = self else {
            throw errorClosure()
        }

        return value
    }
}

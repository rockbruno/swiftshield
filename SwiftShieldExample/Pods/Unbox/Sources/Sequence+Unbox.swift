/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal extension Sequence {
    func map<T>(allowInvalidElements: Bool, transform: (Iterator.Element) throws -> T) throws -> [T] {
        if !allowInvalidElements {
            return try self.map(transform)
        }

        return compactMap {
            return try? transform($0)
        }
    }
}

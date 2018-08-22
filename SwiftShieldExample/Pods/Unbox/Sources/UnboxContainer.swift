/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal struct UnboxContainer<T: Unboxable>: UnboxableWithContext {
    let model: T

    init(unboxer: Unboxer, context: UnboxPath) throws {
        switch context {
        case .key(let key):
            self.model = try unboxer.unbox(key: key)
        case .keyPath(let keyPath):
            self.model = try unboxer.unbox(keyPath: keyPath)
        }
    }
}

/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal struct UnboxArrayContainer<T: Unboxable>: UnboxableWithContext {
    let models: [T]

    init(unboxer: Unboxer, context: (path: UnboxPath, allowInvalidElements: Bool)) throws {
        switch context.path {
        case .key(let key):
            self.models = try unboxer.unbox(key: key, allowInvalidElements: context.allowInvalidElements)
        case .keyPath(let keyPath):
            self.models = try unboxer.unbox(keyPath: keyPath, allowInvalidElements: context.allowInvalidElements)
        }
    }
}

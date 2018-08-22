/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal extension JSONSerialization {
    static func unbox<T>(data: Data, options: ReadingOptions = []) throws -> T {
        do {
            return try (self.jsonObject(with: data, options: options) as? T).orThrow(UnboxError.invalidData)
        } catch {
            throw UnboxError.invalidData
        }
    }
}


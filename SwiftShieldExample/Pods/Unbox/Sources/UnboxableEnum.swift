/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Protocol used to enable an enum to be directly unboxable
public protocol UnboxableEnum: RawRepresentable, UnboxCompatible {}

/// Default implementation of `UnboxCompatible` for enums
public extension UnboxableEnum {
    static func unbox(value: Any, allowInvalidCollectionElements: Bool) throws -> Self? {
        return (value as? RawValue).map(self.init)
    }
}

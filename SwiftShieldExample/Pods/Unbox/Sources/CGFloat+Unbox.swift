/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

#if !os(Linux)
import CoreGraphics

/// Extension making `CGFloat` an Unboxable raw type
extension CGFloat: UnboxableByTransform {
    public typealias UnboxRawValue = Double

    public static func transform(unboxedValue: Double) -> CGFloat? {
        return CGFloat(unboxedValue)
    }
}
#endif

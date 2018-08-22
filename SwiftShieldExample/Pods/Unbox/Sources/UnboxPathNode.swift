/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

internal protocol UnboxPathNode {
    func unboxPathValue(forKey key: String) -> Any?
}

/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

#if !os(Linux)
extension NSDictionary: UnboxPathNode {
    func unboxPathValue(forKey key: String) -> Any? {
        return self[key]
    }
}
#endif

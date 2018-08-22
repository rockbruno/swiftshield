/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Type alias defining what type of Dictionary that is Unboxable (valid JSON)
public typealias UnboxableDictionary = [String : Any]

internal typealias UnboxTransform<T> = (Any) throws -> T?

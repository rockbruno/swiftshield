/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Error type that Unbox throws in case an unrecoverable error was encountered
public enum UnboxError: Error {
    /// Invalid data was provided when calling unbox(data:...)
    case invalidData
    /// Custom unboxing failed, either by throwing or returning `nil`
    case customUnboxingFailed
    /// An error occurred while unboxing a value for a path (contains the underlying path error, and the path)
    case pathError(UnboxPathError, String)
}

/// Extension making `UnboxError` conform to `CustomStringConvertible`
extension UnboxError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidData:
            return "[UnboxError] Invalid data."
        case .customUnboxingFailed:
            return "[UnboxError] Custom unboxing failed."
        case .pathError(let error, let path):
            return "[UnboxError] An error occurred while unboxing path \"\(path)\": \(error)"
        }
    }
}

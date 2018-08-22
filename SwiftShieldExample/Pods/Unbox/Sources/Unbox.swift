/**
 *  Unbox
 *  Copyright (c) 2015-2017 John Sundell
 *  Licensed under the MIT license, see LICENSE file
 */

import Foundation

/// Unbox a JSON dictionary into a model `T`. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary) throws -> T {
    return try Unboxer(dictionary: dictionary).performUnboxing()
}

/// Unbox a JSON dictionary into a model `T` beginning at a certain key. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary, atKey key: String) throws -> T {
    let container: UnboxContainer<T> = try unbox(dictionary: dictionary, context: .key(key))
    return container.model
}

/// Unbox a JSON dictionary into a model `T` beginning at a certain key path. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary, atKeyPath keyPath: String) throws -> T {
    let container: UnboxContainer<T> = try unbox(dictionary: dictionary, context: .keyPath(keyPath))
    return container.model
}

/// Unbox an array of JSON dictionaries into an array of `T`, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionaries: [UnboxableDictionary], allowInvalidElements: Bool = false) throws -> [T] {
    return try dictionaries.map(allowInvalidElements: allowInvalidElements, transform: unbox)
}

/// Unbox an array JSON dictionary into an array of model `T` beginning at a certain key, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary, atKey key: String, allowInvalidElements: Bool = false) throws -> [T] {
    let container: UnboxArrayContainer<T> = try unbox(dictionary: dictionary, context: (.key(key), allowInvalidElements))
    return container.models
}

/// Unbox an array JSON dictionary into an array of model `T` beginning at a certain key path, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary, atKeyPath keyPath: String, allowInvalidElements: Bool = false) throws -> [T] {
    let container: UnboxArrayContainer<T> = try unbox(dictionary: dictionary, context: (.keyPath(keyPath), allowInvalidElements))
    return container.models
}

/// Unbox binary data into a model `T`. Throws `UnboxError`.
public func unbox<T: Unboxable>(data: Data) throws -> T {
    return try data.unbox()
}

/// Unbox binary data into an array of `T`, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: Unboxable>(data: Data, atKeyPath keyPath: String? = nil, allowInvalidElements: Bool = false) throws -> [T] {
    if let keyPath = keyPath {
        return try unbox(dictionary: JSONSerialization.unbox(data: data), atKeyPath: keyPath, allowInvalidElements: allowInvalidElements)
    }
    
    return try data.unbox(allowInvalidElements: allowInvalidElements)
}

/// Unbox a JSON dictionary into a model `T` using a required contextual object. Throws `UnboxError`.
public func unbox<T: UnboxableWithContext>(dictionary: UnboxableDictionary, context: T.UnboxContext) throws -> T {
    return try Unboxer(dictionary: dictionary).performUnboxing(context: context)
}

/// Unbox an array of JSON dictionaries into an array of `T` using a required contextual object, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: UnboxableWithContext>(dictionaries: [UnboxableDictionary], context: T.UnboxContext, allowInvalidElements: Bool = false) throws -> [T] {
    return try dictionaries.map(allowInvalidElements: allowInvalidElements, transform: {
        try unbox(dictionary: $0, context: context)
    })
}

/// Unbox binary data into a model `T` using a required contextual object. Throws `UnboxError`.
public func unbox<T: UnboxableWithContext>(data: Data, context: T.UnboxContext) throws -> T {
    return try data.unbox(context: context)
}

/// Unbox binary data into an array of `T` using a required contextual object, optionally allowing invalid elements. Throws `UnboxError`.
public func unbox<T: UnboxableWithContext>(data: Data, context: T.UnboxContext, allowInvalidElements: Bool = false) throws -> [T] {
    return try data.unbox(context: context, allowInvalidElements: allowInvalidElements)
}

/// Unbox binary data into a dictionary of type `[String: T]`. Throws `UnboxError`.
public func unbox<T: Unboxable>(data: Data) throws -> [String: T] {
    let dictionary : [String: [String: Any]] = try JSONSerialization.unbox(data: data)
    return try unbox(dictionary: dictionary)
}

/// Unbox `UnboxableDictionary` into a dictionary of type `[String: T]` where `T` is `Unboxable`. Throws `UnboxError`.
public func unbox<T: Unboxable>(dictionary: UnboxableDictionary) throws -> [String: T] {
    var mappedDictionary = [String: T]()
    try dictionary.forEach { key, value in
        guard let innerDictionary = value as? UnboxableDictionary else {
            throw UnboxError.invalidData
        }
        let data : T = try unbox(dictionary: innerDictionary)
        mappedDictionary[key] = data
    }
    return mappedDictionary
}

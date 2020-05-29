# What SwiftShield can obfuscate

- Classes
- Structs
- Methods
- Properties (see below for exceptions)
- Enums (see below for exceptions)
- Enum cases

# What SwiftShield can't obfuscate

- `typealias` and `associatedtypes`: SourceKit doesn't always index them, so we avoid them to prevent broken projects. Note that these can't be reverse engineered as they are purely an editor thing, so avoiding them isn't a problem!
- Local content inside methods (like argument names and inner properties). They aren't indexed, but they also can't be reverse engineered.
- Properties from types that inherit from `Codable`, `Encodable` or `Decodable`, as obfuscating them would break your project.
- Properties belonging to `@objc` classes. This is because SourceKit cannot inspect non-Swift content, and we need it to determine if a property's parent inherits from `Codable`.
- Enums that inherit from `CodingKey`, as obfuscating them would break your project.
- Module names: Not implemented yet.

# SourceKit Bugs

These are problems that SourceKit has that are unrelated to a specific feature, which means that we can't disable them to save you. If your project is affected by any of these problems, you will need to manually fix your project after obfuscating as it will not compile. This is not a complete list -- if you discover a problem that is not here, please open an issue.

**Note: You can use the `--ignore-targets` argument to completely disable the obfuscation of specific targets.**

- [(SR-9020)](https://bugs.swift.org/browse/SR-9020) Legacy KeyPaths that include types (like `#keyPath(Foo.bar)`) will not get indexed.
- **Fixed in Swift 5.3**: `@objc optional` protocol methods don't have their references indexed.
- **Fixed in Swift 5.3**: The postfix of an `is` parameter doesn't get indexed. (`foo is MyType`)

# Additional important information

## SceneDelegate / App Extensions class references in plists should be untouched

App Extensions that use `NSExtensionPrincipalClass` or variants in their `Info.plist` (like Rich Notifications/Watch apps and the SceneDelegate in iOS 13) will have such references obfuscated as well, but will assume that you haven't changed them from their default `$(PRODUCT_MODULE_NAME).ClassName` value. If you modified these plists to point to classes in different modules, you'll have to manually update these plists after running SwiftShield.

# SourceKit Bugs When Using `--ignore-public`

The `--ignore-public` (or SDK Mode) obfuscates your app while ignoring anything with the `public` or `open` access controls. However, some SourceKit bugs prevent it from working 100% as intended.

## Public Extensions

SourceKit has a problem where it can't detect content inside public extensions as such. For example, the following snippet will correctly avoid obfuscating `myMethod()`:

```swift
extension Int {
    public func myMethod() {}
}
```

This one however, will be incorrectly obfuscated as SourceKit doesn't recognize `myMethod()` as being public (even though it is).

```swift
public extension Int {
    func myMethod() {}
}
```

If you're using `--ignore-public`, make sure your public extensions follow the pattern from the first snippet.

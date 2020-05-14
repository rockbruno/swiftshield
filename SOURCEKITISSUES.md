# What SwiftShield can obfuscate

- Classes
- Structs
- Methods
- Enums (as long as they don't have `CodingKeys` in the name)
- Enum cases

# What SwiftShield can't obfuscate

- Properties: Although we can obfuscate them, we avoid doing so because of `Codable` types. We can fix it by checking the inheritance tree of a property's outer type.
- `typealias` and `associatedtypes`: SourceKit doesn't always index them, so we avoid them to prevent broken projects. Note that these can't be reverse engineered as they are purely an editor thing, so avoiding them isn't a problem!
- Enums that have the `CodingKeys` suffix
- Module names: Not implemented yet, but possible.

# SourceKit Bugs

These are problems that SourceKit has that are unrelated to a specific feature, which means that we can't disable them to save you. If your project is affected by any of these problems, you will need to manually fix your project after obfuscating as it will not compile. This is not a complete list -- if you discover a problem that is not here, please open an issue.

**Note: You can use the `--ignore-targets` argument to completely disable the obfuscation of specific targets.**

- (SR-9020)](https://bugs.swift.org/browse/SR-9020) Legacy KeyPaths that include types (like `#keyPath(Foo.bar)`) will not get indexed.
- Any file that has an emoji will break the obfuscation process. This may not be a SourceKit bug itself, but something that we have to treat on our side.
- `@objc optional` protocol methods don't have their references indexed.

# Additional important information

## Codable Enums need to have a specific suffix

To prevent `Codable` enums from being obfuscated, we avoid obfuscating enum cases belonging to enums that have the `CodingKeys` suffix. Make sure your enums follow this pattern.

## SceneDelegate / App Extensions class references in plists should be untouched

App Extensions that use `NSExtensionPrincipalClass` or variants in their `Info.plist` (like Rich Notifications/Watch apps and the SceneDelegate in iOS 13) will have such references obfuscated as well, but will assume that you haven't changed them from their default `$(PRODUCT_MODULE_NAME).ClassName` value. If you modified these plists to point to classes in different modules, you'll have to manually update these plists after running SwiftShield.

# SourceKit Bugs When Using `--ignore-public`

The `--ignore-public` (or SDK Mode) obfuscates your app while ignoring anything with the `public` or `open` access controls. However, some SourceKit bugs prevent it from working 100% as intended.

## Public Extensions

SourceKit has a problem where it can't detect content inside public extensions as such. For example, the following snippet will correctly avoid obfuscating `myMethod()`:

```
extension Int {
	public func myMethod() {}
}
```

This one however, will be incorrectly obfuscated as SourceKit doesn't recognize `myMethod()` as being public (even though it is).

```
public extension Int {
	func myMethod() {}
}
```

If you're using `--ignore-public`, make sure your public extensions follow the pattern from the first snippet.

## Public enums

SourceKit doesn't detect public enum cases as such.

```
public enum Foo {
	case bar
}
```

`.bar` will be obfuscated even though the enum is public.
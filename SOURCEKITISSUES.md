# Current known SourceKit issues that prevent SwiftShield from obfuscating *everything*

# SourceKit Bugs

Bugs that are marked as merged are fixed in the Swift repo, but still bugged in the current Xcode version. They are fixed in SwiftShield when the new Xcode containing these fixes come out.

- **IN-REVIEW**: [(SR-8616)](https://bugs.swift.org/browse/SR-8616) `is` pattern: Matched type won't index if the left element is an optional (`if [].first is Foo`). For now, you can overcome this by not using the optionals directly.
- **IN-REVIEW**: [(SR-9020)](https://bugs.swift.org/browse/SR-9020) Legacy KeyPaths that include types, such as `#keyPath(Foo.bar)` will not get indexed.
- Emoji Strings: Although SourceKit has no real bugs regarding emojis, it does treat them differently: While SourceKit treats emojis as several characters, Swift treats them as a single one - which will prevent SwiftShield from knowing the correct position of the references after said emoji. While a solution isn't found, you can avoid this by not using emojis.
- **IN-PROGRESS**: Expressions marked as `@available` fail to be indexed.

# Types that won't be obfuscated

The following types and cases might be working correctly in SourceKit, but are currently disabled for other reasons.

- Typealiases and Associated Types: Not always indexed (`typealias Foo = UIImage | extension Foo {}` - Foo is ignored and indexed as UIImage). Note that these can't be reverse-engineered as they are purely an editor thing, so no action is required!
- Enum cases and names: Although they are correctly indexed, some enums like `CodingKeys` are not meant to be changed. This will be activated again once the way to determine if an enum is related to internal frameworks is implemented.
- Properties: Properties are on hold for a while because they break derived `Codable` types. Although the obfuscation works correctly, if you build `Codable` types to work on top of a backend's json, parsing will fail because of the different property name.
- Module names: Not implemented yet!

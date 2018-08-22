# Current known SourceKit issues that prevent SwiftShield from obfuscating *everything*

The following types are currently disabled in SwiftShield due to SourceKit bugs.

- Typealiases: Not always indexed (`typealias Foo = UIImage | extension Foo {}` - Foo is ignored and indexed as UIImage)
- Enum names: Explicitly using an enum type in pattern matching prevents it from getting indexed (`case MyEnum.myCase` - MyEnum isn't indexed)
- Enum cases: Although they are correctly indexed, some enums like `CodingKeys` are not meant to be changed.
- Operator overloading: Operators only get indexed as such if they are declared in a global scope. Since most people use `public static func`, they get indexed as regular methods. To prevent operators from being obfuscated, methods with names shorter than four characters don't get obfuscated.
- `is` pattern: Matched type won't index if the left element is an optional (`if [].first is Foo`). For now, you can overcome this by not using the optionals directly.

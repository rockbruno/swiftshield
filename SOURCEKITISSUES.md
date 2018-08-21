# Current known SourceKit issues that prevent SwiftShield from obfuscating *everything*

- Typealiases: Not always indexed (`typealias Foo = UIImage | extension Foo {}` - Foo is indexed as UIImage)
- Enum names: Explicit types don't get indexed (`case MyEnum.myCase` - MyEnum isn't indexed)
- Enum cases: Although they are correctly indexed, `CodingKeys` are not meant to be changed.
- Operator overloading: Operators only get indexed if they are declared in a global scope. Since most people use `public static func`, methods with names shorter than four characters don't get obfuscated.
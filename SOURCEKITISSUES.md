# Current known SourceKit issues that prevent SwiftShield from obfuscating *everything*

- Typealiases: Not always indexed (`typealias Foo = UIImage | extension Foo {}` - Foo is indexed as UIImage)
- Enum names (cases are fine): Explicit types don't get indexed (`case MyEnum.myCase` - MyEnum isn't indexed)
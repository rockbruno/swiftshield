# Current SourceKit issues that prevent SwiftShield from working automatically

- Main Module doesn't get indexed for some reason
- Issues with constrained protocols (`extension Foo where RawValue: Bar`)
- Issues with explicit generics (`[MyClass]` is fine, `Swift.Array<MyClass>` isn't)
- Typealiases issues
- Rare cases where references don't get indexed
<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >
# Swift Obfuscator

[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/rockbruno/swiftshield/master/LICENSE)

SwiftShield is a tool that uses SourceKit to generate irreversible, encrypted names for your Swift project's classes, structs and protocols (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS apps, like class-dump and Cycript.
For example, after running SwiftShield, the following class:
```swift
class EncryptedVideoPlayer: DecryptionProtocol {
  func start() {
    let vc = ImportantDecryptingController()
    vc.start()
  }
}
```
becomes:
```swift
class djjck3KDxjs04tgbvb: djdj3ocnC38nid {
  func start() {
    let vc = aAAAa2nc0dfmDssf()
    vc.start()
  }
}
```


## How do I deal with crash logs / Analytics if my project uses SwiftShield?

After succesfully encrypting your project, SwiftShield generates a `conversionMap.txt` file with all the changes it made to your project, allowing you to pinpoint what an encrypted object really is.
````
//
//  SwiftShield
//  Conversion Map
//

Data:

ViewController ===> YytSIcFnBAqTAyR
AppDelegate ===> uJXJkhVbwdQGNhh
SuperImportantClassThatShouldBeHidden ===> GDqKGsHjJsWQzdq
````


## Requirements

1. Xcode command-line tools
2. No logic based on class names, like loading `MyClass.xib` because `String(describing: type(of:self))` is `'MyClass'`.
**3. Temporary:** No constrained extensions like `extension MyEnum where RawValue: MyProtocol` or verbose generic calls like `Array<MyClass>`. This is because SourceKit currently does not detect these cases. If your app contains these calls, you will have to obfuscate them manually after SwiftShield runs.
2. Swift 3.0 (untested on other versions, but could work)
3. Xcode 8.1 (untested on other versions, but could work)
4. No Objective-C classes that call Swift methods (untested, but could work. Swift classes that call Objective-C methods are fine)


## Installation

**Warning:** SwiftShield **irreversibly overwrites** all of your .swift files. Ideally, you should have it run only on your CI server, and on release builds.

Download the [latest release](https://github.com/rockbruno/swiftshield/releases) from this repository and [click here](https://github.com/rockbruno/swiftshield/blob/master/USAGE.md) to see how to setup SwiftShield.


## Next steps

1. Fix SourceKit's exceptions
2. Module names
3. Method names


## License

SwiftShield is released under the MIT license. See LICENSE for details.

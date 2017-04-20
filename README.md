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

While Automatic mode is restricted to classes, structs and protocols, you can use SwiftShield's manual mode to obfuscate virtually anything via tags: (in this case, `"Shielded"`)

```swift
class ShieldedSubscription: ShieldedAuthenticator {
  var shieldedIsSubscribed: Bool {
    let shieldedSubscription = shieldedGetSubscription()
    return shieldedSubscription.shieldedIsExpired() == false
  }
}
```
creating:
```swift
class fj39jdnconxos: mxov9h3hfVjb {
  var fvhvcx9nvn4b: Bool {
    let dj09d9cjx89cx = vxcvocxnmoicxvnv903()
    return dj09d9cjx89cx.kdbxiudn38bg8v() == false
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
3. Xcode 8.1+ (untested on other versions, but could work)
Automatic mode:
1. Swift 3.0 (untested on other versions, but could work)
2. No Objective-C classes that call Swift methods (untested, but could work. Swift classes that call Objective-C methods are fine)
Manual mode:
1. Make sure your tags aren't used on things that are not supposed to be obfuscated, like a hardcoded string.


## Installation

**Warning:** SwiftShield **irreversibly overwrites** all of your .swift files. Ideally, you should have it run only on your CI server, and on release builds.

Download the [latest release](https://github.com/rockbruno/swiftshield/releases) from this repository and [click here](https://github.com/rockbruno/swiftshield/blob/sourcekit/USAGE.md) to see how to setup SwiftShield.


## Next steps

1. Fix SourceKit's exceptions
2. Module names
3. Method names


## License

SwiftShield is released under the MIT license. See LICENSE for details.


## Thanks

Thanks to John Holdsworth from [Refactorator](https://github.com/johnno1962/Refactorator) for `SourceKit.swift`.

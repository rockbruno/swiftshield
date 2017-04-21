<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >

# Swift/OBJ-C Obfuscator

[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/rockbruno/swiftshield/master/LICENSE)

SwiftShield is a tool that generates irreversible, encrypted names for your iOS project's objects (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS apps, like class-dump and Cycript.


## Manual mode (Swift/OBJ-C)

Manual mode will obfuscate properties and classes based on a case-insensitive tag of your choice (`_SHIELDED` by default). For example, after running SwiftShield in manual mode, the following snippet:
```swift
class EncryptedVideoPlayer_SHIELDED: DecryptionProtocol_SHIELDED {
  func start_SHIELDED() {
    let vc_SHIELDED = ImportantDecryptingController_SHIELDED(secureMode_SHIELDED: true)
    vc_SHIELDED.start_SHIELDED(playAutomatically_SHIELDED: true)
  }
}
```
becomes:
```swift
class fjiovh4894bvic: XbuinvcxoDHFh3fjid {
  func cxncjnx8fh83FDJSDd() {
    let DjivneVjxrbv42jsr = vPAOSNdcbif372hFKF(vnjdDNsbufhdks3hdDs: true)
    DjivneVjxrbv42jsr.cxncjnx8fh83FDJSDd(dncjCNCNCKSDhssuhw21w: true)
  }
}
```


## Automatic mode (Swift only, BETA)

With the `-auto` tag, SwiftShield can also use SourceKit to automatically obfuscate entire projects (including dependencies) without the need of putting tags on objects. Unfortunately, due to [a few SourceKit bugs](https://github.com/rockbruno/swiftshield/blob/sourcekit/SOURCEKITISSUES.md), it is still very unreliable. Use with caution and don't expect much.


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

1. No logic based on class/property names, like loading `MyClass.xib` because `String(describing: type(of:self))` is `'MyClass'`.
2. Xcode 8.1+ (untested on other versions, but could work)

Automatic mode:

1. Xcode command-line tools
2. Swift 3.0 (untested on other versions, but could work)
3. No Objective-C classes that call Swift methods (untested, but could work. Swift classes that call Objective-C methods are fine)

Manual mode:

1. Make sure your tags aren't used on things that are not supposed to be obfuscated, like hardcoded strings.


## Installation

**Warning:** SwiftShield **irreversibly overwrites** all your source files. Ideally, you should have it run only on your CI server, and on release builds.

Download the [latest release](https://github.com/rockbruno/swiftshield/releases) from this repository and [click here to see how to setup SwiftShield.](https://github.com/rockbruno/swiftshield/blob/sourcekit/USAGE.md)


## Next steps

1. Fix SourceKit's exceptions
2. Module names
3. Method names (For automatic mode)


## License

SwiftShield is released under the MIT license. See LICENSE for details.


## Thanks

Thanks to John Holdsworth from [Refactorator](https://github.com/johnno1962/Refactorator) for `SourceKit.swift`.

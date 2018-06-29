<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >

# Swift/OBJ-C Obfuscator

[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/rockbruno/swiftshield/master/LICENSE)

SwiftShield is a tool that generates irreversible, encrypted names for your iOS project's objects (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS apps, like class-dump and Cycript.


## 🛡 Manual mode (Swift/OBJ-C)

Manual mode is the easiest way of running SwiftShield, but also the most time consuming. When used, SwiftShield will obfuscate properties and classes based on a tag of your choice at the end of it's name. For example, after running SwiftShield in manual mode and a tag `__s`, the following code:

```swift
class EncryptedVideoPlayer__s: DecryptionProtocol__s {
  func start__s() {
    let vc__s = ImportantDecryptingController__s(secureMode__s: true)
    vc__s.start__s(playAutomatically__s: true)
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


## 🤖 Automatic mode (Swift only, BETA)

With the `-automatic` tag, SwiftShield will use SourceKit to automatically obfuscate entire projects (including dependencies) without the need of putting tags on objects. Note that the accuracy of SwiftShield's automatic mode is directly related to the accuracy of Xcode's native refactoring tool [which unfortunately is still not perfect](https://github.com/rockbruno/swiftshield/blob/master/SOURCEKITISSUES.md), which means that some edge cases might fail to be obfuscated. Use with caution and don't expect much, but be aware that newer releases of Xcode might improve this tool's success rate.


## 💥 Dealing with encrypted crash logs / analytics

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


## 🚨 Requirements

1. No logic based on class/property names, like loading `MyClass.xib` because `String(describing: type(of:self))` is `'MyClass'`.
2. A Xcode version that has a project structure like Xcode 9.3 (which is pretty much every Xcode version for now)

Automatic mode:

1. Xcode command-line tools
2. Swift 4.1 (works on other versions, but has different results due to SourceKit)
3. No Objective-C classes that call Swift methods (Swift classes that call Objective-C methods are fine)

Manual mode:

1. Make sure your tags aren't used on things that are not supposed to be obfuscated, like hardcoded strings.


## Installation

**Warning:** SwiftShield **irreversibly overwrites** all your source files. Ideally, you should have it run only on your CI server, and on release builds.

Download the [latest release](https://github.com/rockbruno/swiftshield/releases) from this repository and [click here to see how to setup SwiftShield.](https://github.com/rockbruno/swiftshield/blob/master/USAGE.md)


## Running SwiftShield


# Manual mode

```
swiftshield -project-root /app/MyApp
```
**Required Parameters:**

`-project-root`: The root of your project. SwiftShield will use this to search for your project files, storyboards and source files.

**Optional Parameters:**

`-tag myTag`: Uses a custom tag. Default is `__s`.

`-verbose`: Prints additional information.


# Automatic mode

```
swiftshield -project-root /app/MyApp -automatic-project-file /app/MyApp/MyApp.xcworkspace -automatic-project-scheme MyApp-AppStore
```
**Required Parameters:**

`-automatic`: Enables automatic mode.

`-project-root`: The root of your project. SwiftShield will use this to search for your project files, storyboards and source files.

`-automatic-project-file`: Your app's main .xcodeproj/.xcworkspace file.

`-automatic-project-scheme myScheme`: The main scheme to build from your `-automatic-project-file`.

**Optional Parameters:**

`-verbose`: Prints additional information.

`-show-sourcekit-queries`: Prints queries sent to SourceKit. Note that they are huge and will absolutely clutter your terminal, so use this only for bug reports and feature development!


## Next steps

1. Module names
2. Method names (For automatic mode)


## License

SwiftShield is released under the MIT license. See LICENSE for details.


## Thanks

Thanks to John Holdsworth from [Refactorator](https://github.com/johnno1962/Refactorator) for `SourceKit.swift`, and for the guys at SourceKitten for helping me figure out which compile arguments to ignore for SourceKit.

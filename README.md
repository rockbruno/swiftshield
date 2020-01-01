<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >

# Swift/OBJ-C Obfuscator

[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)

SwiftShield is a tool that generates irreversible, encrypted names for your iOS project's objects (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS apps, like class-dump and Cycript.

```swift
class fjiovh4894bvic: XbuinvcxoDHFh3fjid {
  func cxncjnx8fh83FDJSDd() {
    return vPAOSNdcbif372hFKF()
  }
}
```


## 🤖 Automatic mode (Swift only)

With the `-automatic` tag, SwiftShield will use SourceKit to automatically obfuscate entire projects (including dependencies). Note that the scope of SwiftShield's automatic mode is directly related to the scope of Xcode's native refactoring tool, [which doesn't refactor everything yet](SOURCEKITISSUES.md). While the specific cases on the document won't be obfuscated, SwiftShield will obfuscate all Swift classes and methods that can be reverse-engineered. Take a look at the Example project to see SwiftShield in action!


## 🛡 Manual mode (Swift/OBJ-C)

If you feel like obfuscating absolutely everything - including typealiases and internal property names, you can also use Manual mode. This is the easiest way of running SwiftShield, but also the most time consuming. When used, SwiftShield will obfuscate properties and classes based on a tag of your choice at the end of it's name. For example, after running SwiftShield in manual mode and a tag `__s`, the following code:

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


## 💥 Deobfuscating encrypted Crash logs

After succesfully encrypting your project, SwiftShield will generate an output folder containing a `conversionMap.txt` file containing with all the changes it made to your project. allowing you to pinpoint what an encrypted object really is.

````
//
//  SwiftShield
//  Conversion Map
//  Automatic mode for MyApp 2.0 153, 2018-09-24 10.23.48
//

Data:

ViewController ===> YytSIcFnBAqTAyR
AppDelegate ===> uJXJkhVbwdQGNhh
SuperImportantClassThatShouldBeHidden ===> GDqKGsHjJsWQzdq
````

You can use this file to automatically deobfuscate any kind of text-based crash file by running:

```
swiftshield -deobfuscate CRASH_FILE -deobfuscate-map PATH_TO_CONVERSION_MAP
```

<img src="https://i.imgur.com/qMKy84P.png" alt="SwiftShield logo" height="172">

## 🚨 Requirements

### Automatic mode:

If one or more modules/extensions of your app fail to satify these conditions, you can avoid obfuscating them with the `-ignore-modules` argument.

1. No logic based on class/property names, like loading `MyClass.xib` because `String(describing: type(of:self))` is `'MyClass'`.
2. No Objective-C classes that call Swift methods (Swift classes that call Objective-C methods are fine, except when interfacing is involved)
4. Latest Swift version and Xcode command line tools (works on all versions, but might have different results due to different SourceKit versions)
5. Make sure your project doesn't contain one of [SourceKit's bugs](SOURCEKITISSUES.md). Although the bugs won't prevent the project from being obfuscated, some of them might require some manual fixing afterwards.

(App Extensions that use `NSExtensionPrincipalClass` or variants in their `Info.plist` (like Rich Notifications/Watch apps) will have such references obfuscated as well, but will assume that you haven't changed them from their default `$(PRODUCT_MODULE_NAME).ClassName` value. If you modified these plists to point to classes in different modules, you'll have to manually change them after running this tool.)

### Manual mode:

1. Make sure your tags aren't used on things that are not supposed to be obfuscated, like hardcoded strings.

## ⚙️ Installation

**Warning:** SwiftShield **irreversibly overwrites** all your source files. Ideally, you should have it run only on your CI server, and on release builds.

Download the [latest release](https://github.com/rockbruno/swiftshield/releases) from this repository and [click here to see how to setup SwiftShield.](USAGE.md)


## 🛫 Running SwiftShield

### Automatic mode

```
swiftshield -automatic -project-root /app/MyApp -automatic-project-file /app/MyApp/MyApp.xcworkspace -automatic-project-scheme MyApp-AppStore
```
**Required Parameters:**

- `-automatic`: Enables automatic mode.

- `-project-root`: The root of your project. SwiftShield will use this to search for your project files.

- `-automatic-project-file`: Your app's main .xcodeproj/.xcworkspace file.

- `-automatic-project-scheme myScheme`: The main scheme to build from your `-automatic-project-file`.

**Optional Parameters:**

- `-sdk`: Prevent public classes and methods from being obfuscated. Use this if it is building a SDK project. 

- `-ignore-modules`: Prevent certain modules from being obfuscated, separated by a comma. Use this if a certain module can't be properly obfuscated. Note that this should be the exact name of the imported module (not the target name!). Example: `MyLib,MyAppRichNotifications,MyAppWatch_Extension`

- `-show-sourcekit-queries`: Prints queries sent to SourceKit. Note that they are huge and will absolutely clutter your terminal, so use this only for bug reports and feature development!

### Manual mode

```
swiftshield -project-root /app/MyApp
```
**Required Parameters:**

- `-project-root`: The root of your project. SwiftShield will use this to search for your project files, storyboards and source files.

**Optional Parameters:**

- `-tag`: Uses a custom tag. Default is `__s`.

### Aditional parameters for both modes

- `-verbose`: Prints additional information.

- `-obfuscation-character-count`: Set the number of characters that obfuscated names will have. By default, this is `32`. Be aware that using a small number will result in slower runs due to the higher possibility of name collisions.

- `-dry-run`: Does not actually overwrite the files. Useful for debugging!


## 🤝 Contributing

Contributions to SwiftShield are more than welcome! There's no contribution guidelines for now, so you're free to use the Issues tab to discuss future features and improvements.


## ✅ Automatic Mode Next Steps

- [X] Method names
- [X] Update Extension plists (Rich Notifications / Watch main classes)
- [X] "SDK Mode" (ignore `public`)
- [ ] Properties
- [ ] Module names


## License

SwiftShield is released under the GNU GPL v3.0 license. See LICENSE for details.


## Thanks

Thanks to John Holdsworth from [Refactorator](https://github.com/johnno1962/Refactorator) for `SourceKit.swift`, Apple for their open-source SourceKit wrapper and to SourceKitten for helping me figure out which compile arguments to ignore for SourceKit.

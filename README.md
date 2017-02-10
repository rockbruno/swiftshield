<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >
# Swift Obfuscator

[![CocoaPods Version](https://cocoapod-badges.herokuapp.com/v/SwiftShield/badge.png)](http://cocoadocs.org/docsets/SwiftShield)
[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/rockbruno/swiftshield/master/LICENSE)

SwiftShield is a tool that generates irreversible, encrypted names for your Swift project classes (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS/macOS apps, such as [class-dump](http://stevenygard.com/projects/class-dump/).
For example, after running SwiftShield, the following class:
```swift
class EncryptedVideoPlayer {
  func start() {
    let vc = ImportantDecryptingController()
    vc.start()
  }
}
```
becomes:
```swift
class djjck3KDxjs04tgbvb {
  func start() {
    let vc = aAAAa2nc0dfmDssf()
    vc.start()
  }
}
```


## How do I deal with crash logs / analytics if my project uses SwiftShield?

After succesfully encrypting your project, SwiftShield generates a `conversionMap.txt` file with all the changes it made to your project, allowing you to pinpoint what an encrypted class really is.
````
//
//  SwiftShield
//  Conversion Map
//

Classes:

ViewController ===> YytSIcFnBAqTAyR
AppDelegate ===> uJXJkhVbwdQGNhh
SuperImportantClassThatShouldBeHidden ===> GDqKGsHjJsWQzdq
````


## Installation

**Warning:** SwiftShield **irreversibly overwrites** all of your .swift files and triples your build times. You should make sure it runs only on your CI server, and on release builds.

Using [CocoaPods](http://cocoapods.org/):

```ruby
use_frameworks!
pod 'SwiftShield'
```

[Click here](https://github.com/rockbruno/swiftshield/blob/master/CONFIGURATION.md) to see how to configure SwiftShield inside your project.


## Next steps

SwiftShield is new, and even though it works, it takes quite some time to do so. It works by obfuscating your classes' declarations and then triggering a build. This build will fail, revealing the location of where the classes are being used, which then are accessed and obfuscated. The process is repeated until the project builds succesfully. Unfortunately, the Swift compiler sometimes doesn't show all errors at once, needing dozens of compiles in order to completely obfuscate a target.

The correct way of doing this is giving SwiftShield a complete understading of Swift (like it already has regarding class declarations), so files can be obfuscated in a single go. This already works rather well, but Swift's Module's are the prime reason why this isn't released yet. If you want to help, you can check it out at the `manual-parsing-obfuscation` branch.

## License

SwiftShield is released under the MIT license. See LICENSE for details.

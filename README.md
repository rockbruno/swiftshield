<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >
# Swift Class Obfuscator

SwiftShield is a tool that generates irreversible, encrypted names for your Swift project classes (including your Pods and Storyboards) in order to protect your app from tools that reverse engineer iOS/macOS apps, such as [class-dump](http://stevenygard.com/projects/class-dump/).
For example, after running SwiftShield, the following class:
```swift
class EncryptedVideoPlayer {
  func start() {
    let controller = ImportantDecryptingController()
    controller.start()
  }
}
```
becomes:
```swift
class djjck3KDxjs04tgbvb {
  func start() {
    let controller = aAAAa2nc0dfmDssf()
    controller.start()
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


## Installing

**Warning:** SwiftShield irreversibly overwrites all your .swift files. Ideally, you should make sure it runs only on your CI server. It also takes a long time to build.

After adding the SwiftShield binary to your project root, create a **New Run Script Phase** on your Build Phases tab, position it before the Compile Sources phase and add the following script: **(don't forget to change "Release" to something that is only executed by your CI server)**

````
if [ "${CONFIGURATION}" = "Release" ]; then
  "$SRCROOT/swiftshield" -p "$SRCROOT" -s 15 -v
fi
````
`-p` is the path where SwiftShield should start looking for .swift files. Unless you're storing files outside your project's folders, $SRCROOT will do the trick.

`-s` is how long the encrypted names should be.

`-v` is optional, and prints additional info about the encrypting proccess.

If your project uses Cocoapods, make sure that your machine have the permissions to edit the Pods folder's contents. If it doesn't, SwiftShield will crash.


## Next steps

SwiftShield is new, and even though it works, it takes quite some time to do so. It works by obfuscating your classes' declarations and then triggering a build. This build will fail, revealing the location of where the classes are being used, which then are accessed and obfuscated. The process is repeated until the project builds succesfully. Unfortunately, the Swift compiler sometimes doesn't show all errors at once, needing dozens of compiles in order to completely obfuscate a target.

The correct way of doing this is giving SwiftShield a complete understading of Swift (like it already has regarding class declarations), so files can be obfuscated in a single go. This already works rather well, but Swift's Module's are the prime reason why this isn't released yet. If you want to help, you can check it out at the `manual-parsing-obfuscation` branch.

## License

SwiftShield is released under the MIT license. See LICENSE for details.

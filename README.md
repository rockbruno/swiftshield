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

**Warning:** SwiftShield irreversibly overwrites all your .swift files. Ideally, you should make sure it runs only on your CI server.

After adding the SwiftShield binary to your project root, create a **New Run Script Phase** on your Build Phases tab, position it **right before** the Compile Sources phase and add the following script: **(don't forget to change "Release" to something that is only executed by your CI server)**

````
if [ "${CONFIGURATION}" = "Release" ]; then
  "$SRCROOT/swiftshield" -p "$SRCROOT" -s 15 -v
fi
````
`-p` is the path where SwiftShield should start looking for .swift files. Unless you're storing files outside your project's folders, $SRCROOT will do the trick.

`-s` is how long the encrypted names should be.

`-v` is optional, and prints additional info about the encrypting proccess.


## License

SwiftShield is released under the MIT license. See LICENSE for details.

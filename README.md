<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >
# (WIP) Swift Class Obfuscator

SwiftShield is a tool that generates irreversible, encrypted names for your Swift classes in order to protect your app from tools that dump information of iOS/macOS apps, such as [class-dump](http://stevenygard.com/projects/class-dump/).
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
  

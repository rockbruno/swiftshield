# SwiftShield Usage


## (Optional) Enable Xcode's "Continue building after errors" option

To make Swiftshield run faster, you should enable the `Continue building after errors` option on your Xcode settings's General tab.

<img src="https://i.stack.imgur.com/Pa0UT.png" alt="Xcode settings">

## Modify Run Scripts that can affect SwiftShield

If your project uses a framework that also changes your .swift files, like `R.swift` or `SwiftGen`, you need to prevent them from interfering with SwiftShield. Don't worry, it's very simple. You probably have a Run Script configured to run these frameworks. You just need to wrap them around a `"$SWIFTSHIELDED" != "true"` condition.
For example, my SwiftGen script:
```bash
$PODS_ROOT/SwiftGen/bin/swiftgen images --output $SRCROOT/Asset.swift $SRCROOT/Assets.xcassets
```
Should be changed to:
```bash
if [ "$SWIFTSHIELDED" != "true" ]; then
    $PODS_ROOT/SwiftGen/bin/swiftgen images --output $SRCROOT/Asset.swift $SRCROOT/Assets.xcassets
fi
```

This will prevent that script from running after your project gets obfuscated.


## Unlocking your Project (if you use Cocoapods)

By default, Cocoapod sources are locked. SwiftShield needs them to be unlocked in order to be able to obfuscate your project. To unlock your project, you can run:

`chmod -R 774 PATHTOPROJECTFOLDER`


## Running SwiftShield

```
./swiftshield -projectroot /Desktop/MyApp -projectfile /Desktop/MyApp/MyApp.xcworkspace -scheme 'MyApp-AppStore' -ignoreschemes 'MyApp-CI,MyApp-Debug' -v
```
**Required Parameters:**

`-projectroot`: The root of your project. SwiftShield will use this to search for .swift files, and .xcodeproj files in order to map your app's modules.

`-projectfile`: Your app's main .xcodeproj/.xcworkspace file.

`-scheme`: The main scheme to build from your `-projectfile`. SwiftShield will obfuscate every scheme, but this one will be the last one. This should be your app's main target.

**Optional Parameters:**

`-ignoreschemes`: If your app has multiple schemes that point to the same target, like MyApp-CI/MyApp-Debug/MyApp-AppStore, you can use this setting to ignore the irrelevant targets.

`-structs`: Obfuscates structs as well. This can make SwiftShield take several hours to run.

`-v`: Prints additional information about the obfuscation proccess.

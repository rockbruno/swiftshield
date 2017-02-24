# SwiftShield Usage


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


## Unlocking your Project (if you use CocoaPods)

By default, CocoaPods sources are locked. SwiftShield needs them to be unlocked in order to be able to obfuscate your project. To unlock your project, you can run:

`chmod -R 774 PATHTOPROJECTFOLDER`


## Running SwiftShield

```
./swiftshield -projectroot /Desktop/MyApp -projectfile /Desktop/MyApp/MyApp.xcworkspace -scheme 'MyApp-AppStore' -v
```
**Required Parameters:**

`-projectroot`: The root of your project. SwiftShield will use this to search for .xcodeproj in order to tag them as `SWIFTSHIELDED`.

`-projectfile`: Your app's main .xcodeproj/.xcworkspace file.

`-scheme`: The main scheme to build from your `-projectfile`.

**Optional Parameters:**

`-v`: Prints additional information, as well as SourceKit's calls.

# SwiftShield Usage


## Modify scripts that can affect SwiftShield

If your project uses a framework that also modifies your files, like `R.swift` or `SwiftGen`, you need to prevent them from interfering with SwiftShield. Don't worry, it's very simple. You probably have a Run Script configured to run these frameworks. You just need to wrap them around a `"$SWIFTSHIELDED" != "true"` condition.
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

By default, CocoaPods sources are locked. SwiftShield needs them to be unlocked in order to be able to obfuscate your project. To unlock your project, you can run, for example:

`chmod -R 774 PATHTOPROJECTFOLDER`


## Running SwiftShield


# Manual mode

```
swiftshield -projectroot /Desktop/MyApp
```
**Required Parameters:**

`-projectroot`: The root of your project. SwiftShield will use this to search for your .xcodeprojs in order to tag them as `SWIFTSHIELDED`.

**Optional Parameters:**

`-tag 'myTag'`: Uses a custom tag. Default is `_SHIELDED`.

`-v`: Prints additional information.


# Automatic mode

```
swiftshield -auto -projectroot /Desktop/MyApp -projectfile /Desktop/MyApp/MyApp.xcworkspace -scheme 'MyApp-AppStore'
```
**Required Parameters:**

`-auto`: Enables automatic mode.

`-projectroot`: The root of your project. SwiftShield will use this to search for your .xcodeprojs in order to tag them as `SWIFTSHIELDED`.

`-projectfile`: Your app's main .xcodeproj/.xcworkspace file.

`-scheme 'myScheme'`: The main scheme to build from your `-projectfile`.

**Optional Parameters:**

`-v`: Prints additional information, as well as SourceKit's calls.

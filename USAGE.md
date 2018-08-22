# SwiftShield Usage


## Modify scripts that can affect SwiftShield

If your project uses a framework that also modifies your files, like `R.swift` or `SwiftGen`, you need to prevent them from interfering with SwiftShield. You probably have a Run Script configured to run these frameworks - all you have to do is wrap them around a `"$SWIFTSHIELDED" != "true"` condition.
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


## (Automatic Mode) Unlocking your Project (if you use CocoaPods)

By default, CocoaPods sources are locked. SwiftShield needs them to be unlocked in order to be able to obfuscate your project. To unlock your project, you can run, for example:

`chmod -R 774 PATHTOPROJECTFOLDER`

You can now run SwiftShield with the commands provided at [README.md](README.md).
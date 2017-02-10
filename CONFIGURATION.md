# Configuring SwiftShield

(WIP)

After installing it with CocoaPods, open your workspace and add a new Target to your app.

At the target, add this Run Script at the top of everything:

```
ONLY_RUN_AT="Release-AppStore" //SwiftShield will only run if you trigger a build with this specific configuration. Set this to something only your CI server executes.
MAIN_SCHEME="MyApp-AppStore" //When SwiftShield is executed, it will obfuscate all schemes from your workspace, with MAIN_SCHEME being the last one. You should put your app's scheme here.
IGNORED_SCHEMES="MyApp-Debug,MyApp-Enterprise" //If your app has multiple schemes, you can prevent the irrelevant ones from being executed.

chmod -R 774 $SRCROOT/  //SwiftShield will unlock your Pods folder in order to obfuscate your pods. Make sure you have the right permissions to run this or SwiftShield will crash!

if [ "$CONFIGURATION" = "$ONLY_RUN_AT" ] && [ "$ALREADY_RUNNING_SWIFTSHIELD" != "true" ]; then
	$SRCROOT/Pods/SwiftShield/bin/swiftshield -projectroot "$SRCROOT" -scheme "$MAIN_SCHEME" -ignoreschemes "$IGNORED_SCHEMES" -v
fi
```

With the script set, go back to your app's target and move SwiftShield's framework above everything, to make sure it's the first thing executed on your build.
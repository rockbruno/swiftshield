<img src="http://i.imgur.com/0ksj7Gh.png" alt="SwiftShield logo" height="140" >

```swift
struct fjiovh4894bvic: XbuinvcxoDHFh3fjid {
  let VNfhnfn3219d: Vnahfi5n34djga
  func cxncjnx8fh83FDJSDd() -> Lghbna2gf0gmh3d {
    return vPAOSNdcbif372hFKF(VNfhnfn3219d.Gjanbfpgi3jfg())
  }
}
```

# SwiftShield: Swift Obfuscator

**Don't use this tool for production apps. I gave up on keeping this tool updated because every Swift release breaks SourceKit in a different way. It's probably really broken and is only useful as a way for you to learn more about obfuscation and SourceKit.**

[![GitHub release](https://img.shields.io/github/tag/rockbruno/swiftshield.svg)](https://github.com/rockbruno/swiftshield/releases)

SwiftShield is a tool that generates random and irreversible encrypted names for your iOS project's types and methods (including third-party libraries). It uses Apple's SourceKit to mimick Xcode's indexing behavior, revealing a complete map of your project that is used to safely rename parts of your project. 

Reverse engineering iOS apps is relatively simple due to the fact that almost every single type and method name is exposed in the app's binary. This allows jailbreak tools like `class-dump` and `Cycript` to extract this information and use it to change the behavior of your app in runtime. 

Obfuscating code in iOS makes the usage of these tools difficult, while also making it tougher for jailbreak developers to create tweaks for your app as SwiftShield's obfuscation changes every time you run it.

## Limitations

The capabilities of SwiftShield are directly related to the capabilities of SourceKit, which unfortunately has its share of bugs. However, although SwiftShield can't obfuscate *everything*, it can obfuscate just enough to make reverse engineering very hard. [Check this document to see its capabilities in detail](SOURCEKITISSUES.md).

## Requirements

- You should not have logic based on hardcoded names (like loading `MyClass.json` because `String(describing: type(of:self))` is `'MyClass'`). SwiftShield does not obfuscate things like file names and hardcoded strings -- only the types themselves.
- No Objective-C classes that call Swift methods (but Swift classes calling Objective-C code are fine).
- Your project should be 100% written in View Code. Older versions of SwiftShield did support obfuscating Storyboards/XIBs, but it was extremely hard to maintain. This parts from the principle that if you have a project big or important enough to be obfuscated, you probably shouldn't be using Storyboards in the first place.
- Your project should **not** be using Xcode's Legacy Build System setting.
- Make sure your project doesn't suffer from [one of SourceKit's bugs](SOURCEKITISSUES.md). Although the bugs won't prevent the project from being obfuscated, some of them might require you to manually fix the resulting code as it will not be able to compile.

## Usage

Check this repo's example project to see it in action! You can run it by executing `make swiftshield` in your terminal.

### Downloading SwiftShield

You can get a SwiftShield binary from [the releases page](https://github.com/rockbruno/swiftshield/releases).

### Modify scripts that can affect SwiftShield

If your project uses a framework that also modifies your files like `SwiftGen`, you need to prevent them from running alongside SwiftShield. This can be done by checking for the `$SWIFTSHIELDED` Xcode variable that is added by SwiftShield after your project is obfuscated.

For example, my SwiftGen Xcode Run Script:

```bash
$PODS_ROOT/SwiftGen/bin/swiftgen images --output $SRCROOT/Asset.swift $SRCROOT/Assets.xcassets
```
...should be changed to:

```bash
if [ "$SWIFTSHIELDED" != "true" ]; then
    $PODS_ROOT/SwiftGen/bin/swiftgen images --output $SRCROOT/Asset.swift $SRCROOT/Assets.xcassets
fi
```

### Unlock Sources

If you're using a dependency manager like CocoaPods, you need to make sure that the sources are unlocked. If they aren't, SwiftShield will fail saying that it failed to overwrite the files. To unlock your project, execute:

`chmod -R 774 PATHTOPROJECTFOLDER`

### Running SwiftInfo

```bash
USAGE: swiftshield obfuscate --project-file <project-file> --scheme <scheme> [--ignore-public] [--ignore-targets] [--verbose] [--dry-run] [--print-sourcekit]

OPTIONS:
  -p, --project-file <project-file>
                          The path to your app's main .xcodeproj/.xcworkspace
                          file. 
  -s, --scheme <scheme>   The main scheme from the project to build. 
  --ignore-public         Don't obfuscate content that is 'public' or 'open'
                          (a.k.a 'SDK Mode'). 
  -i, --ignore-targets    A list of targets, separated by a comma, that should
                          NOT be obfuscated. 
  -v, --verbose           Prints additional information. 
  -d, --dry-run           Does not actually overwrite the files. 
  --print-sourcekit       Prints SourceKit queries. Note that they are huge, so
                          use this only for bug reports and development! 
  -h, --help              Show help information.
```

## Deobfuscating crash logs

A successful run of SwiftShield generates a `swiftshield-output/conversionMap.txt` file that contains all changes made to your project:

```
//
//  SwiftShield
//  Conversion Map
//  Automatic mode for MyApp 2.0 153, 2018-09-24 10.23.48
//

Data:

ViewController ===> YytSIcFnBAqTAyR
AppDelegate ===> uJXJkhVbwdQGNhh
SuperImportantClassThatShouldBeHidden ===> GDqKGsHjJsWQzdq
```

Make sure to store this file when you publish a release, as it can be used to deobfuscate crash logs from the app that generated it through SwiftShield's `deobfuscate` subcommand.

```
USAGE: swiftshield deobfuscate --crash-file <crash-file> --conversion-map <conversion-map>

OPTIONS:
  -c, --crash-file <crash-file>
                          The path to the crash file. 
  -m, --conversion-map <conversion-map>
                          The path to the previously generated conversion map. 
  -h, --help              Show help information.
```

<img src="https://i.imgur.com/qMKy84P.png" alt="SwiftShield logo" height="172">

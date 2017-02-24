import Foundation
/*
let SK = SourceKit()

let verbose = true

let args = SK.array(argv: [
    "-module-name",
    "Freddy",
    "-Onone",
    "-D",
    "COCOAPODS",
    "-suppress-warnings",
    "-sdk",
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.1.sdk",
    "-target",
    "arm64-apple-ios8.0",
    "-g",
    "-module-cache-path",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/ModuleCache",
    "-Xfrontend",
    "-serialize-debugging-options",
    "-embed-bitcode-marker",
    "-enable-testing",
    "-I",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Products/Debug-iphoneos/Freddy",
    "-F",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Products/Debug-iphoneos/Freddy",
    "-c",
    "-j4",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSON.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONDecodable.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONEncodable.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONEncodingDetector.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONLiteralConvertible.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONParser.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONParsing.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONSerializing.swift",
    "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONSubscripting.swift",
    "-emit-module",
    "-emit-module-path",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Objects-normal/arm64/Freddy.swiftmodule",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/swift-overrides.hmap",
    "-Xcc",
    "-iquote",
    "-Xcc",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Freddy-generated-files.hmap",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Freddy-own-target-headers.hmap",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Freddy-all-non-framework-target-headers.hmap",
    "-Xcc",
    "-ivfsoverlay",
    "-Xcc",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/all-product-headers.yaml",
    "-Xcc",
    "-iquote",
    "-Xcc",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Freddy-project-headers.hmap",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Products/Debug-iphoneos/Freddy/include",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Private",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Public",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Public/Crashlytics",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Public/Fabric",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Public/Reveal-SDK",
    "-Xcc",
    "-I/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Headers/Public/SwiftGen",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/DerivedSources/arm64",
    "-Xcc",
    "-I/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/DerivedSources",
    "-Xcc",
    "-DPOD_CONFIGURATION_DEBUG=1",
    "-Xcc",
    "-DDEBUG=1",
    "-Xcc",
    "-DCOCOAPODS=1",
    "-emit-objc-header",
    "-emit-objc-header-path",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/Objects-normal/arm64/Freddy-Swift.h",
    "-import-underlying-module",
    "-Xcc",
    "-ivfsoverlay",
    "-Xcc",
    "/Users/bruno.rocha/Library/Developer/Xcode/DerivedData/VivoMeditacao-bqopcdindlgtscgvtewihlenbnzq/Build/Intermediates/Pods.build/Debug-iphoneos/Freddy.build/unextended-module-overlay.yaml",
    "-Xcc",
    "-working-directory/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods"
    ])

SK.editorOpen(filePath: "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONDecodable.swift", compilerArgs: args)
//SK.cursorInfo(filePath: "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONDecodable.swift", byteOffset: 4697, compilerArgs: args)
let resp = SK.symbolOccurrences(filePath: "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/Pods/Freddy/Sources/JSONDecodable.swift", compilerArgs: args)
if let error = SK.error(resp: resp) {
    Logger.log("SK Error: \(error)")
    exit(error: true)
}
let dict = SKApi.sourcekitd_response_get_value(resp)
exit()*/

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? "/Users/bruno.rocha/Desktop/vivo-meditacao-ios"
let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? "VivoMeditacao-AppStore"

let projectToBuild = UserDefaults.standard.string(forKey: "projectfile") ?? "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/VivoMeditacao.xcworkspace"

if basePath.isEmpty || mainScheme.isEmpty || projectToBuild.isEmpty {
    Logger.log("Bad arguments.\n\nRequired parameters:\n\n-projectroot PATH (Path to your project root, like /app/MyApp \n\n-projectfile PATH (Path to your project file, like /app/MyApp/MyApp.xcodeproj or /app/MyApp/MyApp.xcworkspace)\n\n-scheme 'SCHEMENAME' (Main scheme to build)\n\nOptional parameters:\n\n-v (Verbose mode)")
    exit(error: true)
}

let isWorkspace = projectToBuild.hasSuffix(".xcworkspace")

if isWorkspace == false && projectToBuild.hasSuffix(".xcodeproj") == false {
    Logger.log("Project file provided is not a project or workspace.")
    exit(error: true)
}

let verbose = true
let protectedClassNameSize = 25

Logger.log("SwiftShield 2.0.0")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)

let protector = Protector()

let modules = protector.getModulesAndCompilerArguments(scheme: mainScheme)
let obfuscationData = protector.index(modules: modules)
if obfuscationData.obfuscationDict.isEmpty {
    Logger.log("Found nothing to obfuscate. Finishing...")
    exit(error: true)
}

protector.obfuscateReferences(obfuscationData: obfuscationData)

let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])
let storyboardFiles = storyboardFilePaths.flatMap{ File(filePath: $0) }
protector.protectStoryboards(data: obfuscationData)

fileprivate let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", ignoreDirs: false) ?? []

protector.markAsProtected(projectPaths: projects)
protector.writeToFile(data: obfuscationData)

Logger.log("Finished.")

exit()

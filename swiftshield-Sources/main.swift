import Foundation

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? "/Users/bruno.rocha/Desktop/SwiftShieldExample"
let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? "SwiftProtectorExample-AppStore"

let projectToBuild = UserDefaults.standard.string(forKey: "projectfile") ?? "/Users/bruno.rocha/Desktop/SwiftShieldExample/SwiftProtectorExample.xcodeproj"

if basePath.isEmpty || mainScheme.isEmpty || projectToBuild.isEmpty {
    Logger.log("Bad arguments.\n\nRequired parameters:\n\n-projectroot PATH (Path to your project root, like /app/MyApp \n\n-projectfile PATH (Path to your project file, like /app/MyApp/MyApp.xcodeproj or /app/MyApp/MyApp.xcworkspace)\n\n-scheme 'SCHEMENAME' (Main scheme to build)\n\nOptional parameters:\n\n-v (Verbose mode)")
    exit(error: true)
}

let isWorkspace = projectToBuild.hasSuffix(".xcworkspace")

if isWorkspace == false && projectToBuild.hasSuffix(".xcodeproj") == false {
    Logger.log("Project file provided is not a project or workspace.")
    exit(error: true)
}

let verbose = CommandLine.arguments.contains("-v")
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

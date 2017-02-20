import Foundation

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? "/Users/bruno.rocha/Desktop/victim"
let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? "FenrirExample"

let projectToBuild = UserDefaults.standard.string(forKey: "projectfile") ?? "/Users/bruno.rocha/Desktop/victim/Fenrir.xcodeproj"

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

Logger.log("Swift Protector 1.0.1")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)

let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])
let storyboardFiles = storyboardFilePaths.flatMap{ File(filePath: $0) }

let protector = Protector()

let modules = protector.getModulesAndCompilerArguments(scheme: mainScheme)
let obfuscationData = protector.index(modules: modules)
protector.obfuscateImplementations(obfuscationData: obfuscationData)

protector.protectStoryboards(data: obfuscationData)

fileprivate let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", ignoreDirs: false) ?? []

protector.markAsProtected(projectPaths: projects)

protector.writeToFile(hash: protectionHash)
Logger.log("Finished.")
exit()

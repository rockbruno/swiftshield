import Foundation

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? ""
let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? ""

let projectToBuild = UserDefaults.standard.string(forKey: "projectfile") ?? ""

guard basePath.isEmpty == false, mainScheme.isEmpty == false, projectToBuild.isEmpty == false else {
    Logger.log("Bad arguments.\n\nRequired parameters:\n\n-projectroot PATH (Path to your project root, like /app/MyApp \n\n-projectfile PATH (Path to your project file, like /app/MyApp/MyApp.xcodeproj or /app/MyApp/MyApp.xcworkspace)\n\n-scheme 'SCHEMENAME' (Main scheme to build)\n\nOptional parameters:\n\n-ignoreschemes 'NAME1,NAME2,NAME3' (If you have multiple schemes that point to the same target, like MyApp-CI or MyApp-Debug, mark them as ignored to prevent errors)\n\n-v (Verbose mode)")
    exit(1)
}

let isWorkspace = projectToBuild.contains(".xcworkspace")
if isWorkspace == false && projectToBuild.contains(".xcodeproj") == false {
    Logger.log("Project file provided is not a project or workspace.")
    exit(1)
}

let verbose = CommandLine.arguments.contains("-v")
let protectedClassNameSize = 25

Logger.log("Swift Protector 1.0.0")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: true)

let swiftFilePaths = findFiles(rootPath: basePath, suffix: ".swift") ?? []
let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])

let swiftFiles = swiftFilePaths.flatMap { File(filePath: $0) }
let storyboardFiles = storyboardFilePaths.flatMap{ File(filePath: $0) }

let protector = Protector(swiftFiles: swiftFiles, storyboardFiles: storyboardFiles)

fileprivate let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", ignoreDirs: false) ?? []

protector.markAsProtected(projectPaths: projects)

fileprivate var protectionHash = protector.getProtectionHash(projectPaths: projects)

guard protectionHash.isEmpty == false else {
    Logger.log("No class/methods to obfuscate.")
    exit(0)
}

protector.protectStoryboards(hash: protectionHash)

fileprivate var schemes = protector.getSchemes()
var ignoredSchemes = UserDefaults.standard.string(forKey: "ignoreschemes")?.components(separatedBy: ",") ?? ["VivoLearning","VivoLearning-CI"]
ignoredSchemes.append(mainScheme)
schemes = schemes.filter{return ignoredSchemes.contains($0) == false && ignoredSchemes.contains("Pods-") == false}
schemes.append(mainScheme)

for scheme in schemes {
    Logger.log("Obfuscating \(scheme)")
    var parsedOutputHash = protector.parse(fakeBuildOutput: protector.runFakeBuild(scheme: scheme))
    while parsedOutputHash.keys.isEmpty == false {
        Logger.log("Collected errors. Running...")
        protector.protectClassReferences(output: parsedOutputHash, protectedHash: protectionHash)
        parsedOutputHash = protector.parse(fakeBuildOutput: protector.runFakeBuild(scheme: scheme))
    }
}

protector.writeToFile(hash: protectionHash)
Logger.log("Finished.")
exit(0)

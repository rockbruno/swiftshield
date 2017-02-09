import Foundation

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? "/Users/bruno.rocha/Desktop/vivo-meditacao-ios/"
let scheme = UserDefaults.standard.string(forKey: "scheme") ?? ""

guard basePath.isEmpty == false else {
    Logger.log("Bad arguments. Syntax: 'swiftshield -projectroot (project root) -size (encrypted class name length, optional, default is 15) -scheme (scheme to build) -v (verbose mode, optional)")
    exit(1)
}

let verbose = CommandLine.arguments.contains("-v")
let providedSize = UserDefaults.standard.integer(forKey: "size")
let protectedClassNameSize = providedSize > 0 ? providedSize : 15

Logger.log("Swift Protector 0.5")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: true)

let swiftFilePaths = findFiles(rootPath: basePath, suffix: ".swift") ?? []
let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])

let swiftFiles = swiftFilePaths.flatMap { File(filePath: $0) }
let storyboardFiles = storyboardFilePaths.flatMap{ File(filePath: $0) }

let protector = Protector(swiftFiles: swiftFiles, storyboardFiles: storyboardFiles)

let protectionHash = protector.getProtectionHash()

guard protectionHash.isEmpty == false else {
    Logger.log("No class/methods to obfuscate.")
    exit(0)
}

protector.protectStoryboards(hash: protectionHash)

let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", onlyAtRoot: true) ?? []
let workspaces = findFiles(rootPath: basePath, suffix: ".xcworkspace", onlyAtRoot: true) ?? []

if workspaces.count > 1 || (projects.count > 1 && workspaces.count > 1) || (projects.count > 1 && workspaces.count == 0) {
    Logger.log("Multiple projects (or multiple workspaces) found at the provided. Please make sure there's only one project (or workspace).")
}

var schemes = protector.getSchemes()
let ignoredSchemes = ["VivoMeditacao","VivoMeditacao-CI","VivoMeditacao-AppStore"]
schemes = schemes.filter{return ignoredSchemes.contains($0) == false}
schemes.append(ignoredSchemes.last!)

for scheme in schemes {
    Logger.log("Obfuscating \(scheme)!")
    
    let fakeBuildOutput: String = protector.runFakeBuild(scheme: scheme)
    var parsedOutputHash = protector.parse(fakeBuildOutput: fakeBuildOutput)
    while parsedOutputHash.keys.isEmpty == false {
        Logger.log("Collected errors. Running...")
        protector.protectClassReferences(output: parsedOutputHash, protectedHash: protectionHash)
        let fakeBuildOutput: String = protector.runFakeBuild(scheme: scheme)
        parsedOutputHash = protector.parse(fakeBuildOutput: fakeBuildOutput)
    }
}

protector.writeToFile(hash: protectionHash)
Logger.log("Finished.")
exit(0)

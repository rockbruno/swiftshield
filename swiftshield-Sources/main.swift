import Foundation

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? ""
let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? ""

guard basePath.isEmpty == false, mainScheme.isEmpty == false else {
    Logger.log("Bad arguments. Syntax: 'swiftshield [-projectroot PATH] [-scheme 'NAME']\nOptional parameters: [-ignoreschemes 'NAME1,NAME2,NAME3'] [-v]")
    exit(1)
}

let verbose = CommandLine.arguments.contains("-v")
let providedSize = UserDefaults.standard.integer(forKey: "size")
let protectedClassNameSize = 25

Logger.log("Swift Protector 1.0")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)
Logger.log("Class Name Size: \(protectedClassNameSize)", verbose: true)

let swiftFilePaths = findFiles(rootPath: basePath, suffix: ".swift") ?? []
let storyboardFilePaths = (findFiles(rootPath: basePath, suffix: ".storyboard") ?? []) + (findFiles(rootPath: basePath, suffix: ".xib") ?? [])

let swiftFiles = swiftFilePaths.flatMap { File(filePath: $0) }
let storyboardFiles = storyboardFilePaths.flatMap{ File(filePath: $0) }

let protector = Protector(swiftFiles: swiftFiles, storyboardFiles: storyboardFiles)

fileprivate let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", onlyAtRoot: true) ?? []
fileprivate let workspaces = findFiles(rootPath: basePath, suffix: ".xcworkspace", onlyAtRoot: true) ?? []

if workspaces.count > 1 || (projects.count > 1 && workspaces.count > 1) || (projects.count > 1 && workspaces.count == 0) {
    Logger.log("Multiple projects (or multiple workspaces) found at the provided. Please make sure there's only one project (or workspace).")
    exit(1)
}

let projectToBuild = workspaces.count == 1 ? workspaces[0] : projects[0]
let isWorkspace = workspaces.count == 1

let protectionHash = protector.getProtectionHash()

guard protectionHash.isEmpty == false else {
    Logger.log("No class/methods to obfuscate.")
    exit(0)
}

protector.protectStoryboards(hash: protectionHash)

fileprivate var schemes = protector.getSchemes()
var ignoredSchemes = UserDefaults.standard.string(forKey: "ignoreschemes")?.components(separatedBy: ",") ?? []
ignoredSchemes.append(contentsOf: ["SwiftShield",mainScheme])
schemes = schemes.filter{return ignoredSchemes.contains($0) == false}
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

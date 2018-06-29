import Foundation

if CommandLine.arguments.contains("-h") {
    Logger.log(.helpText)
    exit()
}

Logger.verbose = CommandLine.arguments.contains("-verbose")
SKAPI.verbose = CommandLine.arguments.contains("-show-sourcekit-queries")

let automatic = CommandLine.arguments.contains("-automatic")

Logger.log(.version)
Logger.log(.verbose)
Logger.log(.mode)

let basePath = UserDefaults.standard.string(forKey: "project-root") ?? ""

let protector: Protector
if automatic {
    let schemeToBuild = UserDefaults.standard.string(forKey: "automatic-project-scheme") ?? ""
    let projectToBuild = UserDefaults.standard.string(forKey: "automatic-project-file") ?? ""
    protector = AutomaticSwiftShield(basePath: basePath, projectToBuild: projectToBuild, schemeToBuild: schemeToBuild)
} else {
    let tag = UserDefaults.standard.string(forKey: "tag") ?? "__s"
    protector = ManualSwiftShield(basePath: basePath, tag: tag)
}

let obfuscationData = protector.protect()
if obfuscationData.obfuscationDict.isEmpty {
    Logger.log(.foundNothingError)
    exit(error: true)
}
protector.protectStoryboards(data: obfuscationData)
protector.writeToFile(data: obfuscationData)
protector.markProjectsAsProtected()
Logger.log(.finished)
exit()

import Foundation

if CommandLine.arguments.contains("-h") {
    Logger.log(String.badArguments)
    exit()
}

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? ""

let verbose = CommandLine.arguments.contains("-v")
let protectedClassNameSize = 25

let automatic = CommandLine.arguments.contains("-auto")

Logger.log("SwiftShield 2.0.1")
Logger.log("Verbose Mode", verbose: true)
Logger.log("Path: \(basePath)", verbose: true)

if automatic {
    AutomaticSwiftShield().protect()
} else {
    ManualSwiftShield().protect()
}

import Foundation

if CommandLine.arguments.contains("-h") {
    Logger.log(.helpText)
    exit()
}

let basePath = UserDefaults.standard.string(forKey: "projectroot") ?? ""

let verbose = CommandLine.arguments.contains("-v")
let protectedClassNameSize = 25

let automatic = CommandLine.arguments.contains("-auto")

Logger.log(.version)
Logger.log(.verbose)
Logger.log(.mode)

if automatic {
    AutomaticSwiftShield().protect()
} else {
    ManualSwiftShield().protect()
}

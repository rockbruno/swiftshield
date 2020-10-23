import ArgumentParser
import Foundation
import SwiftShieldCore

struct Swiftshield: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "SwiftShield 4.1.1",
        subcommands: [Obfuscate.self, Deobfuscate.self]
    )
}

extension Swiftshield {
    struct Obfuscate: ParsableCommand {
        @Option(name: .shortAndLong, help: "The path to your app's main .xcodeproj/.xcworkspace file.")
        var projectFile: String

        @Option(name: .shortAndLong, help: "The main scheme from the project to build.")
        var scheme: String

        @Option(name: .shortAndLong, help: "A list of targets, separated by a comma, that should NOT be obfuscated.")
        var ignoreTargets: String?
        
        @Option(name: .shortAndLong, help: "A list of names, separated by a comma, that should NOT be obfuscated.")
        var ignoreNames: String?

        @Flag(help: "Don't obfuscate content that is 'public' or 'open' (a.k.a 'SDK Mode').")
        var ignorePublic: Bool

        @Flag(name: .shortAndLong, help: "Prints additional information.")
        var verbose: Bool

        @Flag(name: .shortAndLong, help: "Does not actually overwrite the files.")
        var dryRun: Bool

        @Flag(help: "Prints SourceKit queries. Note that they are huge, so use this only for bug reports and development!")
        var printSourcekit: Bool

        func run() throws {
            let modulesToIgnore = Set((ignoreTargets ?? "").components(separatedBy: ","))
            let namesToIgnore = Set((ignoreNames ?? "").components(separatedBy: ","))
            let runner = SwiftSwiftAssembler.generate(
                projectPath: projectFile, scheme: scheme,
                modulesToIgnore: modulesToIgnore,
                namesToIgnore: namesToIgnore,
                ignorePublic: ignorePublic,
                dryRun: dryRun,
                verbose: verbose,
                printSourceKitQueries: printSourcekit
            )
            try runner.run()
        }
    }
}

extension Swiftshield {
    struct Deobfuscate: ParsableCommand {
        @Option(name: .shortAndLong, help: "The path to the crash file.")
        var crashFile: String

        @Option(name: [.long, .customShort("m")], help: "The path to the previously generated conversion map.")
        var conversionMap: String

        func run() throws {
            let runner = Deobfuscator()
            try runner.deobfuscate(crashFilePath: crashFile, mapPath: conversionMap)
        }
    }
}

Swiftshield.main()

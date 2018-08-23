import Foundation

struct XcodeProjectBuilder {

    private typealias MutableModuleData = (source: [File], xibs: [File], args: [String])
    private typealias MutableModuleDictionary = [String: MutableModuleData]

    let projectToBuild: String
    let schemeToBuild: String

    var isWorkspace: Bool {
        return projectToBuild.hasSuffix(".xcworkspace")
    }

    init(projectToBuild: String, schemeToBuild: String) {
        self.projectToBuild = projectToBuild
        self.schemeToBuild = schemeToBuild
    }

    func getModulesAndCompilerArguments() -> [Module] {
        Logger.log(.buildingProject)
        let path = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        let arguments: [String] = [projectParameter, projectToBuild, "-scheme", schemeToBuild]
        let cleanTask = Process()
        cleanTask.launchPath = path
        cleanTask.arguments = ["clean", "build"] + arguments + ["CODE_SIGN_IDENTITY=", "CODE_SIGNING_REQUIRED=NO"]
        let outpipe: Pipe = Pipe()
        cleanTask.standardOutput = outpipe
        cleanTask.standardError = outpipe
        cleanTask.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outdata, encoding: .utf8) else {
            Logger.log(.compilerArgumentsError)
            exit(error: true)
        }
        return parseModulesFrom(xcodeBuildOutput: output)
    }

    func parseModulesFrom(xcodeBuildOutput output: String) -> [Module] {
        let lines = output.components(separatedBy: "\n")
        var modules: MutableModuleDictionary = [:]
        for line in lines {
            if let moduleName = firstMatch(for: "(?<=-module-name ).*?(?= )", in: line) {
                parseMergeSwiftModulePhase(line: line, moduleName: moduleName, modules: &modules)
            } else if let moduleName = firstMatch(for: "(?<=--module ).*?(?= )", in: line) {
                parseCompileXibPhase(line: line, moduleName: moduleName, modules: &modules)
            }
        }
        return modules.map {
            Module(name: $0.key, sourceFiles: $0.value.source, xibFiles: $0.value.xibs, compilerArguments: $0.value.args)
        }
    }

    private func parseMergeSwiftModulePhase(line: String, moduleName: String, modules: inout MutableModuleDictionary) {
        guard modules[moduleName]?.args.isEmpty != false else {
            return
        }
        guard let fullRelevantArguments = firstMatch(for: "/usr/bin/swiftc.*-module-name \(moduleName) .*", in: line) else {
            return
        }
        Logger.log(.found(module: moduleName))
        let spacedFolderPlaceholder = "\u{0}"
        let relevantArguments = fullRelevantArguments.replacingOccurrences(of: "\\ ", with: spacedFolderPlaceholder)
            .components(separatedBy: " ")
            .map { $0.replacingOccurrences(of: spacedFolderPlaceholder, with: " ")}
        let files = parseModuleFiles(from: relevantArguments)
        let compilerArguments = parseCompilerArguments(from: relevantArguments)
        modules[moduleName, default: ([], [], [])].source = files
        modules[moduleName]?.args = compilerArguments
    }

    private func parseModuleFiles(from relevantArguments: [String]) -> [File] {
        var files: [File] = []
        var fileZone: Bool = false
        for arg in relevantArguments {
            if fileZone {
                if arg.hasPrefix("/") {
                    let file = File(filePath: arg)
                    files.append(file)
                }
                fileZone = arg.hasPrefix("-") == false || files.count == 0
            } else {
                fileZone = arg == "-c"
            }
        }
        return files
    }

    private func parseCompilerArguments(from relevantArguments: [String]) -> [String] {
        var args: [String?] = Array(relevantArguments.dropFirst())
        while let indexOfOutputMap = args.index(of: "-output-file-map") {
            args[indexOfOutputMap] = nil
            args[indexOfOutputMap + 1] = nil
        }
        let forbiddenArgs = ["-parseable-output", "-incremental", "-serialize-diagnostics", "-emit-dependencies"]
        for (index, arg) in args.enumerated() {
            if forbiddenArgs.contains(arg ?? "") {
                args[index] = nil
            } else if arg == "-O" {
                args[index] = "-Onone"
            } else if arg == "-DNDEBUG=1" {
                args[index] = "-DDEBUG=1"
            }
        }
        args.append(contentsOf: ["-D", "DEBUG"])
        return args.compactMap { $0 }
    }

    private func parseCompileXibPhase(line: String, moduleName: String, modules: inout MutableModuleDictionary) {
        guard let xibPath = firstMatch(for: "(?=)[^ ]*$", in: line) else {
            return
        }
        guard xibPath.hasSuffix(".xib") || xibPath.hasSuffix(".storyboard") else {
            return
        }
        let file = File(filePath: xibPath)
        modules[moduleName, default: ([], [], [])].xibs.append(file)
    }
}

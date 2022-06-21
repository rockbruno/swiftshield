import Foundation

struct SchemeInfoProvider: SchemeInfoProviderProtocol {
    let projectFile: File
    let schemeName: String
    let taskRunner: TaskRunnerProtocol
    let logger: LoggerProtocol
    let modulesToIgnore: Set<String>

    var isWorkspace: Bool {
        projectFile.path.hasSuffix(".xcworkspace")
    }

    private typealias MutableModuleData = (source: [File], plists: [File], args: [String], order: Int)
    private typealias MutableModuleDictionary = [String: MutableModuleData]

    func getModulesFromProject() throws -> [Module] {
        logger.log("--- Building project to retrieve compiler arguments.")
        let command = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        let arguments: [String] = [
            projectParameter, projectFile.path, "-scheme", schemeName, "-sdk", "iphonesimulator", "clean", "build",
        ]

        let result = taskRunner.runTask(withCommand: command, arguments: arguments)

        guard let output = result.output else {
            throw logger.fatalError(forMessage: "Failed to retrieve output from Xcode.")
        }

        if result.terminationStatus != 0 {
            logger.log(output)
            throw logger.fatalError(forMessage: "It looks like xcodebuild failed. The log was printed above.")
        }

        return try parseModules(fromOutput: output)
    }

    func parseModules(fromOutput output: String) throws -> [Module] {
        let lines = output.components(separatedBy: "\n")
        var modules: MutableModuleDictionary = [:]
        for (index, line) in lines.enumerated() {
            if let moduleName = firstMatch(for: "(?<=-module-name ).*?(?= )", in: line) {
                try parseMergeSwiftModulePhase(line: line, moduleName: moduleName, modules: &modules)
            } else if line.hasPrefix("ProcessInfoPlistFile") ||
                line.hasPrefix("CopyPlistFile") ||
                line.hasPrefix("Preprocess") {
                try parsePlistPhase(line: line + lines[index + 1], modules: &modules)
            }
        }
        return modules.filter { modulesToIgnore.contains($0.key) == false }.sorted { $0.value.order < $1.value.order }.map {
            Module(name: $0.key,
                   sourceFiles: Set($0.value.source),
                   plists: Set($0.value.plists.removeDuplicates()),
                   compilerArguments: $0.value.args)
        }
    }

    private func parseMergeSwiftModulePhase(line: String, moduleName: String, modules: inout MutableModuleDictionary) throws {
        guard modules[moduleName]?.args.isEmpty != false else {
            return
        }
        guard var fullRelevantArguments = firstMatch(for: "/usr/bin/swiftc.*-module-name \(moduleName) .*", in: line) else {
            throw logger.fatalError(forMessage: "Failed to retrieve \(moduleName) xcodebuild arguments")
        }

        logger.log("Found Module: \(moduleName)")

        var swiftFileList: File?
        let result = fullRelevantArguments.match(regex: "(?<=@).*SwiftFileList")
        if let pathRange = result.first?.range {
            let nsStr = fullRelevantArguments as NSString
            let fullRange = NSMakeRange(pathRange.location - 1, pathRange.length + 1)
            swiftFileList = File(path: nsStr.substring(with: pathRange))
            fullRelevantArguments = nsStr.replacingCharacters(in: fullRange, with: "")
        }

        let relevantArguments = fullRelevantArguments.replacingEscapedSpaces
            .components(separatedBy: " ")
            .map { $0.removingPlaceholder }

        var files: [File]
        var compilerArguments = parseCompilerArguments(from: relevantArguments)

        if let swiftFileList = swiftFileList {
            let swiftFilePaths = try swiftFileList.read()
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }.map{ $0.removeEscapedSpaces }

            if let complieFlagIndex = compilerArguments.firstIndex(of: "-c") {
                var insertIndex = complieFlagIndex
                if complieFlagIndex + 1 < compilerArguments.count,
                    compilerArguments[complieFlagIndex + 1].hasPrefix("-j") {
                    insertIndex += 1
                }

                compilerArguments.insert(contentsOf: swiftFilePaths, at: insertIndex + 1)
            } else {
                compilerArguments.append(contentsOf: ["-c"] + swiftFilePaths)
            }

            files = swiftFilePaths.map(File.init)
        } else {
            files = parseModuleFiles(from: relevantArguments)
        }

        set(sourceFiles: files, to: moduleName, modules: &modules)
        set(compilerArgs: compilerArguments, to: moduleName, modules: &modules)
    }

    private func parseModuleFiles(from relevantArguments: [String]) -> [File] {
        var files: [File] = []
        var fileZone: Bool = false
        for arg in relevantArguments {
            if fileZone {
                if arg.hasPrefix("/") {
                    let file = File(path: arg)
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
        while let indexOfOutputMap = args.firstIndex(of: "-output-file-map") {
            args[indexOfOutputMap] = nil
            args[indexOfOutputMap + 1] = nil
        }
        let forbiddenArgs = ["-parseable-output", "-incremental", "-serialize-diagnostics", "-emit-dependencies", "-enforce-exclusivity\\=checked"]
        for (index, arg) in args.enumerated() {
            if forbiddenArgs.contains(arg ?? "") {
                args[index] = nil
            } else if arg == "-O" {
                args[index] = "-Onone"
            } else if arg == "-DNDEBUG=1" {
                args[index] = "-DDEBUG=1"
            } else if arg == "-DDEBUG\\=1" {
                args[index] = "-DDEBUG=1"
            }
        }
        args.append(contentsOf: ["-D", "DEBUG"])
        return args.compactMap { $0 }
    }

    private func parsePlistPhase(line: String, modules: inout MutableModuleDictionary) throws {
        let prefix = line.hasPrefix("Preprocess") ? "Preprocess" : "PlistFile"
        let line = line.replacingEscapedSpaces
        guard let regex = line.match(regex: "\(prefix) (.*) (.*.plist).*cd (.*)").first else {
            return
        }
        let compiledPlistPath = regex.captureGroup(1, originalString: line)
        guard compiledPlistPath.hasSuffix(".plist") else {
            throw logger.fatalError(forMessage: "Plist row has no .plist!\nLine:\n\(line)")
        }
        let plistPath = regex.captureGroup(2, originalString: line)
        let moduleNamePath = URL(fileURLWithPath: compiledPlistPath.removingPlaceholder)
            .deletingLastPathComponent()
            .lastPathComponent
        guard let moduleName = moduleNamePath.components(separatedBy: ".").first else {
            throw logger.fatalError(forMessage: "Failed to extract module name from PlistFile row (unrecognized pattern)\nLine:\n\(line)")
        }
        let file = File(path: plistPath.removingPlaceholder)
        add(plist: file, to: moduleName, modules: &modules)
    }
}

extension SchemeInfoProvider {
    private func set(sourceFiles: [File], to moduleName: String, modules: inout MutableModuleDictionary) {
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.source = sourceFiles
    }

    private func add(plist: File, to moduleName: String, modules: inout MutableModuleDictionary) {
        guard URL(fileURLWithPath: plist.path).lastPathComponent
            .hasPrefix("Preprocessed-") == false else {
            return
        }
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.plists.append(plist)
    }

    private func set(compilerArgs: [String], to moduleName: String, modules: inout MutableModuleDictionary) {
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.args = compilerArgs
    }

    private func registerFoundModuleIfNeeded(_ moduleName: String, modules: inout MutableModuleDictionary) {
        guard modules[moduleName] == nil else {
            return
        }
        let moduleData: MutableModuleData = ([], [], [], modules.count)
        modules[moduleName] = moduleData
    }
}

extension SchemeInfoProvider {
    func markProjectsAsObfuscated() throws -> [File: String] {
        let projects: [Project]
        if isWorkspace {
            projects = try Workspace(workspaceFile: projectFile).xcodeProjFiles()
        } else {
            projects = [Project(xcodeProjFile: projectFile)]
        }
        let tuple: [(File, String)] = try projects.map { ($0.pbxProj, try $0.markAsSwiftShielded()) }
        return Dictionary(uniqueKeysWithValues: tuple)
    }
}

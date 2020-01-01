import Foundation

final class XcodeProjectBuilder {
    let projectToBuild: String
    let schemeToBuild: String
    let modulesToIgnore: Set<String>
    var sdkMode: Bool

    private typealias MutableModuleData = (source: [File], xibs: [File], plists: [File], args: [String])
    private typealias MutableModuleDictionary = OrderedDictionary<String, MutableModuleData>

    var isWorkspace: Bool {
        return projectToBuild.hasSuffix(".xcworkspace")
    }

    init(projectToBuild: String, schemeToBuild: String, modulesToIgnore: Set<String>, sdkMode: Bool) {
        self.projectToBuild = projectToBuild
        self.schemeToBuild = schemeToBuild
        self.modulesToIgnore = modulesToIgnore
        self.sdkMode = sdkMode
    }

    func getModulesAndCompilerArguments() -> [Module] {
        if modulesToIgnore.isEmpty == false {
            Logger.log(.ignoreModules(modules: modulesToIgnore))
        }
        Logger.log(.buildingProject)
        let path = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        var arguments: [String] = [projectParameter, projectToBuild, "-scheme", schemeToBuild]
        if sdkMode {
            arguments += ["-sdk", "iphoneos"]
        }
        let cleanTask = Process()
        cleanTask.launchPath = path
        cleanTask.arguments = ["clean", "build"] + arguments
        let outpipe: Pipe = Pipe()
        cleanTask.standardOutput = outpipe
        cleanTask.standardError = outpipe
        cleanTask.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outdata, encoding: .utf8) else {
            Logger.log(.compilerArgumentsError)
            exit(error: true)
        }
        if cleanTask.terminationStatus != 0 {
            print(output)
            fatalError("It looks like xcodebuild failed which prevents SwiftShield from proceeding. The log was printed above.")
        }
        return parseModulesFrom(xcodeBuildOutput: output)
    }

    func parseModulesFrom(xcodeBuildOutput output: String) -> [Module] {
        let lines = output.components(separatedBy: "\n")
        var modules: MutableModuleDictionary = [:]
        for (index, line) in lines.enumerated() {
            if let moduleName = firstMatch(for: "(?<=-module-name ).*?(?= )", in: line) {
                parseMergeSwiftModulePhase(line: line, moduleName: moduleName, modules: &modules)
            } else if let moduleName = firstMatch(for: "(?<=--module ).*?(?= )", in: line) {
                parseCompileXibPhase(line: line, moduleName: moduleName, modules: &modules)
            } else if line.hasPrefix("ProcessInfoPlistFile") ||
                      line.hasPrefix("CopyPlistFile") ||
                      line.hasPrefix("Preprocess") {
                parsePlistPhase(line: line + lines[index + 1], modules: &modules)
            }
        }
        return modules.filter { modulesToIgnore.contains($0.key) == false }.map {
            Module(name: $0.key,
                   sourceFiles: $0.value.source,
                   xibFiles: $0.value.xibs,
                   plists: $0.value.plists.removeDuplicates(),
                   compilerArguments: $0.value.args)
        }
    }

    private func parseMergeSwiftModulePhase(line: String, moduleName: String, modules: inout MutableModuleDictionary) {
        guard modules[moduleName]?.args.isEmpty != false else {
            return
        }
        guard var fullRelevantArguments = firstMatch(for: "/usr/bin/swiftc.*-module-name \(moduleName) .*", in: line) else {
            print("Fatal: Failed to retrieve \(moduleName) xcodebuild arguments")
            exit(error: true)
        }
        Logger.log(.found(module: moduleName))

        var swiftFileList: File?
        let result = fullRelevantArguments.match(regex: "(?<=@).*SwiftFileList")
        if let pathRange = result.first?.range {
            let nsStr = fullRelevantArguments as NSString
            let fullRange = NSMakeRange(pathRange.location - 1, pathRange.length + 1)
            swiftFileList = File(filePath: nsStr.substring(with: pathRange))
            fullRelevantArguments = nsStr.replacingCharacters(in: fullRange, with: "")
        }

        let relevantArguments = fullRelevantArguments.replacingEscapedSpaces
            .components(separatedBy: " ")
            .map { $0.removingPlaceholder }

        var files: [File]
        var compilerArguments = parseCompilerArguments(from: relevantArguments)

        if let swiftFileList = swiftFileList {
            let swiftFilePaths = swiftFileList.read()
                .components(separatedBy: "\n")
                .filter { !$0.isEmpty }

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
        let line = line.replacingEscapedSpaces
        guard let xibPath = firstMatch(for: "(?=)[^ ]*$", in: line) else {
            return
        }
        guard xibPath.hasSuffix(".xib") || xibPath.hasSuffix(".storyboard") else {
            return
        }
        let file = File(filePath: xibPath.removingPlaceholder)
        add(xib: file, to: moduleName, modules: &modules)
    }

    private func parsePlistPhase(line: String, modules: inout MutableModuleDictionary) {
        let prefix = line.hasPrefix("Preprocess") ? "Preprocess" : "PlistFile"
        let line = line.replacingEscapedSpaces
        guard let regex = line.match(regex: "\(prefix) (.*) (.*.plist) *cd (.*)").first else {
            return
        }
        let compiledPlistPath = regex.captureGroup(1, originalString: line)
        guard compiledPlistPath.hasSuffix(".plist") else {
            Logger.log(.plistError(info: "Plist row has no .plist!\nLine:\n\(line)"))
            exit(error: true)
        }
        let plistPath = regex.captureGroup(2, originalString: line)
        let folder = regex.captureGroup(3, originalString: line)
        let moduleNamePath = URL(fileURLWithPath: compiledPlistPath.removingPlaceholder)
                                .deletingLastPathComponent()
                                .lastPathComponent
        guard let moduleName = moduleNamePath.components(separatedBy: ".").first else {
            Logger.log(.plistError(info: "Failed to extract module name from PlistFile row (unrecognized pattern)\nLine:\n\(line)"))
            exit(error: true)
        }
        let file = File(filePath: folder.removingPlaceholder + "/" + plistPath.removingPlaceholder)
        add(plist: file, to: moduleName, modules: &modules)
    }
}

extension XcodeProjectBuilder {
    private func add(xib: File, to moduleName: String, modules: inout MutableModuleDictionary) {
        registerFoundModuleIfNeeded(moduleName, modules: &modules)
        modules[moduleName]?.xibs.append(xib)
    }

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
        let moduleData: MutableModuleData = ([], [], [], [])
        modules[moduleName] = moduleData
    }
}

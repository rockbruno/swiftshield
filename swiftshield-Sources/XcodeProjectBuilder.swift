import Foundation

struct XcodeProjectBuilder {
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
            exit(1)
        }
        return parseModulesFrom(xcodeBuildOutput: output)
    }

    func parseModulesFrom(xcodeBuildOutput output: String) -> [Module] {
        let lines = output.components(separatedBy: "\n")
        var modules: [Module] = []
        for line in lines {
            guard line.contains("-module-name") else {
                continue
            }
            let moduleName = matches(for: "(?<=-module-name ).*?(?= )", in: line)[0]
            guard modules.contains(where: {$0.name == moduleName}) == false else {
                continue
            }
            Logger.log(.found(module: moduleName))
            let relevantArguments = matches(for: "/usr/bin/swiftc.*-module-name \(moduleName) .*", in: line)[0].components(separatedBy: " ")
            let files = parseModuleFiles(from: relevantArguments)
            let compilerArguments = parseCompilerArguments(from: relevantArguments)
            let module = Module(name: moduleName, files: files, compilerArguments: compilerArguments)
            modules.append(module)
        }
        return modules
    }

    private func parseModuleFiles(from relevantArguments: [String]) -> [File] {
        var files: [File] = []
        var fileZone: Bool = false
        for arg in relevantArguments {
            if fileZone {
                if arg.hasPrefix("/") {
                    files.append(File(filePath: arg))
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
}

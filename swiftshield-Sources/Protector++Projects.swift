//
//  Protector++Projects.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/11/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

fileprivate let pbxProjRegex = ".*"
fileprivate let pbxProjTargetNameRegex = "buildConfigurationList = (.*) \\/\\* .* PBXNativeTarget \"(.*)\""

extension Protector {
    
    func getModulesAndCompilerArguments(scheme: String) -> [Module] {
        Logger.log(.buildingProject)
        let path = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        let arguments: [String] = [projectParameter, projectToBuild, "-scheme", scheme]
        let cleanTask = Process()
        cleanTask.launchPath = path
        cleanTask.arguments = ["clean"] + arguments
        cleanTask.standardOutput = nil
        cleanTask.standardError = nil
        cleanTask.launch()
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outdata, encoding: .utf8) else {
            Logger.log(.compilerArgumentsError)
            exit(1)
        }
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
            var compilerArguments: [String] = []
            let fullCall = line.components(separatedBy: " ")
            var startRetrievingArguments = false
            var ignoreNext = false
            var files: [File] = []
            var fileZone: Bool = false
            for arg in fullCall {
                guard startRetrievingArguments else {
                    startRetrievingArguments = arg.contains("bin/swiftc")
                    continue
                }
                guard ignoreNext == false else {
                    ignoreNext = false
                    continue
                }
                if fileZone {
                    if arg.hasPrefix("/") {
                        files.append(File(filePath: arg))
                    }
                    fileZone = arg.hasPrefix("-") == false || files.count == 0
                } else {
                    fileZone = arg == "-c"
                }
                if arg == "-incremental" || arg == "-parseable-output" || arg == "-serialize-diagnostics" || arg == "-emit-dependencies" {
                    continue
                } else if arg == "-output-file-map" {
                    ignoreNext = true
                    continue
                } else if arg == "-o" {
                    break
                } else if arg == "-frontend" {
                    compilerArguments.append( "-Xfrontend" )
                    compilerArguments.append( "-j4" )
                } else {
                    compilerArguments.append(arg)
                }
            }
            modules.append(Module(name: moduleName, files: files, compilerArguments: compilerArguments))
        }
        return modules
    }
    
    func markAsProtected(projectPaths: [String]) {
        Logger.log(.taggingProjects)
        let targetLine = "PRODUCT_NAME ="
        let injectedLine = "SWIFTSHIELDED = true;"
        for projectPath in projectPaths {
            let path = projectPath+"/project.pbxproj"
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                var shouldInject = true
                let matches = data.match(regex: pbxProjRegex)
                let newProject = matches.flatMap { result in
                    let currentLine = (data as NSString).substring(with: result.rangeAt(0))
                    guard shouldInject else {
                        return currentLine + "\n"
                    }
                    if currentLine.contains(injectedLine) {
                        shouldInject = false
                    } else if currentLine.contains(targetLine) {
                        return "\t\t" + injectedLine + "\n" + currentLine + "\n"
                    }
                    return currentLine + "\n"
                }.joined()
                try newProject.write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            } catch {
                Logger.log(.fatal(error: error.localizedDescription))
                exit(error: true)
            }
        }
    }
}

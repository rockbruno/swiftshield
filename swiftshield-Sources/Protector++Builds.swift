//
//  Protector++Builds.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/12/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Foundation

extension Protector {
    func getSchemes() -> [String] {
        Logger.log("Getting schemes")
        let path = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        let arguments: [String] = ["-list", projectParameter, projectToBuild]
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        var output = String(data: outdata, encoding: .utf8)?.components(separatedBy: "Schemes:")
        output?.remove(at: 0)
        output = output![0].replacingOccurrences(of: "\n", with: "").components(separatedBy: "        ")
        output?.remove(at: 0)
        return output!
    }
    
    func runFakeBuild(scheme: String) -> String {
        Logger.log("Performing fake build to detect class references. This can take a few minutes...")
        let path = "/usr/bin/xcodebuild"
        let projectParameter = isWorkspace ? "-workspace" : "-project"
        let arguments: [String] = ["-quiet", projectParameter, projectToBuild, "-scheme", scheme]
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        let outpipe: Pipe = Pipe()
        task.standardOutput = outpipe
        task.standardError = nil
        task.launch()
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outdata, encoding: .utf8)
        return output!
    }
    
    func parse(fakeBuildOutput: String) -> [File:[ErrorData]] {
        let errorRegex = "/.* error:.*'.*'"
        func regexMapClosure(fromData nsString: NSString) -> RegexClosure {
            return { result in
                return nsString.substring(with: result.rangeAt(0))
            }
        }
        let data = fakeBuildOutput.matchRegex(regex: errorRegex, mappingClosure: regexMapClosure(fromData: fakeBuildOutput as NSString))
        var errorDataHash: BuildOutput = BuildOutput()
        for error in data {
            guard let errorData = ErrorData(fullError: error), errorData.file.name.contains(".swift") else {
                continue
            }
            if let lastError = errorDataHash[errorData.file]?.last, errorData.line == lastError.line && errorData.column == lastError.column {
                continue
            }
            errorDataHash[errorData.file] == nil ? errorDataHash[errorData.file] = [errorData] : errorDataHash[errorData.file]!.append(errorData)
            if errorData.isModuleHasNoMemberError {
                errorDataHash[errorData.file]?.append(ErrorData(file: errorData.file, line: errorData.line, column: errorData.column + errorData.target.characters.count + 1))
            }
        }
        return errorDataHash
    }
}

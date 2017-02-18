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
    func markAsProtected(projectPaths: [String]) {
        let targetLine = "PRODUCT_NAME ="
        let injectedLine = "SWIFTSHIELDED = true;"
        for projectPath in projectPaths {
            let path = projectPath+"/project.pbxproj"
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                var shouldInject = true
                let newProject = data.matchRegex(regex: pbxProjRegex) { result in
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
                Logger.log("FATAL: \(error.localizedDescription)")
                exit(error: true)
            }
        }
    }
    
    func retrieveModuleNames(projectPaths: [String]) -> [String] {
        var moduleNames: [String] = []
        for projectPath in projectPaths {
            let data = try! String(contentsOfFile: projectPath+"/project.pbxproj", encoding: .utf8)
            let idToTargetNameDict = getTargetsIdAndNameDict(data: data)
            let configurationIdToTargetIdDict = getConfigurationIdToTargetIdDict(data: data)
            let names = getModuleNames(data: data, idTargetDict: idToTargetNameDict, configIdTargetIdDict: configurationIdToTargetIdDict)
            moduleNames.append(contentsOf: names)
        }
        return moduleNames.map{$0.replacingOccurrences(of: " ", with: "_")}.removeDuplicates()
    }
    
    fileprivate func getTargetsIdAndNameDict(data: String) -> [String:String] {
        let results = data.matchRegex(regex: pbxProjTargetNameRegex) { result in
            guard result.numberOfRanges == 3 else {
                return nil
            }
            let id = (data as NSString).substring(with: result.rangeAt(1))
            let target = (data as NSString).substring(with: result.rangeAt(2))
            return "\(id)|\(target)"
        }
        var dict: [String:String] = [:]
        for result in results {
            let data = result.components(separatedBy: "|")
            dict[data[0]] = data[1]
        }
        return dict
    }
    
    fileprivate func getConfigurationIdToTargetIdDict(data: String) -> [String:String] {
        var configurationIdToTargetId: [String:String] = [:]
        var listenToConfigId = false
        var currentTargetId = ""
        var shouldMap = false
        _ = data.matchRegex(regex: pbxProjRegex) { result in
            let currentLine = (data as NSString).substring(with: result.rangeAt(0))
            if shouldMap == false {
                shouldMap = currentLine.contains("Begin XCConfigurationList section")
                return currentLine
            }
            if currentLine.contains("/*") {
                if currentLine.contains("Build configuration list for") {
                    listenToConfigId = true
                    currentTargetId = currentLine.components(separatedBy: "/*")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else if currentLine.contains("End") && listenToConfigId {
                    listenToConfigId = false
                } else {
                    let configId = currentLine.components(separatedBy: "/*")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    configurationIdToTargetId[configId] = currentTargetId
                }
            }
            return currentLine
        }
        return configurationIdToTargetId
    }
    
    fileprivate func getModuleNames(data: String, idTargetDict: [String:String], configIdTargetIdDict: [String:String]) -> [String] {
        let productModuleLine = "PRODUCT_MODULE_NAME = "
        let productNameLine = "PRODUCT_NAME = "
        let buildSettingsSection = "XCBuildConfiguration section"
        var configId = ""
        var listenToTargetId = false
        var previousLine = ""
        var moduleNames: [String] = []
        _ = data.matchRegex(regex: pbxProjRegex) { result in
            var currentLine = (data as NSString).substring(with: result.rangeAt(0))
            guard currentLine != "" else {
                return nil
            }
            defer { previousLine = currentLine }
            if currentLine.contains(buildSettingsSection) {
                listenToTargetId = currentLine.contains("Begin")
            } else if listenToTargetId {
                let foundTarget = currentLine.contains("/*") && currentLine.contains("= {")
                if foundTarget {
                    configId = currentLine.components(separatedBy: "/*")[0].noSpaces
                }
            }
            if currentLine.contains(productModuleLine) {
                let targetName = currentLine.components(separatedBy: productModuleLine)[1].components(separatedBy: ";")[0]
                moduleNames.append(targetName)
            } else if currentLine.contains(productNameLine) && previousLine.contains(productModuleLine) == false {
                let productName = currentLine.replacingOccurrences(of: productNameLine, with: "").replacingOccurrences(of: ";", with: "").noSpaces
                if productName.contains("$") == false {
                    moduleNames.append(productName)
                } else if let targetName = idTargetDict[configIdTargetIdDict[configId]!] {
                    moduleNames.append(targetName)
                }
            }
            return nil
        }
        return moduleNames
    }
}

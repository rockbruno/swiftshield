//
//  Protector++Modules.swift
//  swiftshield
//
//  Created by Bruno Rocha on 2/11/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

extension Protector {
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
        let pbxProjTargetNameRegex = "buildConfigurationList = (.*) \\/\\* .* PBXNativeTarget \"(.*)\""
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
        let pbxProjRegex = ".*"
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
        let pbxProjRegex = ".*"
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

//MARK: Consultation
//This ugly method obfuscate module names. It works for your project, but it breaks your build because it's not this simple to change Framework module names. Need to fix this later on.

/*
 func retrieveModuleNames(projectPaths: [String]) -> [String] {
 let pbxProjTargetNameRegex = "buildConfigurationList = (.*) \\/\\* .* PBXNativeTarget \"(.*)\""
 let pbxProjRegex = ".*"
 Logger.log("Obfuscating Modules")
 for projectPath in projectPaths {
 var idToTargetNameHash: [String:String] = [:]
 //Getting target names first based on their ID
 let data = try! String(contentsOfFile: projectPath+"/project.pbxproj", encoding: .utf8)
 _ = data.matchRegex(regex: pbxProjTargetNameRegex) { result in
 guard result.numberOfRanges == 3 else {
 return ""
 }
 let id = (data as NSString).substring(with: result.rangeAt(1))
 let target = (data as NSString).substring(with: result.rangeAt(2))
 idToTargetNameHash[id] = target
 Logger.log("Found module \(target)")
 return ""
 }
 var configurationIdToTargetId: [String:String] = [:]
 var listenToConfigId = false
 var currentTargetId = ""
 var shouldMap = false
 //Mapping build configuration ids to its target ID
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
 //Replacing
 let spacing = "\t\t"
 let productModuleLine = "PRODUCT_MODULE_NAME = "
 let productNameLine = "PRODUCT_NAME = "
 let buildSettingsSection = "XCBuildConfiguration section"
 var configId = ""
 var listenToTargetId = false
 var previousLine = ""
 let newProj = data.matchRegex(regex: pbxProjRegex) { result in
 var currentLine = (data as NSString).substring(with: result.rangeAt(0))
 guard currentLine != "" else {
 return currentLine + "\n"
 }
 defer { previousLine = currentLine }
 if currentLine.contains(buildSettingsSection) {
 listenToTargetId = currentLine.contains("Begin")
 } else if listenToTargetId {
 let foundTarget = currentLine.contains("/*") && currentLine.contains("= {")
 if foundTarget {
 configId = currentLine.components(separatedBy: "/*")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
 }
 }
 if currentLine.contains(productModuleLine) {
 let targetName = currentLine.components(separatedBy: productModuleLine)[1].components(separatedBy: ";")[0]
 if protectionHash.hash[targetName] == nil {
 protectionHash.hash[targetName] = String.random(length: protectedClassNameSize)
 }
 let newName = protectionHash.hash[targetName]!
 if newName != targetName {
 currentLine = currentLine.replacingOccurrences(of: targetName, with: protectionHash.hash[targetName] ?? targetName)
 Logger.log("\(targetName) -> \(newName) (Target had a custom module name)")
 }
 } else if currentLine.contains(productNameLine) && previousLine.contains(productModuleLine) == false {
 var productName = currentLine.replacingOccurrences(of: productNameLine, with: "").replacingOccurrences(of: ";", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
 if productName.contains("$") == false {
 if protectionHash.hash[productName] == nil {
 protectionHash.hash[productName] = String.random(length: protectedClassNameSize)
 }
 Logger.log("\(productName) -> \(protectionHash.hash[productName]!)")
 currentLine = currentLine.replacingOccurrences(of: productName, with: protectionHash.hash[productName]!)
 } else if let targetName = idToTargetNameHash[configurationIdToTargetId[configId]!] {
 if protectionHash.hash[targetName] == nil {
 protectionHash.hash[targetName] = String.random(length: protectedClassNameSize)
 }
 productName = protectionHash.hash[targetName] ?? targetName
 Logger.log("\(targetName) -> \(productName)")
 currentLine = spacing + productModuleLine + productName + ";\n" + currentLine
 }
 }
 return currentLine + "\n"
 }.joined()
 try! newProj.write(toFile: projectPath+"/project.pbxproj", atomically: false, encoding: String.Encoding.utf8)
 }
 return protectionHash
 }
 }
 */*/*/*/*/*/

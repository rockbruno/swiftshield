//
//  AuomaticSwiftShield.swift
//  swiftshield
//
//  Created by Bruno Rocha on 4/20/17.
//  Copyright © 2017 Bruno Rocha. All rights reserved.
//

import Cocoa

let mainScheme = UserDefaults.standard.string(forKey: "scheme") ?? ""
let projectToBuild = UserDefaults.standard.string(forKey: "projectfile") ?? ""
let isWorkspace = projectToBuild.hasSuffix(".xcworkspace")

struct AutomaticSwiftShield {
    func protect() {
        guard basePath.isEmpty == false && mainScheme.isEmpty == false && projectToBuild.isEmpty == false else {
            Logger.log(.helpText)
            exit(error: true)
            return
        }
        
        if isWorkspace == false && projectToBuild.hasSuffix(".xcodeproj") == false {
            Logger.log(.projectError)
            exit(error: true)
        }
        
        let protector = Protector()
        
        let modules = protector.getModulesAndCompilerArguments(scheme: mainScheme)
        let obfuscationData = protector.index(modules: modules)
        if obfuscationData.obfuscationDict.isEmpty {
            Logger.log(.foundNothingError)
            exit(error: true)
        }
        
        protector.obfuscateReferences(obfuscationData: obfuscationData)
        
        protector.protectStoryboards(data: obfuscationData)
        
        let projects = findFiles(rootPath: basePath, suffix: ".xcodeproj", ignoreDirs: false) ?? []
        
        protector.markAsProtected(projectPaths: projects)
        protector.writeToFile(data: obfuscationData)
        
        Logger.log(.finished)
        
        exit()
    }
}

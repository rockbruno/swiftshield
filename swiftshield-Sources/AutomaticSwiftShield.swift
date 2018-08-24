import Foundation

class AutomaticSwiftShield: Protector {

    let projectToBuild: String
    let schemeToBuild: String
    let modulesToIgnore: Set<String>

    var isWorkspace: Bool {
        return projectToBuild.hasSuffix(".xcworkspace")
    }

    init(basePath: String,
         projectToBuild: String,
         schemeToBuild: String,
         modulesToIgnore: Set<String>,
         protectedClassNameSize: Int) {
        self.projectToBuild = projectToBuild
        self.schemeToBuild = schemeToBuild
        self.modulesToIgnore = modulesToIgnore
        super.init(basePath: basePath, protectedClassNameSize: protectedClassNameSize)
        if self.schemeToBuild.isEmpty || self.projectToBuild.isEmpty {
            Logger.log(.helpText)
            exit(error: true)
        }
    }

    override func protect() -> ObfuscationData {
        guard isWorkspace || projectToBuild.hasSuffix(".xcodeproj") else {
            Logger.log(.projectError)
            exit(error: true)
        }
        let projectBuilder = XcodeProjectBuilder(projectToBuild: projectToBuild, schemeToBuild: schemeToBuild, modulesToIgnore: modulesToIgnore)
        let modules = projectBuilder.getModulesAndCompilerArguments()
        let obfuscationData = getObfuscationData(from: modules)
        index(modules: modules, obfuscationData: obfuscationData)
        findReferencesInIndexed(obfuscationData: obfuscationData)
        if obfuscationData.referencesDict.isEmpty {
            Logger.log(.foundNothingError)
            exit(error: true)
        }
        overwriteFiles(obfuscationData: obfuscationData)
        return obfuscationData
    }

    func getObfuscationData(from modules: [Module]) -> ObfuscationData {
        let obfuscationData = ObfuscationData()
        obfuscationData.storyboardsToObfuscate = modules.flatMap { $0.xibFiles }
        obfuscationData.moduleNames = Set(modules.compactMap { $0.name })
        return obfuscationData
    }

    func index(modules: [Module], obfuscationData: ObfuscationData) {
        let sourceKit = SourceKit()
        var fileDataArray: [(file: File, module: Module)] = []
        for module in modules {
            for file in module.sourceFiles {
                fileDataArray.append((file, module))
            }
        }
        for fileData in fileDataArray {
            let file = fileData.file
            let module = fileData.module
            let compilerArgs = sourceKit.array(argv: module.compilerArguments)
            Logger.log(.indexing(file: file))
            let resp = index(sourceKit: sourceKit, file: file, args: compilerArgs)
            let dict = SKApi.sourcekitd_response_get_value(resp)
            sourceKit.recurseOver(childID: sourceKit.entitiesID, resp: dict) { [unowned self] dict in
                guard let data = self.getNameData(from: dict,
                                                  obfuscationData: obfuscationData,
                                                  sourceKit: sourceKit) else {
                                                    return
                }
                let name = data.name
                let usr = data.usr
                obfuscationData.usrDict.insert(usr)
                if dict.getString(key: sourceKit.receiverID) == nil {
                    obfuscationData.usrRelationDict[usr] = dict
                }
                Logger.log(.foundDeclaration(name: name, usr: usr))
            }
            obfuscationData.indexedFiles.append((file, resp))
        }
    }
}

extension AutomaticSwiftShield {
    private func index(sourceKit: SourceKit, file: File, args: sourcekitd_object_t) -> sourcekitd_response_t {
        let resp = sourceKit.indexFile(filePath: file.path, compilerArgs: args)
        if let error = sourceKit.error(resp: resp) {
            Logger.log(.indexError(file: file, error: error))
            exit(error: true)
        }
        return resp
    }

    private func getNameData(from dict: sourcekitd_variant_t, obfuscationData: ObfuscationData, sourceKit: SourceKit) -> (name: String, usr: String, obfuscatedName: String)? {
        let kind = dict.getUUIDString(key: sourceKit.kindID)
        guard sourceKit.declarationType(for: kind) != nil else {
            return nil
        }
        guard let name = dict.getString(key: sourceKit.nameID)?.trueName, let usr = dict.getString(key: sourceKit.usrID) else {
            return nil
        }
        guard let protected = obfuscationData.obfuscationDict[name] else {
            let newName = String.random(length: self.protectedClassNameSize, excluding: obfuscationData.allObfuscatedNames)
            obfuscationData.obfuscationDict[name] = newName
            obfuscationData.allObfuscatedNames.insert(newName)
            return (name, usr, newName)
        }
        return (name, usr, protected)
    }

    func findReferencesInIndexed(obfuscationData: ObfuscationData) {
        let SK = SourceKit()
        Logger.log(.searchingReferencesOfUsr)
        for (file, indexResponse) in obfuscationData.indexedFiles {
            print("HERE")
            let dict = SKApi.sourcekitd_response_get_value(indexResponse)
            SK.recurseOver(childID: SK.entitiesID, resp: dict, block: { dict in
                let kind = dict.getUUIDString(key: SK.kindID)
                guard let type = SK.referenceType(kind: kind) else {
                    return
                }
                guard let usr = dict.getString(key: SK.usrID), let name = dict.getString(key: SK.nameID)?.trueName else {
                    return
                }
                let line = dict.getInt(key: SK.lineID)
                let column = dict.getInt(key: SK.colID)
                if obfuscationData.usrDict.contains(usr) {
                    //Operators only get indexed as such if they are declared in a global scope
                    //Unfortunately, most people use public static func
                    //So we avoid obfuscating methods with small names to prevent obfuscating operators.
                    if type == .method && name.count <= 4 {
                        return
                    }
                    guard self.isReferencingInternal(type: type, kind: kind, dict: dict, obfuscationData: obfuscationData, sourceKit: SK) == false else {
                        return
                    }
                    let newName = obfuscationData.obfuscationDict[name] ?? name
                    Logger.log(.foundReference(name: name, usr: usr, at: file, line: line, column: column, newName: newName))
                    let reference = ReferenceData(name: name, line: line, column: column)
                    obfuscationData.referencesDict[file, default: []].append(reference)
                }
            })
        }
    }

    private func isReferencingInternal(type: SourceKit.DeclarationType, kind: String, dict: sourcekitd_variant_t, obfuscationData: ObfuscationData, sourceKit: SourceKit) -> Bool {
        guard type == .method || type == .property else {
            return false
        }
        guard let usr = dict.getString(key: sourceKit.usrID) else {
            return false
        }
        if let relDict = obfuscationData.usrRelationDict[usr], relDict.data != dict.data {
            return isReferencingInternal(type: type, kind: kind, dict: relDict, obfuscationData: obfuscationData, sourceKit: sourceKit)
        }
        var isReference = false
        sourceKit.recurseOver(childID: sourceKit.relatedID, resp: dict) { dict in
            guard isReference == false else {
                return
            }
            guard let usr = dict.getString(key: sourceKit.usrID) else {
                return
            }
            if obfuscationData.usrDict.contains(usr) == false {
                isReference = true
            } else if let relDict = obfuscationData.usrRelationDict[usr] {
                isReference = self.isReferencingInternal(type: type, kind: kind, dict: relDict, obfuscationData: obfuscationData, sourceKit: sourceKit)
            }
        }
        return isReference
    }

    func overwriteFiles(obfuscationData: ObfuscationData) {
        for (file,references) in obfuscationData.referencesDict {
            Logger.log(.overwriting(file: file))
            let data = try! String(contentsOfFile: file.path, encoding: .utf8)
            let obfuscatedFile = generateObfuscatedFile(fromString: data, references: references, obfuscationData: obfuscationData)
            do {
                try obfuscatedFile.write(toFile: file.path, atomically: false, encoding: .utf8)
            } catch {
                Logger.log(.fatal(error: error.localizedDescription))
                exit(error: true)
            }
        }
    }

    func generateObfuscatedFile(fromString data: String, references: [ReferenceData], obfuscationData: ObfuscationData) -> String {
        var sortedReferences = references.filterDuplicates { $0.line == $1.line && $0.column == $1.column }.sorted(by: lesserPosition)
        var currentReference = 0
        var line = 1
        var column = 1
        var charArray = Array(data).map(String.init)
        var currentCharIndex = 0
        while currentCharIndex < charArray.count && currentReference < sortedReferences.count {
            let reference = sortedReferences[currentReference]
            if line == reference.line && column == reference.column {
                let originalName = reference.name
                let word = obfuscationData.obfuscationDict[originalName] ?? originalName
                let wasInternalKeyword = charArray[currentCharIndex] == "`"
                for i in 1..<(originalName.count + (wasInternalKeyword ? 2 : 0)) {
                    charArray[currentCharIndex + i] = ""
                }
                charArray[currentCharIndex] = word
                currentReference += 1
                currentCharIndex += originalName.count
                column += originalName.count
                if wasInternalKeyword {
                    charArray[currentCharIndex] = ""
                }
            } else if charArray[currentCharIndex] == "\n" {
                line += 1
                column = 1
                currentCharIndex += 1
            } else {
                column += 1
                currentCharIndex += 1
            }
        }
        return charArray.joined()
    }
}

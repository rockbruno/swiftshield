import Foundation

class AutomaticSwiftShield: Protector {

    let sourceKit: SourceKit
    let projectToBuild: String
    let schemeToBuild: String
    let modulesToIgnore: Set<String>
    let sdkMode: Bool

    var isWorkspace: Bool {
        return projectToBuild.hasSuffix(".xcworkspace")
    }

    init(basePath: String,
         projectToBuild: String,
         schemeToBuild: String,
         modulesToIgnore: Set<String>,
         protectedClassNameSize: Int,
         dryRun: Bool,
         sdkMode: Bool,
         sourceKit: SourceKit = .init()) {
        self.sourceKit = sourceKit
        self.projectToBuild = projectToBuild
        self.schemeToBuild = schemeToBuild
        self.modulesToIgnore = modulesToIgnore
        self.sdkMode = sdkMode
        super.init(basePath: basePath, protectedClassNameSize: protectedClassNameSize, dryRun: dryRun)
        if self.schemeToBuild.isEmpty || self.projectToBuild.isEmpty {
            Logger.log(.helpText)
            exit(error: true)
        }
    }

    override func protect() -> ObfuscationData {
        SourceKit.start()
        defer {
            SourceKit.stop()
        }
        guard isWorkspace || projectToBuild.hasSuffix(".xcodeproj") else {
            Logger.log(.projectError)
            exit(error: true)
        }
        let projectBuilder = XcodeProjectBuilder(projectToBuild: projectToBuild, schemeToBuild: schemeToBuild, modulesToIgnore: modulesToIgnore, sdkMode: sdkMode)
        let modules = projectBuilder.getModulesAndCompilerArguments()
        let obfuscationData = AutomaticObfuscationData(modules: modules)
        index(obfuscationData: obfuscationData)
        findReferencesInIndexed(obfuscationData: obfuscationData)
        if obfuscationData.referencesDict.isEmpty {
            Logger.log(.foundNothingError)
            exit(error: true)
        }
        obfuscateNSPrincipalClassPlists(obfuscationData: obfuscationData)
        if dryRun == false {
            overwriteFiles(obfuscationData: obfuscationData)
        }
        return obfuscationData
    }

    func index(obfuscationData: AutomaticObfuscationData) {
        var fileDataArray: [(file: File, module: Module)] = []
        for module in obfuscationData.modules {
            for file in module.sourceFiles {
                fileDataArray.append((file, module))
            }
        }
        for fileData in fileDataArray {
            let file = fileData.file
            let module = fileData.module
            Logger.log(.indexing(file: file))
            let resp = index(file: file, args: module.compilerArguments)
            resp.recurseOver(uid: .entitiesId) { [unowned self] variant in
                let dict = variant.getDictionary()
                if self.sdkMode && self.isPublicOpenAttribute(from: dict) {
                    return
                }
                
                guard let data = self.getNameData(from: dict,
                                                  obfuscationData: obfuscationData) else {
                                                    return
                }
                let name = data.name
                let usr = data.usr
                obfuscationData.usrDict.insert(usr)
                if dict.getString(.receiverId) == nil {
                    obfuscationData.usrRelationDict[usr] = variant
                }
                Logger.log(.foundDeclaration(name: name, usr: usr))
            }
            obfuscationData.indexedFiles.append((file, resp))
        }
    }

    override func writeToFile(data: ObfuscationData) {
        var path = "\(schemeToBuild)"
        for plist in (data as? AutomaticObfuscationData)?.mainModule?.plists ?? [] {
            guard let version = getPlistVersionAndNumber(plist) else {
                continue
            }
            path += " \(version.0) \(version.1)"
            break
        }
        writeToFile(data: data, path: path, info: "Automatic mode for \(path)")
    }
}

extension AutomaticSwiftShield {
    private func index(file: File, args: [String]) -> SourceKitdResponse {
        let resp = sourceKit.indexFile(filePath: file.path, compilerArgs: args)
        if let error = resp.error {
            Logger.log(.indexError(file: file, error: error))
            exit(error: true)
        }
        return resp
    }
    
    private func isPublicOpenAttribute(from dict: SourceKitdResponse.Dictionary) -> Bool {
        guard let attributes = dict.getArray(.attributesId) else {
            return false
        }
        if attributes.count > 0 {
            let attr = attributes.getDictionary(0).getUID(.attributeId)
            return (attr.asString == SwiftAccessControl.public.rawValue ||
                attr.asString == SwiftAccessControl.open.rawValue)
        }
        
        return false
    }

    private func getNameData(from dict: SourceKitdResponse.Dictionary,
                             obfuscationData: ObfuscationData) -> (name: String,
                                                                   usr: String,
                                                                   obfuscatedName: String)? {
        let kind = dict.getUID(.kindId).asString
        guard sourceKit.declarationType(for: kind) != nil else {
            return nil
        }
        guard let name = dict.getString(.nameId)?.trueName, let usr = dict.getString(.usrId) else {
            return nil
        }

        guard let protected = obfuscationData.obfuscationDict[name] else {
            let newName = String.random(length: self.protectedClassNameSize, excluding: obfuscationData.allObfuscatedNames)
            obfuscationData.obfuscationDict[name] = newName
            return (name, usr, newName)
        }
        return (name, usr, protected)
    }

    func findReferencesInIndexed(obfuscationData: AutomaticObfuscationData) {
        Logger.log(.searchingReferencesOfUsr)
        for (file, response) in obfuscationData.indexedFiles {
            response.recurseOver(uid: .entitiesId) { [unowned self] variant in
                let dict = variant.getDictionary()
                let kind = dict.getUID(.kindId).asString
                guard let type = self.sourceKit.referenceType(kind: kind) else {
                    return
                }
                guard let usr = dict.getString(.usrId), let name = dict.getString(.nameId)?.trueName else {
                    return
                }
                let line = dict.getInt(.lineId)
                let column = dict.getInt(.colId)
                guard obfuscationData.usrDict.contains(usr) else {
                    return
                }
                //Operators only get indexed as such if they are declared in a global scope
                //Unfortunately, most people use public static func
                //So we avoid obfuscating methods with small names to prevent obfuscating operators.
                if type == .method && name.count <= 4 {
                    return
                }
                guard self.isReferencingInternal(type: type, kind: kind, variant: variant, obfuscationData: obfuscationData) == false else {
                    return
                }
                let newName = obfuscationData.obfuscationDict[name] ?? name
                Logger.log(.foundReference(name: name,
                                           usr: usr,
                                           at: file,
                                           line: line,
                                           column: column,
                                           newName: newName))
                let reference = ReferenceData(name: name, line: line, column: column)
                obfuscationData.referencesDict[file, default: []].append(reference)
            }
        }
    }

    private func isReferencingInternal(type: SourceKit.DeclarationType,
                                       kind: String,
                                       variant: SourceKitdResponse.Variant,
                                       obfuscationData: AutomaticObfuscationData) -> Bool {
        guard type == .method || type == .property else {
            return false
        }
        guard let usr = variant.getDictionary().getString(.usrId) else {
            return false
        }
        if let relDict = obfuscationData.usrRelationDict[usr], relDict.val.data != variant.val.data {
            return isReferencingInternal(type: type,
                                         kind: kind,
                                         variant: relDict,
                                         obfuscationData: obfuscationData)
        }
        var isReference = false
        variant.recurseOver(uid: .relatedId) { [unowned self] variant in
            guard isReference == false else {
                return
            }
            let dict = variant.getDictionary()
            guard let usr = dict.getString(.usrId) else {
                return
            }
            if obfuscationData.usrDict.contains(usr) == false {
                isReference = true
            } else if let relDict = obfuscationData.usrRelationDict[usr] {
                isReference = self.isReferencingInternal(type: type,
                                                         kind: kind,
                                                         variant: relDict,
                                                         obfuscationData: obfuscationData)
            }
        }
        return isReference
    }

    func overwriteFiles(obfuscationData: AutomaticObfuscationData) {
        for (file,references) in obfuscationData.referencesDict {
            Logger.log(.overwriting(file: file))
            let data = file.read()
            let obfuscatedFile = generateObfuscatedFile(fromString: data, references: references, obfuscationData: obfuscationData)
            file.write(obfuscatedFile)
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

    func obfuscateNSPrincipalClassPlists(obfuscationData: AutomaticObfuscationData) {
        for plist in obfuscationData.plists {
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: plist.path)),
                  let xmlDoc = try? AEXMLDocument(xml: data, options: AEXMLOptions()) else {
                Logger.log(.plistError(info: "Failed to open \(plist.path)"))
                exit(error: true)
            }
            obfuscateNSPrincipalClass(plistXml: xmlDoc, obfuscationData: obfuscationData)
            plist.write(xmlDoc.xml)
        }
    }

    private func obfuscateNSPrincipalClass(plistXml: AEXMLElement, obfuscationData: AutomaticObfuscationData) {
        let children = plistXml.children
        for i in 0..<children.count {
            if children[i].value == "NSExtensionPrincipalClass" ||
               children[i].value == "WKExtensionDelegateClassName" ||
               children[i].value == "CLKComplicationPrincipalClass" {
                let moduleName = "$(PRODUCT_MODULE_NAME)"
                let currentName = (children[i+1].value ?? "")
                                  .components(separatedBy: "\(moduleName).")
                                  .last ?? ""
                let protectedName = obfuscationData.obfuscationDict[currentName] ?? currentName
                children[i+1].value = moduleName + "." + protectedName
            } else {
                obfuscateNSPrincipalClass(plistXml: children[i], obfuscationData: obfuscationData)
            }
        }
    }

    func getPlistVersionAndNumber(_ plist: File) -> (String, String)? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: plist.path)),
              let xmlDoc = try? AEXMLDocument(xml: data, options: AEXMLOptions()) else {
            Logger.log(.plistError(info: "Failed to open \(plist.path)"))
            exit(error: true)
        }
        guard let children = xmlDoc.root.children.first?.children else {
            return nil
        }
        var shortVersion: String? = ""
        var version: String? = ""
        for i in 0..<children.count {
            if children[i].value == "CFBundleShortVersionString" {
                shortVersion = children[i+1].value ?? ""
            } else if children[i].value == "CFBundleVersion" {
                version = children[i+1].value ?? ""
            }
        }
        guard let shortVer = shortVersion, let ver = version else {
            return nil
        }
        return (shortVer, ver)
    }
}

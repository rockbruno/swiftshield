
import SwiftSyntax
import Foundation

final class SourceKitObfuscator: ObfuscatorProtocol {
    let sourceKit: SourceKit
    let logger: LoggerProtocol
    let dataStore: SourceKitObfuscatorDataStore
    let ignorePublic: Bool
    let namesToIgnore: Set<String>
    let namesToEnforce: Set<String>
    weak var delegate: ObfuscatorDelegate?

    private lazy var rewriter = RenameRewriter(names: namesToEnforce, logger: logger) { [weak self] in
        self?.obfuscate(name: $0)
    }

    init(sourceKit: SourceKit, logger: LoggerProtocol, dataStore: SourceKitObfuscatorDataStore, namesToIgnore: Set<String>, namesToEnforce: Set<String>, ignorePublic: Bool) {
        self.sourceKit = sourceKit
        self.logger = logger
        self.dataStore = dataStore
        self.ignorePublic = ignorePublic
        self.namesToIgnore = namesToIgnore
        self.namesToEnforce = namesToEnforce
    }

    var requests: sourcekitd_requests! {
        sourceKit.requests
    }

    var keys: sourcekitd_keys! {
        sourceKit.keys
    }
}

// MARK: Indexing

extension SourceKitObfuscator {
    func registerModuleForObfuscation(_ module: Module) throws {
        logger.log("\n\n========== \(module.name) ==========")
        let compilerArguments = SKRequestArray(sourcekitd: sourceKit)
        module.compilerArguments.forEach(compilerArguments.append(_:))
        do {
            try module.sourceFiles.sorted { $0.path < $1.path }.forEach { file in
                logger.log("--- Indexing: \(file.name)")
                let req = SKRequestDictionary(sourcekitd: sourceKit)
                req[keys.request] = requests.indexsource
                req[keys.sourcefile] = file.path
                req[keys.compilerargs] = compilerArguments
                let response = try sourceKit.sendSync(req)
                logger.log("--- Preprocessing indexing result of: \(file.name)")
//                if file.name == "HomeFlowViewProviding.swift" {
//                    print("======= RESPONSE ======")
//                    dump(response)
//                    print("======= END OF RESPONSE ======")
//                }
                response.recurseEntities { [unowned self] dict in
//                    if file.name == "DashboardFlowCoordinator.swift" {
//                        print(dict)
//                    }
                    self.preprocess(declarationEntity: dict, ofFile: file, fromModule: module)
                }
                logger.log("--- Processing indexing result of: \(file.name)")
                response.recurseEntities { [unowned self] dict in
//                    if file.name == "DashboardFlowCoordinator.swift" {
//                        print(dict)
//                    }
                    if self.ignorePublic, dict.isPublic {
                        return
                    }
                    do {
                        try self.process(declarationEntity: dict, ofFile: file, fromModule: module)
                    } catch {
                        print("❌ SourceKit request error: \(error)")
                    }
                }
                let indexedFile = IndexedFile(file: file, response: response)
                self.dataStore.indexedFiles.append(indexedFile)
            }
        } catch {
            print("❌ SourceKit request error: \(error)")
        }
        dataStore.plists = dataStore.plists.union(module.plists)
    }

    func preprocess(
        declarationEntity dict: SKResponseDictionary,
        ofFile file: File,
        fromModule module: Module
    ) {
        guard let usr: String = dict[keys.usr] else {
            let kind = dict[keys.kind] ?? "unknown"
            let name = dict[keys.name] ?? "unknown"
            logger.log("* --- Ignoring: kind: \(kind) | name: \(name) : usr invalid", verbose: true)
            return
        }
        dataStore.fileForUSR[usr] = file
    }

    func process(
        declarationEntity dict: SKResponseDictionary,
        ofFile file: File,
        fromModule module: Module
    ) throws {
        do {
            let entityKind: SKUID = dict[keys.kind]!
            guard let kind = entityKind.declarationType() else {
                logger.log("* --- Ignoring: kind: \(entityKind): \(entityKind.description)", verbose: true)
                return
            }

            guard let rawName: String = dict[keys.name],
                  let usr: String = dict[keys.usr] else {
              logger.log("* --- Ignoring: kind: \(kind): name or usr invalid", verbose: true)

              return
            }

            let name = rawName.removingParameterInformation

            if namesToIgnore.contains(name) {
                logger.log("* --- Ignoring \(name) (USR: \(usr)) because its included in ignore-names", verbose: true)
                return
            }

            if kind == .enumelement, let parentUSR: String = dict.parent[keys.usr] {
                if let parent = dict.parent {
                    if let parentKindID: SKUID = parent[keys.kind] {
                        if let parentKind = parentKindID.declarationType() {
                            if parentKind == .enum {
                                logger.log("* --> found case in a parent enum: \(usr) - \(parentUSR)")
                                let codingKeysUSR: Set<String> = ["s:s7Codablea", "s:SE", "s:Se"]
                                if try inheritsFromAnyUSR(
                                    parentUSR,
                                    anyOf: codingKeysUSR,
                                    inModule: module,
                                    resursive: false
                                ) {
                                    logger.log("* --- Ignoring \(name) (USR: \(usr)) because its parent enum inherits from Codable and RawValue.", verbose: true)
                                    return
                                } else {
                                    logger.log("Info: Proceeding with \(name) (USR: \(usr)) because its parent enum does not appear to inherit Codable has RawValue.)", verbose: true)
                                }
                            }
                        }
                    }
                }

                let codingKeysUSR: Set<String> = ["s:s9CodingKeyP"]
                if try inheritsFromAnyUSR(
                    parentUSR,
                    anyOf: codingKeysUSR,
                    inModule: module
                ) {
                    logger.log("* --- Ignoring \(name) (USR: \(usr)) because its parent enum inherits from CodingKey.", verbose: true)
                    return
                } else {
                    logger.log("Info: Proceeding with \(name) (USR: \(usr)) because its parent enum does not appear to inherit from CodingKey.)", verbose: true)
                }
            }

            if kind == .property,
               dict.parent != nil,
               let parentKind: SKUID = dict.parent[keys.kind],
               parentKind.declarationType() == .object
            {
                guard let parentUSR: String = dict.parent[keys.usr] else {
                    throw logger.fatalError(forMessage: "Parent of \(usr) is has no USR!")
                }
                let codableUSRs: Set<String> = ["s:s7Codablea", "s:SE", "s:Se"]
                if try inheritsFromAnyUSR(
                    parentUSR,
                    anyOf: codableUSRs,
                    inModule: module
                ) {
                    logger.log("* --- Ignoring \(name) (USR: \(usr)) because its parent inherits from Codable.", verbose: true)
                    return
                } else {
                    logger.log("Info: Proceeding with \(name) (USR: \(usr)) because its parent does not appear to inherit from Codable.)", verbose: true)
                }
            }

            logger.log("* +++ Found declaration of \(name) (USR: \(usr))")
            dataStore.processedUsrs.insert(usr)

            let receiver: String? = dict[keys.receiver]
            if receiver == nil {
                dataStore.usrRelationDictionary[usr] = dict
            }
        } catch {
            print("❌ [process] SourceKit request error: \(error)")
        }
    }
}

// MARK: Obfuscating

extension SourceKitObfuscator {
    @discardableResult
    func obfuscate() throws -> ConversionMap {
        try dataStore.indexedFiles.forEach { index in
            try obfuscate(index: index)
        }
        try dataStore.plists.forEach { plist in
            try obfuscate(plist: plist)
        }
        return ConversionMap(obfuscationDictionary: dataStore.obfuscationDictionary)
    }

    func obfuscate(index: IndexedFile) throws {
        logger.log("\n--- Obfuscating \(index.file.name)")
        var referenceArray = [Reference]()
        index.response.recurseEntities { [unowned self] dict in
            guard let kindId: SKUID = dict[self.keys.kind],
                  kindId.referenceType() != nil || kindId.declarationType() != nil,
                  let rawName: String = dict[self.keys.name],
                  let usr: String = dict[self.keys.usr],
                  let line: Int = dict[self.keys.line],
                  let column: Int = dict[self.keys.column] else {

                let kind = dict[self.keys.kind] ?? "unknown"
                let rawName = dict[self.keys.name] ?? "unknown"
                let usr = dict[self.keys.usr] ?? "unknown"
                let line = dict[self.keys.line] ?? "unknown"
                let column = dict[self.keys.column] ?? "unknown"

                self.logger.log("* --- Skipped: kind: \(kind) | name: \(rawName) | usr: \(usr) | line: \(line) | column: \(column)")
                return
            }

            guard self.dataStore.processedUsrs.contains(usr) else {
                self.logger.log("* --- Skipped: kind: \(dict[self.keys.kind] ?? "unknown") | name: \(dict[self.keys.name] ?? "unknown") (USR: \(usr) at \(index.file.name) (\(line):\(column)): usr not proccessed ")
                return
            }

            guard dict.isReferencingInternalFramework(dataStore: self.dataStore) == false else {
                let name = rawName.removingParameterInformation
                self.logger.log("* --- Skipped reference of \(name) (USR: \(usr) at \(index.file.name) (\(line):\(column)): refercing internal framework")
                return
            }

            let name = rawName.removingParameterInformation
            let obfuscatedName = self.obfuscate(name: name)
            self.logger.log("* +++ Found reference of \(name) (USR: \(usr) at \(index.file.name) (\(line):\(column)) -> now \(obfuscatedName)")
            let reference = Reference(name: name, line: line, column: column)
            referenceArray.append(reference)
        }
        let originalContents = try index.file.read()
        let obfuscatedContents = try obfuscate(fileContents: originalContents, fromReferences: referenceArray)
        if let error = delegate?.obfuscator(self, didObfuscateFile: index.file, newContents: obfuscatedContents) {
            throw error
        }
    }

    func obfuscate(plist: File) throws {
        var data = try plist.read()
        let regex = "\\$\\(PRODUCT_MODULE_NAME\\)\\.[^ \n]*<"
        let results = data.match(regex: regex)
        guard results.isEmpty == false else {
            return
        }
        logger.log("\n--- Obfuscating \(plist.name)")
        for result in results.reversed() {
            let value = String(result.captureGroup(0, originalString: data).dropLast())
            let range = result.captureGroupRange(0, originalString: data)
            let productModuleName = "$(PRODUCT_MODULE_NAME)"
            let currentName = value.components(separatedBy: "\(productModuleName).").last ?? ""
            let protectedName = dataStore.obfuscationDictionary[currentName] ?? currentName
            let newPlistValue = productModuleName + "." + protectedName + "<"
            data = data.replacingCharacters(in: range, with: newPlistValue)
        }
        let newPlist = data
        if let error = delegate?.obfuscator(self, didObfuscateFile: plist, newContents: newPlist) {
            throw error
        }
    }

    func obfuscate(name: String) -> String {
        let cachedResult = dataStore.obfuscationDictionary[name]
        guard cachedResult == nil else {
            return cachedResult!
        }
        let size = 32
        let letters: [Character] = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let numbers: [Character] = Array("0123456789")
        let lettersAndNumbers = letters + numbers
        var randomString = ""
        for i in 0 ..< size {
            let characters: [Character] = i == 0 ? letters : lettersAndNumbers
            let rand = Int.random(in: 0 ..< characters.count)
            let nextChar = characters[rand]
            randomString.append(nextChar)
        }
        guard dataStore.obfuscatedNames.contains(randomString) == false else {
            return obfuscate(name: name)
        }
        dataStore.obfuscatedNames.insert(randomString)
        dataStore.obfuscationDictionary[name] = randomString
        return randomString
    }

    func obfuscate(fileContents: String, fromReferences references: [Reference]) throws -> String {
        let sortedReferences = references.sorted(by: <)

        var previousReference: Reference!
        var currentReferenceIndex = 0
        var line = 1
        var column = 1
        var currentCharIndex = 0

        var charArray: [String] = Array(fileContents).map(String.init)

        while currentCharIndex < charArray.count, currentReferenceIndex < sortedReferences.count {
            let reference = sortedReferences[currentReferenceIndex]
            if previousReference != nil,
               reference.line == previousReference.line,
               reference.column == previousReference.column {
                // Avoid duplicates.
                currentReferenceIndex += 1
            }
            let currentCharacter = charArray[currentCharIndex]
            if line == reference.line, column == reference.column {
                previousReference = reference
                let originalName = reference.name
                let obfuscatedName = obfuscate(name: originalName)
                let wasInternalKeyword = currentCharacter == "`"
                for i in 1 ..< (originalName.count + (wasInternalKeyword ? 2 : 0)) {
                    charArray[currentCharIndex + i] = ""
                }
                charArray[currentCharIndex] = obfuscatedName
                currentReferenceIndex += 1
                currentCharIndex += originalName.count
                column += originalName.utf8Count
                if wasInternalKeyword {
                    charArray[currentCharIndex] = ""
                }
            } else if currentCharacter == "\n" {
                line += 1
                column = 1
                currentCharIndex += 1
            } else {
                column += currentCharacter.utf8Count
                currentCharIndex += 1
            }
        }
        let sourceKitObfuscatedResult = charArray.joined()
        let sourceFileTree = try SyntaxParser.parse(source: sourceKitObfuscatedResult)
        return rewriter.visit(sourceFileTree).description
    }
}

extension SourceKitObfuscator {
    func inheritsFromAnyUSR(_ usr: String, anyOf usrs: Set<String>, inModule module: Module, resursive: Bool = true) throws -> Bool {
        let usrsKey = usrs.joined(separator: " ")
        if let cache = dataStore.inheritsFromX[usr, default: [:]][usrsKey] {
            return cache
        }

        func result(_ val: Bool) -> Bool {
            dataStore.inheritsFromX[usr, default: [:]][usrsKey] = val
            return val
        }

        let req = SKRequestDictionary(sourcekitd: sourceKit)
        req[keys.request] = requests.cursorinfo
        req[keys.compilerargs] = module.compilerArguments
        req[keys.usr] = usr
        // We have to store the file of the USR because it looks CursorInfo doesn't returns USRs if you use the wrong one
        //, except if it's a closed source framework. No idea why it works like that.
        // Hopefully this won't break in the future.
        let file: File = dataStore.fileForUSR[usr] ?? module.sourceFiles.first!
        req[keys.sourcefile] = file.path
        let cursorInfo = try sourceKit.sendSync(req)
        guard let annotation: String = cursorInfo[keys.annotated_decl] else {
            // Added support for phantom types: https://github.com/jortberends/swiftshield/commit/0d524facda062a4de6107f4ee421bc740402b5cc
            if usr.hasPrefix("c:") {
                logger.log("Pretending \(usr) inherits from Codable because SourceKit failed to look it up. This can happen if this USR belongs to an @objc class.", verbose: true)
                return result(true)
            }
            return result(false)
        }
        let regex = "usr=\\\"(.\\S*)\\\""
        let regexResult = annotation.components(separatedBy: " where ")[0].match(regex: regex)
        for res in regexResult {
            let inheritedUSR = res.captureGroup(1, originalString: annotation)
            if usrs.contains(inheritedUSR) {
                return result(true)
            } else {
                if resursive {
                    if try inheritsFromAnyUSR(inheritedUSR, anyOf: usrs, inModule: module) {
                        return result(true)
                    }
                }
            }
        }
        return result(false)
    }
}

// MARK: SKResponseDictionary Helpers

extension SKResponseDictionary {
    var isPublic: Bool {
        if let kindId: SKUID = self[sourcekitd.keys.kind], let type = kindId.declarationType(), type == .enumelement {
            return parent.isPublic
        }

        // Add public protocol conformance ignoring: https://github.com/CoreWillSoft/swiftshield/commit/2896a0c90f12c1929e7b80d826c7054d536c1cf4
        if let kindId: SKUID = parent[sourcekitd.keys.kind], let type = kindId.declarationType(), type == .protocol {
            return parent.isPublic
        }

        if let kindId: SKUID = parent[sourcekitd.keys.kind], let type = kindId.declarationType(), type == .method {
            return parent.isPublic
        }

        guard let attributes: SKResponseArray = self[sourcekitd.keys.attributes] else {
            return false
        }
        guard attributes.count > 0 else {
            return false
        }
        for i in 0 ..< attributes.count {
            guard let attr: SKUID = attributes[i][sourcekitd.keys.attribute] else {
                continue
            }
            guard attr.asString == AccessControl.public.rawValue || attr.asString == AccessControl.open.rawValue else {
                continue
            }
            return true
        }
        return false
    }

    func isReferencingInternalFramework(dataStore: SourceKitObfuscatorDataStore) -> Bool {
        guard let kindId: SKUID = self[sourcekitd.keys.kind] else {
            return false
        }
        let type = kindId.referenceType() ?? kindId.declarationType()
        guard type == .method || type == .property else {
            return false
        }
        guard let usr: String = self[sourcekitd.keys.usr] else {
            return false
        }
        let usrRelationDict = dataStore.usrRelationDictionary
        if let dict: SKResponseDictionary = usrRelationDict[usr], self.dict.data != dict.dict.data {
            return dict.isReferencingInternalFramework(dataStore: dataStore)
        }
        var isReference = false
        recurse(uid: sourcekitd.keys.related) { [unowned self] dict in
            guard isReference == false else {
                return
            }
            guard let usr: String = dict[self.sourcekitd.keys.usr] else {
                return
            }
            if dataStore.processedUsrs.contains(usr) == false {
                isReference = true
            } else if let dict: SKResponseDictionary = usrRelationDict[usr] {
                isReference = dict.isReferencingInternalFramework(dataStore: dataStore)
            }
        }
        return isReference
    }
}

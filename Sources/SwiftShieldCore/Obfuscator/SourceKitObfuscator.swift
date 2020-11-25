import Foundation

final class SourceKitObfuscator: ObfuscatorProtocol {
    let sourceKit: SourceKit
    let logger: LoggerProtocol
    let dataStore: SourceKitObfuscatorDataStore
    let ignorePublic: Bool
    weak var delegate: ObfuscatorDelegate?

    init(sourceKit: SourceKit, logger: LoggerProtocol, dataStore: SourceKitObfuscatorDataStore, ignorePublic: Bool) {
        self.sourceKit = sourceKit
        self.logger = logger
        self.dataStore = dataStore
        self.ignorePublic = ignorePublic
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
        let compilerArguments = SKRequestArray(sourcekitd: sourceKit)
        module.compilerArguments.forEach(compilerArguments.append(_:))
        try module.sourceFiles.sorted { $0.path < $1.path }.forEach { file in
            logger.log("--- Indexing: \(file.name)")
            let req = SKRequestDictionary(sourcekitd: sourceKit)
            req[keys.request] = requests.indexsource
            req[keys.sourcefile] = file.path
            req[keys.compilerargs] = compilerArguments
            let response = sourceKit.sendSync(req)
            switch response {
            case let .success(response):
                response.recurseEntities { [unowned self] dict in
                    if self.ignorePublic, dict.isPublic {
                        return
                    }
                    self.process(declarationEntity: dict, ofFile: file)
                }
                let indexedFile = IndexedFile(file: file, response: response)
                self.dataStore.indexedFiles.append(indexedFile)
            case let .failure(error):
                throw logger.fatalError(forMessage: error)
            }
        }
        dataStore.plists = dataStore.plists.union(module.plists)
    }

    func process(
        declarationEntity dict: SKResponseDictionary,
        ofFile _: File
    ) {
        let entityKind: SKUID = dict[keys.kind]!
        guard entityKind.declarationType() != nil else {
            return
        }
        guard let rawName: String = dict[keys.name],
            let usr: String = dict[keys.usr] else {
            return
        }

        let name = rawName.removingParameterInformation

        // CodingKeysFix: mariusms75, 20 nov 2020: 4.0.3 repo implementation not working, it obfuscates CodingKeys
//        if dict.isCodingKeysEnumElement {
//            return
//        }
        
        // start: CodingKeysFix: mariusms75, 20 nov 2020: Exclude CodingKeys using SwiftShield 3.5.1 method
        if kind == .enum, name.lowercased().hasSuffix("codingkeys") {
            dataStore.codableEnumUSRs.insert(usr)
            logger.log("* Found Enum CodingKeys declaration of \(name) (USR: \(usr))")
            return
        }
        
        if kind == .enumelement {
            for codableEnum in dataStore.codableEnumUSRs {
                // Enum element belongs to excluded enum
                if usr.lowercased().hasPrefix(codableEnum.lowercased()) {
                    logger.log("* Found EnumElement declaration of \(codableEnum) (USR: \(usr))")
                    return
                }
            }
        }
        // end: CodingKeysFix

        logger.log("* Found declaration of \(name) (USR: \(usr))")
        dataStore.processedUsrs.insert(usr)

        let receiver: String? = dict[keys.receiver]
        if receiver == nil {
            dataStore.usrRelationDictionary[usr] = dict
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
        logger.log("--- Obfuscating \(index.file.name)")
        var referenceArray = [Reference]()
        index.response.recurseEntities { [unowned self] dict in
            guard let kindId: SKUID = dict[self.keys.kind],
                kindId.referenceType() != nil,
                let rawName: String = dict[self.keys.name],
                let usr: String = dict[self.keys.usr],
                self.dataStore.processedUsrs.contains(usr),
                let line: Int = dict[self.keys.line],
                let column: Int = dict[self.keys.column],
                dict.isReferencingInternalFramework(dataStore: self.dataStore) == false else {
                return
            }

            let name = rawName.removingParameterInformation
            let obfuscatedName = self.obfuscate(name: name)
            self.logger.log("* Found reference of \(name) (USR: \(usr) at \(index.file.name) (\(line):\(column)) -> now \(obfuscatedName)")
            let reference = Reference(name: name, line: line, column: column)
            referenceArray.append(reference)
        }
        let originalContents = try index.file.read()
        let obfuscatedContents = obfuscate(fileContents: originalContents, fromReferences: referenceArray)
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
        logger.log("--- Obfuscating \(plist.name)")
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

    func obfuscate(fileContents: String, fromReferences references: [Reference]) -> String {
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
        return charArray.joined()
    }
}

// MARK: SKResponseDictionary Helpers

extension SKResponseDictionary {
    var isPublic: Bool {
        if let kindId: SKUID = self[sourcekitd.keys.kind], let type = kindId.declarationType(), type == .enumelement {
            return parent.isPublic
        }
        guard let attributes: SKResponseArray = self[sourcekitd.keys.attributes] else {
            return false
        }
        guard attributes.count > 0 else {
            return false
        }
        for _ in 0 ..< attributes.count {
            guard let attr: SKUID = attributes[0][sourcekitd.keys.attribute] else {
                continue
            }
            guard attr.asString == AccessControl.public.rawValue || attr.asString == AccessControl.open.rawValue else {
                continue
            }
            return true
        }
        return false
    }

    var isCodingKeysEnumElement: Bool {
        guard let kindId: SKUID = self[sourcekitd.keys.kind],
              let type = kindId.declarationType(),
              type == .enumelement else
        {
            return false
        }
        guard let parentEntities: SKResponseArray = parent[sourcekitd.keys.entities] else {
            return false
        }
        var result = false
        parentEntities.forEach(parent: parent) { (i, dict) -> Bool in
            guard let kindId: SKUID = dict[sourcekitd.keys.kind],
                  let type = kindId.referenceType(),
                  type == .protocol,
                  let usr: String = dict[self.sourcekitd.keys.usr],
                  usr == "s:s9CodingKeyP" else
            {
                return true
            }
            result = true
            return false
        }
        return result
    }

    func isReferencingInternalFramework(dataStore: SourceKitObfuscatorDataStore) -> Bool {
        guard let kindId: SKUID = self[sourcekitd.keys.kind] else {
            return false
        }
        let type = kindId.referenceType()
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

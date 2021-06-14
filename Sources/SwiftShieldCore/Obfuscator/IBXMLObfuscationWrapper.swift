//
//  IBXMLObfuscationWrapper.swift
//  

import Foundation

final class IBXMLObfuscationWrapper {
    private let obfuscationDictionary: [String: String]
    private let modulesToIgnore: Set<String>
    private var idModuleMapping: [String: String] = [:]
    
    init(obfuscationDictionary: [String: String], modulesToIgnore: Set<String>) {
        self.obfuscationDictionary = obfuscationDictionary
        self.modulesToIgnore = modulesToIgnore
    }
    
    func obfuscate(file: File) throws -> String {
        let xmlDoc = try XMLDocument(contentsOf: URL(fileURLWithPath: file.path), options: XMLNode.Options())
        idModuleMapping = [:]
        guard let rootElement = xmlDoc.rootElement() else { return "" }
        obfuscateIBXML(element: rootElement, document: xmlDoc)
        let origStr = try file.read()
        var newIBXMLFile = xmlDoc.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
        let xmlLineRegex = "<\\?xml version=.*?\\?>"
        if let oldXMLRange = origStr.range(of: xmlLineRegex, options: .regularExpression) {
            newIBXMLFile.replaceFirst(regex: xmlLineRegex, with: String(origStr[oldXMLRange]))
        }
        return newIBXMLFile
    }
    
    private func getSelectorModule(element: XMLElement, document: XMLDocument) throws -> String {
        guard let destinationAttrib = element.attribute(forName: "destination")?.stringValue, !destinationAttrib.isEmpty else { return "" }
        if idModuleMapping[destinationAttrib] == nil, let firstNode = try document.nodes(forXPath: "//*[@id='\(destinationAttrib)']").first(where: { ($0 as? XMLElement) != nil }) as? XMLElement {
            let customModule = firstNode.attribute(forName: "customModule")?.stringValue ?? ""
            idModuleMapping[destinationAttrib] = customModule
        }
        return idModuleMapping[destinationAttrib] ?? ""
    }
    
    private func obfuscateIBXML(element: XMLElement, document: XMLDocument) {
        if let attribElement = element.attribute(forName: "customClass"),
           let attribStr = attribElement.stringValue, !attribStr.isEmpty,
           let obfuscatedClassName = obfuscationDictionary[attribStr], !obfuscatedClassName.isEmpty {
            let attribModule = element.attribute(forName: "customModule")?.stringValue ?? ""
            if attribModule.isEmpty || !modulesToIgnore.contains(attribModule) {
                attribElement.stringValue = obfuscatedClassName
            }
        }
        if element.name == "action", let selectorElement = element.attribute(forName: "selector"), element.parent?.name == "connections", let selectorStr = selectorElement.stringValue, !selectorStr.isEmpty {
            let selectorModule = (try? getSelectorModule(element: element, document: document)) ?? ""
            if selectorModule.isEmpty || !modulesToIgnore.contains(selectorModule) {
                if selectorStr.contains(":") {
                    var selectorComps = selectorStr.components(separatedBy: ":")
                    if let firstSelectorName = selectorComps.first, !firstSelectorName.isEmpty, let obfuscatedName = obfuscationDictionary[firstSelectorName], !obfuscatedName.isEmpty {
                        selectorComps[0] = obfuscatedName
                        selectorElement.stringValue = selectorComps.joined(separator: ":")
                    }
                }else{
                    if let obfuscatedName = obfuscationDictionary[selectorStr], !obfuscatedName.isEmpty {
                        selectorElement.stringValue = obfuscatedName
                    }
                }
            }
        }
        for child in element.children ?? [] {
            guard let childElement = child as? XMLElement else { continue }
            obfuscateIBXML(element: childElement, document: document)
        }
    }
}

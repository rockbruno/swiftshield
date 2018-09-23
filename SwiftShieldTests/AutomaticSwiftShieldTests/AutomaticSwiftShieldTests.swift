//
//  AutomaticSwiftShieldTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 8/24/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class AutomaticSwiftShieldTests: XCTestCase {
    func testObfuscator() {
        let obfuscationData = AutomaticObfuscationData()
        obfuscationData.obfuscationDict["ViewController"] = "AAAAA"
        obfuscationData.obfuscationDict["CustomViewController"] = "BBBBB"
        obfuscationData.obfuscationDict["++++"] = "SHOULDNOTWORK"
        obfuscationData.obfuscationDict["myProperty"] = "CCCCC"
        obfuscationData.obfuscationDict["MyType"] = "DDDDD"
        obfuscationData.obfuscationDict["fakeMethod"] = "EEEEE"
        obfuscationData.obfuscationDict["myMethod"] = "FFFFF"
        let references = [ReferenceData(name: "ViewController", line: 1, column: 7),
                          ReferenceData(name: "CustomViewController", line: 1, column: 23),
                          ReferenceData(name: "myMethod", line: 3, column: 20),
                          ReferenceData(name: "ViewController", line: 4, column: 34),
                          ReferenceData(name: "ViewController", line: 4, column: 55),
                          ReferenceData(name: "myProperty", line: 6, column: 16),
                          ReferenceData(name: "MyType", line: 6, column: 28),
                          ReferenceData(name: "ViewController", line: 10, column: 15),
                          ReferenceData(name: "fakeMethod", line: 10, column: 30)]
        let originalFileData = loadFile("MockOriginalFile", ofType: "txt")
        let originalFile = String(data: originalFileData, encoding: .utf8)!
        let obfuscatedFile = AutomaticSwiftShield(basePath: "abc", projectToBuild: "abc", schemeToBuild: "abc", modulesToIgnore: [], protectedClassNameSize: 0).generateObfuscatedFile(fromString: originalFile, references: references, obfuscationData: obfuscationData)
        let expectedFileData = loadFile("MockObfuscatedFile", ofType: "txt")
        let expectedFile = String(data: expectedFileData, encoding: .utf8)!
        XCTAssertEqual(obfuscatedFile, expectedFile)
    }

    func testPlistExtractor() {
        let protector = AutomaticSwiftShield(basePath: "abc", projectToBuild: "abc", schemeToBuild: "abc", modulesToIgnore: [], protectedClassNameSize: 0)
        let plist = path(for: "MockPlist", ofType: "plist")
        let file = File(filePath: plist)
        let data = protector.getPlistVersionAndNumber(file)
        XCTAssertEqual("1.0", data.0)
        XCTAssertEqual("1", data.1)
    }

    func testPlistPrincipalClassObfuscation() {
        let protector = AutomaticSwiftShield(basePath: "abc", projectToBuild: "abc", schemeToBuild: "abc", modulesToIgnore: [], protectedClassNameSize: 0)
        let plist = path(for: "MockPlist", ofType: "plist")
        let file = MockFile(path: plist)
        let obfuscationData = AutomaticObfuscationData(modules: [Module(name: "mock", plists: [file])])
        obfuscationData.obfuscationDict["AClass"] = "ZZZZZ"
        protector.obfuscateNSPrincipalClassPlists(obfuscationData: obfuscationData)
        let expectedPlistData = loadFile("MockPlistObfuscatedPrincipalClass", ofType: "plist")
        let expectedPlistString = String(data: expectedPlistData, encoding: .utf8)!
        let origXml = try! AEXMLDocument(xml: file.writtenData)
        let expectedXml = try! AEXMLDocument(xml: expectedPlistString)
        XCTAssertEqual(origXml.xml, expectedXml.xml)
    }
}

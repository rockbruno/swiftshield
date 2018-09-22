//
//  AutomaticSwiftShieldTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 8/24/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class AutomaticSwiftShieldTests: XCTestCase {
    func testObfuscationDataCreation() {
        let modules: [Module] = [Module(name: "test", sourceFiles: [], xibFiles: [File(filePath: "/Users/bruno.rocha/Desktop/test/test/BLABLA.xib"), File(filePath: "/Users/bruno.rocha/Desktop/test/test/Base.lproj/LaunchScreen.storyboard"), File(filePath: "/Users/bruno.rocha/Desktop/test/test/Base.lproj/Main.storyboard")], plist: nil, compilerArguments: []), Module(name: "MyLib", sourceFiles: [], xibFiles: [File(filePath: "/Users/bruno.rocha/Desktop/test/RapiddoUtils/Sources/Assets/StatusLine.xib")], plist: nil, compilerArguments: [])]
        let protector = AutomaticSwiftShield(basePath: "abc", projectToBuild: "abc", schemeToBuild: "abc", modulesToIgnore: [], protectedClassNameSize: 0)
        let obfuscationData = protector.getObfuscationData(from: modules)
        XCTAssertEqual(obfuscationData.storyboardsToObfuscate, modules.flatMap { $0.xibFiles })
        XCTAssertEqual(obfuscationData.moduleNames, ["test", "MyLib"])
    }

    func testObfuscator() {
        let obfuscationData = ObfuscationData()
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
}

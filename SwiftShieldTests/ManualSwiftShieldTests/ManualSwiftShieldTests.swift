//
//  AutomaticSwiftShieldTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 9/24/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class ManualSwiftShieldTests: XCTestCase {
    func testObfuscator() {
        let ss = ManualSwiftShield(basePath: "abc", tag: "__s", protectedClassNameSize: 32, dryRun: true)
        let obfuscationData = ObfuscationData()
        obfuscationData.obfuscationDict["ViewController__s"] = "AAAAA"
        obfuscationData.obfuscationDict["CustomVC__s"] = "BBBBBBBBBBBBBBBBBBB"
        obfuscationData.obfuscationDict["myProperty__s"] = "CCCCC"
        obfuscationData.obfuscationDict["MyType__s"] = "DDDDD"
        obfuscationData.obfuscationDict["fakeMethod__s"] = "EEEEE"
        obfuscationData.obfuscationDict["myMethod__s"] = "FFFFF"
        let originalFileData = loadFile("MockManualOriginalFile", ofType: "txt")
        let originalFile = String(data: originalFileData, encoding: .utf8)!
        let obfuscatedFile = ss.obfuscateReferences(fileString: originalFile, obfsData: obfuscationData)
        let expectedFileData = loadFile("MockObfuscatedFile", ofType: "txt")
        let expectedFile = String(data: expectedFileData, encoding: .utf8)!
        XCTAssertEqual(obfuscatedFile, expectedFile)
    }
}

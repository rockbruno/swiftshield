//
//  DeobfuscatorTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 9/22/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class DeobfuscatorTests: XCTestCase {

    let mockObfuscatedLog = "0  vn#nfib  0x10050090c specialized 38fhdb3i.38383(bvjn9fjd, argument : ksadbDs) -> GHInfa (MyFile.swift:73)"
    let mockDeobfuscatedLog = "0  SwiftShield  0x10050090c specialized AClass.myMethod(BClass, argument : CClass) -> DClass (MyFile.swift:73)"
    let mockDict: [String: String] = ["SwiftShield": "vn#nfib", "AClass": "38fhdb3i", "myMethod": "38383", "BClass": "bvjn9fjd", "CClass": "ksadbDs", "DClass": "GHInfa"]

    func testMapExtraction() {
        let obfuscationData = ObfuscationData()
        obfuscationData.obfuscationDict = mockDict
        let mapOutput = Protector.mapData(from: obfuscationData)
        let expectedDict = Deobfuscator.process(mapFileContent: mapOutput)
        XCTAssertEqual(mockDict, expectedDict)
    }

    func testFileChanges() {
        let replacedContent = Deobfuscator.replace(content: mockObfuscatedLog, withContentsOf: mockDict)
        XCTAssertEqual(replacedContent, mockDeobfuscatedLog)
    }

    func testRunner() {
        let mockFile = MockFile(data: mockObfuscatedLog)
        let obfuscationData = ObfuscationData()
        obfuscationData.obfuscationDict = mockDict
        let mapOutput = Protector.mapData(from: obfuscationData)
        let mockMapFile = MockFile(data: mapOutput)
        Deobfuscator.deobfuscate(file: mockFile, mapFile: mockMapFile)
        XCTAssertEqual(mockFile.writtenData, mockDeobfuscatedLog)
    }
}

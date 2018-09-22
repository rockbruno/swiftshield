//
//  DeobfuscatorTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 9/22/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class DeobfuscatorTests: XCTestCase {
    func testMapExtraction() {
        let obfuscationData = ObfuscationData()
        let dict = ["AClass": "38fhdb3i", "BType": "bvjn9fjd"]
        obfuscationData.obfuscationDict = dict
        let mapOutput = Protector.mapData(from: obfuscationData)
        let expectedDict = Deobfuscator.process(mapFileContent: mapOutput)
        XCTAssertEqual(dict, expectedDict)
    }

    func testFileChanges() {
        let data = "0  SwiftShield  0x10050090c specialized 38fhdb3i.38383(bvjn9fjd, argument : ksadbDs) -> GHInfa (MyFile.swift:73)"
        let dict = ["AClass": "38fhdb3i", "myMethod": "38383", "BClass": "bvjn9fjd", "CClass": "ksadbDs", "DClass": "GHInfa"]
        let replacedContent = Deobfuscator.replace(content: data, withContentsOf: dict)
        let expected = "0  SwiftShield  0x10050090c specialized AClass.myMethod(BClass, argument : CClass) -> DClass (MyFile.swift:73)"
        XCTAssertEqual(replacedContent, expected)
    }
}

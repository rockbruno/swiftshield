@testable import SwiftShieldCore
import XCTest

final class DeobfuscatorTests: XCTestCase {
    let mockObfuscatedLog = "0  vn#nfibffffffff  0x10050090c specialized 38fhdb3i.383(bvjn9fjd, argument : ksadbDs) -> GHInfa (MyFile.swift:73)"
    let mockDeobfuscatedLog = "0  SwiftShield  0x10050090c specialized AClass.myMethod(BClass, argument : CClass) -> DClass (MyFile.swift:73)"
    let mockDict: [String: String] = ["SwiftShield": "vn#nfibffffffff", "AClass": "38fhdb3i", "myMethod": "383", "BClass": "bvjn9fjd", "CClass": "ksadbDs", "DClass": "GHInfa"]

    func test_deobfuscation() throws {
        let crashFilePath = temporaryFilePath(forFile: "crash.crash")
        let crashFile = File(path: crashFilePath)
        try crashFile.write(contents: mockObfuscatedLog)

        let mapFilePath = temporaryFilePath(forFile: "deobfuscator_map.txt")
        let mapFile = File(path: mapFilePath)
        let map = ConversionMap(obfuscationDictionary: mockDict)
        try mapFile.write(contents: map.toString())

        let deobfuscator = Deobfuscator(logger: DummyLogger())
        try deobfuscator.deobfuscate(crashFilePath: crashFilePath, mapPath: mapFilePath)

        XCTAssertEqual(try crashFile.read(), mockDeobfuscatedLog)
    }
}

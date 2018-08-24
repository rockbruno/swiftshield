import XCTest

func loadFile(_ name: String, ofType type: String) -> Data {
    let bundle = Bundle(for: StoryboardObfuscationTests.self)
    let path = bundle.path(forResource: name, ofType: type)!
    return try! Data(contentsOf: URL(fileURLWithPath: path))
}

class StoryboardObfuscationTests: XCTestCase {
    func testStoryboardObfuscation() {
        let data = loadFile("MockXib", ofType: "txt")
        var xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        let obfsData = ObfuscationData()
        obfsData.obfuscationDict["ClassFromMainModule"] = "AAAAClass"
        obfsData.obfuscationDict["ViewFromMainModule"] = "AAAAClass2"
        obfsData.obfuscationDict["selectorFromMainModule"] = "AAAASelector"
        obfsData.obfuscationDict["ClassFromOtherModule"] = "BBBBClass"
        obfsData.obfuscationDict["AnotherClassFromOtherModule"] = "BBBBClass2"
        obfsData.obfuscationDict["ClassFromThirdModule"] = "CCCCClass"
        Protector(basePath: "abc").obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        let data2 = loadFile("ExpectedMockXib", ofType: "txt")
        let xmlDoc2 = try! AEXMLDocument(xml: data2, options: AEXMLOptions())
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)
        xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        obfsData.moduleNames = ["OtherModule", "ThirdModule"]
        let data3 = loadFile("ExpectedMockXibIgnoringMainModule", ofType: "txt")
        let xmlDoc3 = try! AEXMLDocument(xml: data3, options: AEXMLOptions())
        Protector(basePath: "abc").obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        XCTAssertEqual(xmlDoc.xml, xmlDoc3.xml)
    }
}

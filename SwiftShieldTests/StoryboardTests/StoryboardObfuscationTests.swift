import XCTest

func path(for name: String, ofType type: String) -> String {
    let bundle = Bundle(for: StoryboardObfuscationTests.self)
    return bundle.path(forResource: name, ofType: type)!
}

func loadFile(_ name: String, ofType type: String) -> Data {
    let filePath = path(for: name, ofType: type)
    return try! Data(contentsOf: URL(fileURLWithPath: filePath))
}

class StoryboardObfuscationTests: XCTestCase {
    func testStoryboardObfuscation() {
        let obfsData = ObfuscationData()
        obfsData.obfuscationDict["ViewController"] = "AAAAClass"
        obfsData.obfuscationDict["MainModuleView"] = "AAAAClass2"
        obfsData.obfuscationDict["ThirdModuleView"] = "CCCCClass"
        obfsData.obfuscationDict["OtherModuleButton"] = "BBBBClass"
        obfsData.obfuscationDict["otherModuleButtonMethod"] = "AAAASelector"

        var data = loadFile("MockStoryboard", ofType: "txt")
        var xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc").obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        data = loadFile("ExpectedMockStoryboard", ofType: "txt")
        var xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)

        data = loadFile("MockStoryboard", ofType: "txt")
        xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        obfsData.moduleNames = ["OtherModule", "ThirdModule"]
        data = loadFile("ExpectedMockStoryboardIgnoringMainModule", ofType: "txt")
        xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc").obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)

        data = loadFile("MockXib", ofType: "txt")
        xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        obfsData.moduleNames = nil
        data = loadFile("ExpectedMockXib", ofType: "txt")
        xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc").obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)
    }
}

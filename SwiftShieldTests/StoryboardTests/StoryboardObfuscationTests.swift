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

    let obfuscationDict: [String: String] = ["ViewController": "AAAAClass", "MainModuleView": "AAAAClass2", "ThirdModuleView": "CCCCClass", "OtherModuleButton": "BBBBClass", "otherModuleButtonMethod": "AAAASelector"]

    func testStoryboardObfuscation() {
        var obfsData = ObfuscationData()
        obfsData.obfuscationDict = self.obfuscationDict
        var data = loadFile("MockStoryboard", ofType: "txt")
        var xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc", dryRun: true).obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        data = loadFile("ExpectedMockStoryboard", ofType: "txt")
        var xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)

        data = loadFile("MockXib", ofType: "txt")
        xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        data = loadFile("ExpectedMockXib", ofType: "txt")
        xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc", dryRun: true).obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)

        data = loadFile("MockStoryboard", ofType: "txt")
        xmlDoc = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        obfsData = AutomaticObfuscationData(modules: [Module(name: "OtherModule"), Module(name: "ThirdModule")])
        obfsData.obfuscationDict = self.obfuscationDict
        data = loadFile("ExpectedMockStoryboardIgnoringMainModule", ofType: "txt")
        xmlDoc2 = try! AEXMLDocument(xml: data, options: AEXMLOptions())
        Protector(basePath: "abc", dryRun: true).obfuscateIBXML(element: xmlDoc.root, obfuscationData: obfsData)
        XCTAssertEqual(xmlDoc.xml, xmlDoc2.xml)
    }
}

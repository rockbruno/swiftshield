@testable import SwiftShieldCore
import XCTest

final class SourceKitObfuscatorTests: XCTestCase {
    func test_moduleRegistration() throws {
        let sourceKit = SourceKit(logger: DummyLogger())
        let dataStore = SourceKitObfuscatorDataStore()
        let obfuscator = SourceKitObfuscator(sourceKit: sourceKit, logger: DummyLogger(), dataStore: dataStore, namesToIgnore: [], ignorePublic: false)

        let module = try testModule(withContents: "final class Foo {}")

        try obfuscator.registerModuleForObfuscation(module)

        let expectedSet = Set<String>(["s:18FeatureTestProject3FooC", "c:@M@FeatureTestProject@objc(cs)AppDelegate", "s:18FeatureTestProject28CodableProtocolInAnotherFileP"])

        XCTAssertEqual(dataStore.processedUsrs, expectedSet)
        XCTAssertEqual(Set(dataStore.indexedFiles.map { $0.file }), module.sourceFiles)
    }

    func test_removeParametersFromString() {
        let methodName = "fooFunc(parameter:parameter2:)"
        XCTAssertEqual(methodName.removingParameterInformation, "fooFunc")
        let propertyName = "barProp"
        XCTAssertEqual(propertyName.removingParameterInformation, "barProp")
    }

    func test_obfuscation_sendsCorrectObfuscatedFileContentToDelegate() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        class Foo {
            func barbar() {}
        }
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"
        store.obfuscationDictionary["barbar"] = "OBS2"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        class OBS1 {
            func OBS2() {}
        }
        """)
        XCTAssertEqual(delegate.receivedContent.count, 3)
    }

    func test_obfuscation_sendsCorrectObfuscatedPlistContentToDelegate() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withPlist: """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>NSExtensionPrincipalClass</key>
            <string>$(PRODUCT_MODULE_NAME).Foo</string>
            <key>Foo</key>
            <integer>2</integer>
        <key>WKExtensionDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).Foo</string>
        </dict>
        </plist>
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiablePlistPath], """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>NSExtensionPrincipalClass</key>
            <string>$(PRODUCT_MODULE_NAME).OBS1</string>
            <key>Foo</key>
            <integer>2</integer>
        <key>WKExtensionDelegateClassName</key>
                    <string>$(PRODUCT_MODULE_NAME).OBS1</string>
        </dict>
        </plist>
        """)
    }

    func test_obfuscation_haltsIfDelegateFails() throws {
        let (obfs, _, delegate) = baseTestData()
        let module = try testModule(withContents: "final class Foo {}")
        try obfs.registerModuleForObfuscation(module)

        delegate.failAfter = 2
        let someError = NSError(domain: "foo", code: 0, userInfo: nil)
        delegate.error = someError

        XCTAssertThrowsError(try obfs.obfuscate())
        XCTAssertEqual(delegate.receivedContent.count, 2)
    }

    func test_obfuscation_returnsConversionMap() throws {
        let (obfs, store, _) = baseTestData()
        let module = try testModule(withContents: """
        class Foo {
            func barbar() {}
        }
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"
        store.obfuscationDictionary["barbar"] = "OBS2"

        try obfs.registerModuleForObfuscation(module)
        let map = try obfs.obfuscate()

        XCTAssertEqual(map.obfuscationDictionary["Foo"], "OBS1")
        XCTAssertEqual(map.obfuscationDictionary["barbar"], "OBS2")
    }

    func test_obfuscation_cachesStrings() {
        let sourceKit = SourceKit(logger: DummyLogger())
        let dataStore = SourceKitObfuscatorDataStore()
        let obfuscator = SourceKitObfuscator(sourceKit: sourceKit, logger: DummyLogger(), dataStore: dataStore, namesToIgnore: [], ignorePublic: false)

        let fooString = "fooString"
        XCTAssertNil(dataStore.obfuscationDictionary[fooString])

        let obfuscation = obfuscator.obfuscate(name: fooString)

        XCTAssertNotNil(dataStore.obfuscationDictionary[fooString])
        XCTAssertNotEqual(fooString, obfuscation)

        let sameObfuscation = obfuscator.obfuscate(name: fooString)
        XCTAssertEqual(obfuscation, sameObfuscation)

        dataStore.obfuscationDictionary[fooString] = nil
        dataStore.obfuscatedNames.remove(obfuscation)

        let differentObfuscation = obfuscator.obfuscate(name: fooString)
        XCTAssertNotEqual(obfuscation, differentObfuscation)
    }

    func test_fileContentsObfuscationBasedOnReferences() throws {
        let file = """
        class Foo {
            let `default` = 3
        }
        """

        let defaultDecl = Reference(name: "default", line: 2, column: 9)
        let fooDecl = Reference(name: "Foo", line: 1, column: 7)

        let sourceKit = SourceKit(logger: DummyLogger())
        let dataStore = SourceKitObfuscatorDataStore()
        let obfuscator = SourceKitObfuscator(sourceKit: sourceKit, logger: DummyLogger(), dataStore: dataStore, namesToIgnore: [], ignorePublic: false)

        dataStore.obfuscationDictionary["Foo"] = "AAAA"
        dataStore.obfuscationDictionary["default"] = "BBBB"

        let result = obfuscator.obfuscate(fileContents: file, fromReferences: [fooDecl, defaultDecl])

        XCTAssertEqual(result, """
        class AAAA {
            let BBBB = 3
        }
        """)
    }

    func test_fileContentsObfuscationBasedOnReferences_ignoresDuplicates() throws {
        let file = """
        class Foo {
            let `default` = 3
        }
        """

        let defaultDecl = Reference(name: "default", line: 2, column: 9)
        let fooDecl = Reference(name: "Foo", line: 1, column: 7)

        let sourceKit = SourceKit(logger: DummyLogger())
        let dataStore = SourceKitObfuscatorDataStore()
        let obfuscator = SourceKitObfuscator(sourceKit: sourceKit, logger: DummyLogger(), dataStore: dataStore, namesToIgnore: [], ignorePublic: false)

        dataStore.obfuscationDictionary["Foo"] = "AAAA"
        dataStore.obfuscationDictionary["default"] = "BBBB"

        let result = obfuscator.obfuscate(fileContents: file, fromReferences: [
            defaultDecl, defaultDecl, fooDecl, defaultDecl, fooDecl, fooDecl,
        ])

        XCTAssertEqual(result, """
        class AAAA {
            let BBBB = 3
        }
        """)
    }
    
    func test_phantomTypeConformingToProtocol_sendsCorrectObfuscatedFileContentToDelegate() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        protocol SomeProtocol {}
        struct SomeStruct<T: SomeProtocol> {
            var someBool: Bool {
                return true
            }
        }
        """)

        store.obfuscationDictionary["SomeProtocol"] = "OBS1"
        store.obfuscationDictionary["SomeStruct"] = "OBS2"
        store.obfuscationDictionary["someBool"] = "OBS3"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        protocol OBS1 {}
        struct OBS2<T: OBS1> {
            var OBS3: Bool {
                return true
            }
        }
        """)
        XCTAssertEqual(delegate.receivedContent.count, 3)
    }
    
    func test_phantomTypeConformingToProtocolWithWhereClause_sendsCorrectObfuscatedFileContentToDelegate() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        struct Foo {}
        protocol SomeProtocol {
            associatedtype Item
        }
        struct SomeStruct<T: SomeProtocol> where T.Item == Foo {
            var someBool: Bool {
                return true
            }
        }
        """)

        store.obfuscationDictionary["SomeProtocol"] = "OBS1"
        store.obfuscationDictionary["SomeStruct"] = "OBS2"
        store.obfuscationDictionary["someBool"] = "OBS3"
        store.obfuscationDictionary["Foo"] = "OBS4"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        struct OBS4 {}
        protocol OBS1 {
            associatedtype Item
        }
        struct OBS2<T: OBS1> where T.Item == OBS4 {
            var OBS3: Bool {
                return true
            }
        }
        """)
        XCTAssertEqual(delegate.receivedContent.count, 3)
    }
}

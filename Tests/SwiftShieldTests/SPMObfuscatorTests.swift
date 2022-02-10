//
//  File.swift
//  
//
//  Created by Binh An Tran on 10/2/22.
//

@testable import SwiftShieldCore
import XCTest

final class SPMSourceKitObfuscatorTests: XCTestCase {
    // swiftshield obfuscate -p SPMFeatureTestsProject.xcodeproj -s SPMFeatureTestsProject --ignore-public  --ignore-names "AppDelegate,ViewController"

    func test_publicProtocolWithMethodsWhenNotIgnorePublic_sendsCorrectNonObfuscatedFileContentToDelegate2() throws {
        let (obfs, store, delegate) = SPMFeatureTestUtils.baseTestData(ignorePublic: false)
        let (libraryModule, appModule) = try SPMFeatureTestUtils.testModule(
            withAppContents: """
            import MyLibrary

            let someImpl = SomeImpl()
            """,
            withLibraryContents: """
            public protocol SomeProtocol {
                func someFunc() -> Bool
            }
            public class SomeImpl: SomeProtocol {
                public func someFunc() -> Bool {
                    return true
                }
            }
            """
        )

        store.obfuscationDictionary["SomeImpl"] = "OBS1"
        store.obfuscationDictionary["SomeProtocol"] = "OBS2"
        store.obfuscationDictionary["someFunc"] = "OBS3"

        try obfs.registerModuleForObfuscation(libraryModule)
        try obfs.registerModuleForObfuscation(appModule)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableAppFilePath], """
        import MyLibrary

        let someImpl = OBS1()
        """)

        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableLibraryFilePath], """
        public protocol OBS2 {
            func OBS3() -> Bool
        }
        public class OBS1: OBS2 {
            public func OBS3() -> Bool {
                return true
            }
        }
        """)
    }
}

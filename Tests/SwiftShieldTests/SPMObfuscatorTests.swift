//
//  File.swift
//  
//
//  Created by Binh An Tran on 10/2/22.
//

@testable import SwiftShieldCore
import XCTest

final class SPMSourceKitObfuscatorTests: XCTestCase {
    // swiftshield obfuscate -p SPMFeatureTestsProject.xcodeproj -s SPMFeatureTestsProject --ignore-public --ignore-names "AppDelegate,ViewController" --print-sourcekit

    // swift run swiftshield obfuscate -p /Users/binhan.tran/Desktop/Private/OpenSource/swiftshield/Tests/Resources/SPMFeatureTestsProject/SPMFeatureTestsProject.xcodeproj -s SPMFeatureTestsProject --ignore-public --ignore-names "AppDelegate,ViewController"

    // swift run swiftshield obfuscate -p /Users/binhan.tran/Desktop/Private/OpenSource/swiftshield/Tests/Resources/SPMFeatureTestsProject/SPMFeatureTestsProject.xcodeproj -s SPMFeatureTestsProject --ignore-names "AppDelegate,ViewController"
    func test_publicProtocolWithMethodsWhenNotIgnorePublic_sendsCorrectNonObfuscatedFileContentToDelegate3() throws {
        let (obfs, store, delegate) = SPMFeatureTestUtils.baseTestData(ignorePublic: true)
        let (internalLibraryModule, libraryModule, appModule) = try SPMFeatureTestUtils.testModule(
            withAppContents: """
            import MyLibrary

            let someImpl = SomeImpl()
            """,
            withLibraryContents: """
            public protocol TransactionUseCase {

                func getUserDepositAccount(
                completion: @escaping (Result<String?, Error>) -> Void
                )

                func getTransactions(
                    request: String,
                    completion: @escaping (Result<String, Error>) -> Void
                )

                func getCalendarActivity(
                completion: @escaping (Result<String, Error>) -> Void
                )
            }

            public final class DBTransactionUseCase: TransactionUseCase {

                public init() {}

                deinit {}

                public func getUserDepositAccount(
                completion: @escaping (Result<String?, Error>) -> Void
                ) {}

                public func getTransactions(
                    request: String,
                    completion: @escaping (Result<String, Error>) -> Void
                ) {}

                @discardableResult
                public func getCalendarActivity(
                    completion: @escaping (Result<String, Error>) -> Void
                ) {}
            }
            """
        )

        store.obfuscationDictionary["getUserDepositAccount"] = "OBS1"
        store.obfuscationDictionary["getTransactions"] = "OBS2"
        store.obfuscationDictionary["getCalendarActivity"] = "OBS3"
        store.obfuscationDictionary["TransactionUseCase"] = "OBS4"
        store.obfuscationDictionary["DBTransactionUseCase"] = "OBS5"

        try obfs.registerModuleForObfuscation(internalLibraryModule)
        try obfs.registerModuleForObfuscation(libraryModule)
        try obfs.registerModuleForObfuscation(appModule)
        try obfs.obfuscate()

        //        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableAppFilePath], """
        //        import MyLibrary
        //
        //        let someImpl = OBS1()
        //        """)

        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableLibraryFilePath], """
        public protocol TransactionUseCase {

            func getUserDepositAccount(
            completion: @escaping (Result<String?, Error>) -> Void
            )

            func getTransactions(
                request: String,
                completion: @escaping (Result<String, Error>) -> Void
            )

            func getCalendarActivity(
            completion: @escaping (Result<String, Error>) -> Void
            )
        }

        public final class DBTransactionUseCase: TransactionUseCase {

            public init() {}

            deinit {}

            public func getUserDepositAccount(
            completion: @escaping (Result<String?, Error>) -> Void
            ) {}

            public func getTransactions(
                request: String,
                completion: @escaping (Result<String, Error>) -> Void
            ) {}

            @discardableResult
            public func getCalendarActivity(
                completion: @escaping (Result<String, Error>) -> Void
            ) {}
        }
        """)
    }

    func test_publicProtocolWithMethodsWhenNotIgnorePublic_sendsCorrectNonObfuscatedFileContentToDelegate2() throws {
        let (obfs, store, delegate) = SPMFeatureTestUtils.baseTestData(ignorePublic: true)
        let (internalLibraryModule, libraryModule, appModule) = try SPMFeatureTestUtils.testModule(
            withAppContents: """
            import MyLibrary

            let someImpl = SomeImpl()
            """,
            withLibraryContents: """
            public class SomeImpl: SomeProtocol {
                public func someFunc() -> Bool {
                    return true
                }
            }
            public protocol SomeProtocol {
                func someFunc() -> Bool
            }
            """
        )

        store.obfuscationDictionary["SomeImpl"] = "OBS1"
        store.obfuscationDictionary["SomeProtocol"] = "OBS2"
        store.obfuscationDictionary["someFunc"] = "OBS3"

        try obfs.registerModuleForObfuscation(internalLibraryModule)
        try obfs.registerModuleForObfuscation(libraryModule)
        try obfs.registerModuleForObfuscation(appModule)
        try obfs.obfuscate()

//        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableAppFilePath], """
//        import MyLibrary
//
//        let someImpl = OBS1()
//        """)

        XCTAssertEqual(delegate.receivedContent[SPMFeatureTestUtils.modifiableLibraryFilePath], """
        public class SomeImpl: SomeProtocol {
            public func someFunc() -> Bool {
                return true
            }
        }
        public protocol SomeProtocol {
            func someFunc() -> Bool
        }
        """)
    }
}

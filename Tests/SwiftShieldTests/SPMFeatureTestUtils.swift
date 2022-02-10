//
//  File.swift
//  
//
//  Created by Binh An Tran on 10/2/22.
//

import Foundation
@testable import SwiftShieldCore

enum SPMFeatureTestUtils {

    static var modifiableAppFilePath: String {
        path(forResource: "SPMFeatureTestsProject/SPMFeatureTestsProject/AppFile.swift").relativePath
    }

    static func modifiableAppFileContents() throws -> String {
        try File(path: modifiableAppFilePath).read()
    }

        static var modifiableLibraryFilePath: String {
        path(forResource: "SPMFeatureTestsProject/MyLibrary/Sources/MyLibrary/LibraryFile.swift").relativePath
    }

    static func modifiableLibraryFileContents() throws -> String {
        try File(path: modifiableLibraryFilePath).read()
    }

    static var modifiablePlistPath: String {
        path(forResource: "FeatureTestProject/FeatureTestProject/CustomPlist.plist").relativePath
    }

    static func modifiablePlistContents() throws -> String {
        try File(path: modifiablePlistPath).read()
    }

    static func testModule(
        withAppContents appContents: String = "",
        withLibraryContents libraryContents: String = "",
        withPlist plistContents: String =
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        </dict>
        </plist>
        """
    ) throws -> (library: Module, app: Module) {
        let projectPath = path(forResource: "SPMFeatureTestsProject/SPMFeatureTestsProject.xcodeproj").relativePath
        let projectFile = File(path: projectPath)
        let provider = SchemeInfoProvider(
            projectFile: projectFile,
            schemeName: "SPMFeatureTestsProject",
            taskRunner: TaskRunner(),
            logger: DummyLogger(),
            modulesToIgnore: []
        )

        try File(path: modifiableAppFilePath).write(contents: appContents)
        try File(path: modifiableLibraryFilePath).write(contents: libraryContents)
        try File(path: modifiablePlistPath).write(contents: plistContents)

        let modules = try provider.getModulesFromProject()
        return (modules[0], modules[1])
    }

    static func baseTestData(ignorePublic: Bool = false,
                      namesToIgnore: Set<String> = []) -> (SourceKitObfuscator, SourceKitObfuscatorDataStore, ObfuscatorDelegateSpy) {
        let logger = Logger()
        let sourceKit = SourceKit(logger: logger)
        let dataStore = SourceKitObfuscatorDataStore()
        let obfuscator = SourceKitObfuscator(
            sourceKit: sourceKit,
            logger: logger,
            dataStore: dataStore,
            namesToIgnore: namesToIgnore,
            ignorePublic: ignorePublic
        )
        let delegateSpy = ObfuscatorDelegateSpy()
        obfuscator.delegate = delegateSpy
        return (obfuscator, dataStore, delegateSpy)
    }

}

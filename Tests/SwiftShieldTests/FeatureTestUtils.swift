import Foundation
@testable import SwiftShieldCore

var modifiableFilePath: String {
    path(forResource: "FeatureTestProject/FeatureTestProject/File.swift").relativePath
}

func modifiableFileContents() throws -> String {
    try File(path: modifiableFilePath).read()
}

var modifiablePlistPath: String {
    path(forResource: "FeatureTestProject/FeatureTestProject/CustomPlist.plist").relativePath
}

func modifiablePlistContents() throws -> String {
    try File(path: modifiablePlistPath).read()
}

func testModule(
    withContents contents: String = "",
    withPlist plistContents: String =
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        </dict>
        </plist>
        """
) throws -> Module {
    let projectPath = path(forResource: "FeatureTestProject/FeatureTestProject.xcodeproj").relativePath
    let projectFile = File(path: projectPath)
    let provider = SchemeInfoProvider(
        projectFile: projectFile,
        schemeName: "FeatureTestProject",
        taskRunner: TaskRunner(),
        logger: DummyLogger(),
        modulesToIgnore: [],
        includeIBXMLs: false
    )

    try File(path: modifiableFilePath).write(contents: contents)
    try File(path: modifiablePlistPath).write(contents: plistContents)

    return try provider.getModulesFromProject().first!
}

func baseTestData(ignorePublic: Bool = false,
                  namesToIgnore: Set<String> = []) -> (SourceKitObfuscator, SourceKitObfuscatorDataStore, ObfuscatorDelegateSpy) {
    let logger = Logger()
    let sourceKit = SourceKit(logger: logger)
    let dataStore = SourceKitObfuscatorDataStore()
    let obfuscator = SourceKitObfuscator(
        sourceKit: sourceKit,
        logger: logger,
        dataStore: dataStore,
        namesToIgnore: namesToIgnore,
        ignorePublic: ignorePublic,
        modulesToIgnore: []
    )
    let delegateSpy = ObfuscatorDelegateSpy()
    obfuscator.delegate = delegateSpy
    return (obfuscator, dataStore, delegateSpy)
}

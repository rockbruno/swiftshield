@testable import SwiftShieldCore
import XCTest

final class ProjectTests: XCTestCase {
    func test_pbxproj() throws {
        let file = Project(xcodeProjFile: File(path: "foo/bar.xcodeproj"))
        XCTAssertEqual(file.pbxProj, File(path: "foo/bar.xcodeproj/project.pbxproj"))
    }

    func test_workspace() throws {
        let workspaceContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace
        version = "1.0">
        <FileRef
            location = "group:Rapiddo.xcodeproj">
        </FileRef>
        <FileRef
            location = "group:Pods/Pods.xcodeproj">
        </FileRef>
        </Workspace>
        """
        let wkspaceTemp = temporaryFilePath(forFile: "foo.xcworkspace")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: wkspaceTemp),
            withIntermediateDirectories: false,
            attributes: nil
        )
        let dataTemp = wkspaceTemp + "/contents.xcworkspacedata"
        try File(path: dataTemp).write(contents: workspaceContent)
        let workspaceFile = File(path: wkspaceTemp)
        let workspace: Workspace = Workspace(workspaceFile: workspaceFile)
        let projects = try workspace.xcodeProjFiles()
        XCTAssertEqual(projects.count, 2)
        let workspaceRoot = URL(fileURLWithPath: wkspaceTemp).deletingLastPathComponent().relativePath
        XCTAssertEqual(projects.first?.xcodeProjFile, File(path: workspaceRoot + "/Rapiddo.xcodeproj"))
        XCTAssertEqual(projects.dropFirst().first?.xcodeProjFile, File(path: workspaceRoot + "/Pods/Pods.xcodeproj"))
    }

    func test_projectTagging() throws {
        let projectContent = """
        LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";
        OTHER_SWIFT_FLAGS = "$(inherited) \"-D\" \"COCOAPODS\" \"-D\" \"TESTS\"";
        PRODUCT_BUNDLE_IDENTIFIER = com.rockbruno.MarketplaceTests;
        PRODUCT_NAME = "$(TARGET_NAME)";
        PROVISIONING_PROFILE_SPECIFIER = "";
        """
        let projTemp = temporaryFilePath(forFile: "foo.xcodeproj")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: projTemp),
            withIntermediateDirectories: false,
            attributes: nil
        )
        let dataTemp = projTemp + "/project.pbxproj"
        let pbxProj = File(path: dataTemp)
        try pbxProj.write(contents: projectContent)
        let projectFile = Project(xcodeProjFile: File(path: projTemp))

        let result = try projectFile.markAsSwiftShielded()

        XCTAssertEqual(result, """
        LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";
        OTHER_SWIFT_FLAGS = "$(inherited) \"-D\" \"COCOAPODS\" \"-D\" \"TESTS\"";
        PRODUCT_BUNDLE_IDENTIFIER = com.rockbruno.MarketplaceTests;
        PRODUCT_NAME = "$(TARGET_NAME)";SWIFTSHIELDED = true;
        PROVISIONING_PROFILE_SPECIFIER = "";
        """)
    }
}

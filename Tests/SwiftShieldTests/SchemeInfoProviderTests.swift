@testable import SwiftShieldCore
import XCTest

final class SchemeInfoProviderTests: XCTestCase {
    func test_gettingModules_runsXcodebuildTask() {
        let logger = DummyLogger()
        let dummyFile = File(path: "./test.xcworkspace")
        let runnerFake = TaskRunnerFake()
        let provider = SchemeInfoProvider(
            projectFile: dummyFile,
            schemeName: "MyScheme",
            taskRunner: runnerFake,
            logger: logger,
            modulesToIgnore: []
        )

        _ = try? provider.getModulesFromProject()

        let expectedArgs: [String] = [
            "-workspace",
            "./test.xcworkspace",
            "-scheme",
            "MyScheme", "-sdk", "iphonesimulator",
            "clean",
            "build",
        ]

        XCTAssertEqual(runnerFake.receivedCommand, "/usr/bin/xcodebuild")
        XCTAssertEqual(runnerFake.receivedArgs, expectedArgs)
    }

    func test_gettingModules_withProject_runsXcodebuildTask_withProjectParam() {
        let logger = DummyLogger()
        let dummyFile = File(path: "./test.xcodeproj")
        let runnerFake = TaskRunnerFake()
        let provider = SchemeInfoProvider(
            projectFile: dummyFile,
            schemeName: "MyScheme",
            taskRunner: runnerFake,
            logger: logger,
            modulesToIgnore: []
        )

        _ = try? provider.getModulesFromProject()

        let expectedArgs: [String] = [
            "-project",
            "./test.xcodeproj",
            "-scheme",
            "MyScheme", "-sdk", "iphonesimulator",
            "clean",
            "build",
        ]

        XCTAssertEqual(runnerFake.receivedCommand, "/usr/bin/xcodebuild")
        XCTAssertEqual(runnerFake.receivedArgs, expectedArgs)
    }

    func test_onNilOutput_errorIsThrown() {
        let logger = DummyLogger()
        let dummyFile = File(path: "./test.xcworkspace")
        let runnerFake = TaskRunnerFake()
        let provider = SchemeInfoProvider(
            projectFile: dummyFile,
            schemeName: "MyScheme",
            taskRunner: runnerFake,
            logger: logger,
            modulesToIgnore: []
        )

        runnerFake.mockOutput = nil

        XCTAssertThrowsError(try provider.getModulesFromProject())
    }

    func test_onNonZeroStatusCode_errorIsThrown() {
        let logger = DummyLogger()
        let dummyFile = File(path: "./test.xcworkspace")
        let runnerFake = TaskRunnerFake()
        let provider = SchemeInfoProvider(
            projectFile: dummyFile,
            schemeName: "MyScheme",
            taskRunner: runnerFake,
            logger: logger,
            modulesToIgnore: []
        )

        runnerFake.shouldFail = true
        runnerFake.mockOutput = "Output"

        XCTAssertThrowsError(try provider.getModulesFromProject())
    }

    func test_onInvalidOutput_nothingIsReturned() throws {
        let logger = DummyLogger()
        let dummyFile = File(path: "./test.xcworkspace")
        let runnerFake = TaskRunnerFake()
        let provider = SchemeInfoProvider(
            projectFile: dummyFile,
            schemeName: "MyScheme",
            taskRunner: runnerFake,
            logger: logger,
            modulesToIgnore: []
        )

        runnerFake.mockOutput = "Output"

        let result = try provider.getModulesFromProject()
        XCTAssertTrue(result.isEmpty)
    }

    var exampleProjectModule: Module {
        let vc = File(path: path(forResource: "ExampleProject/ExampleProject/ViewController.swift").relativePath)
        let appDelegate = File(path: path(forResource: "ExampleProject/ExampleProject/AppDelegate.swift").relativePath)
        let sceneDelegate = File(path: path(forResource: "ExampleProject/ExampleProject/SceneDelegate.swift").relativePath)
        let info = File(path: path(forResource: "ExampleProject/ExampleProject/Info.plist").relativePath)
        return Module(
            name: "ExampleProject",
            sourceFiles: [vc, appDelegate, sceneDelegate],
            plists: [info],
            compilerArguments: []
        )
    }

    var anotherTargetModule: Module {
        let source = File(path: path(forResource: "ExampleProject/AnotherTarget/AnotherTargetSource.swift").relativePath)
        let info = File(path: path(forResource: "ExampleProject/AnotherTarget/Info.plist").relativePath)
        let customPlist = File(path: path(forResource: "ExampleProject/AnotherTarget/CustomPlist.plist").relativePath)
        return Module(
            name: "AnotherTarget",
            sourceFiles: [source],
            plists: [info, customPlist],
            compilerArguments: []
        )
    }

    func test_baseExtraction() throws {
        let projectPath = path(forResource: "ExampleProject/ExampleProject.xcodeproj").relativePath
        let projectFile = File(path: projectPath)
        let provider = SchemeInfoProvider(
            projectFile: projectFile,
            schemeName: "ExampleProject",
            taskRunner: TaskRunner(),
            logger: DummyLogger(),
            modulesToIgnore: []
        )
        let modules = try provider.getModulesFromProject()
        XCTAssertEqual(modules.map { $0.withoutCompilerArgs }, [anotherTargetModule, exampleProjectModule])
    }

    func test_baseExtraction_ignoringModule() throws {
        let projectPath = path(forResource: "ExampleProject/ExampleProject.xcodeproj").relativePath
        let projectFile = File(path: projectPath)
        let provider = SchemeInfoProvider(
            projectFile: projectFile,
            schemeName: "ExampleProject",
            taskRunner: TaskRunner(),
            logger: DummyLogger(),
            modulesToIgnore: ["AnotherTarget"]
        )
        let modules = try provider.getModulesFromProject()
        XCTAssertEqual(modules.map { $0.withoutCompilerArgs }, [exampleProjectModule])
    }

    func test_singleProject_tagging() throws {
        let projectContent = "PRODUCT_NAME = \"$(TARGET_NAME)\";"
        let projTemp = temporaryFilePath(forFile: "foo.xcodeproj")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: projTemp),
            withIntermediateDirectories: false,
            attributes: nil
        )
        let dataTemp = projTemp + "/project.pbxproj"
        let pbxProj = File(path: dataTemp)
        try pbxProj.write(contents: projectContent)
        let projectFile = File(path: projTemp)
        let project = Project(xcodeProjFile: projectFile)

        let provider = SchemeInfoProvider(
            projectFile: projectFile,
            schemeName: "Foo",
            taskRunner: TaskRunner(),
            logger: DummyLogger(),
            modulesToIgnore: []
        )

        let result = try provider.markProjectsAsObfuscated()
        XCTAssertEqual(result, [project.pbxProj: try project.markAsSwiftShielded()])
    }

    func test_workspace_tagging() throws {
        let projectContent = "PRODUCT_NAME = \"$(TARGET_NAME)\";"
        let projTemp = temporaryFilePath(forFile: "foo.xcodeproj")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: projTemp),
            withIntermediateDirectories: false,
            attributes: nil
        )
        let proj2Temp = temporaryFilePath(forFile: "bar.xcodeproj")
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: proj2Temp),
            withIntermediateDirectories: false,
            attributes: nil
        )
        try File(path: projTemp + "/project.pbxproj").write(contents: projectContent)
        try File(path: proj2Temp + "/project.pbxproj").write(contents: projectContent)

        let workspaceContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace
        version = "1.0">
        <FileRef
            location = "group:foo.xcodeproj">
        </FileRef>
        <FileRef
            location = "group:bar.xcodeproj">
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

        let provider = SchemeInfoProvider(
            projectFile: workspaceFile,
            schemeName: "Foo",
            taskRunner: TaskRunner(),
            logger: DummyLogger(),
            modulesToIgnore: []
        )

        let project = Project(xcodeProjFile: File(path: projTemp))
        let project2 = Project(xcodeProjFile: File(path: proj2Temp))

        let result = try provider.markProjectsAsObfuscated()
        XCTAssertEqual(result, [
            project.pbxProj: try project.markAsSwiftShielded(),
            project2.pbxProj: try project2.markAsSwiftShielded(),
        ])
    }
}

extension Module {
    // The compiler args change all the time, so its best to ignore them.
    var withoutCompilerArgs: Module {
        Module(name: name, sourceFiles: sourceFiles, plists: plists, compilerArguments: [])
    }
}

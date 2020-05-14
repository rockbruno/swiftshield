@testable import SwiftShieldCore
import XCTest

private final class FakeDelegate: SwiftShieldInteractorDelegate {
    var theReturn: Error?
    var fileReceived: File!
    var contentsReceived: String!
    func interactor(_: SwiftShieldInteractorProtocol, didPrepare file: File, withContents contents: String) -> Error? {
        fileReceived = file
        contentsReceived = contents
        return theReturn
    }
}

final class SwiftShieldInteractorTests: XCTestCase {
    func test_gettingModules_callsProvider() throws {
        let providerFake = SchemeInfoProviderFake()
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: providerFake,
            logger: DummyLogger(),
            obfuscator: ObfuscatorFake()
        )

        let fakeModule = Module(name: "foo", sourceFiles: [], plists: [], compilerArguments: ["bar"])
        providerFake.modulesToReturn = [fakeModule]

        let result = try interactor.getModulesFromProject()

        XCTAssertEqual(result, [fakeModule])
    }

    func test_obfuscatingModules_registersTargetsThenObfuscates() throws {
        let obfuscatorFake = ObfuscatorFake()
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: SchemeInfoProviderFake(),
            logger: DummyLogger(),
            obfuscator: obfuscatorFake
        )

        let fakeModule = Module(name: "foo", sourceFiles: [], plists: [], compilerArguments: ["bar"])
        let fakeModule2 = Module(name: "bar", sourceFiles: [], plists: [], compilerArguments: ["foo"])

        obfuscatorFake.mapToReturn = ConversionMap(obfuscationDictionary: ["a": "b"])
        let map = try interactor.obfuscate(modules: [fakeModule, fakeModule2])

        XCTAssertEqual(obfuscatorFake.registered, [fakeModule2, fakeModule])
        XCTAssertEqual(obfuscatorFake.registerCountWhenCallingObfuscate, 2)
        XCTAssertEqual(map, obfuscatorFake.mapToReturn)
    }

    func test_obfuscatorDelegate_isRoutedToDelegate() throws {
        let obfuscatorFake = ObfuscatorFake()
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: SchemeInfoProviderFake(),
            logger: DummyLogger(),
            obfuscator: obfuscatorFake
        )

        let delegate = FakeDelegate()
        interactor.delegate = delegate

        let file = File(path: "")
        let contents = "bla"
        func call() -> Error? {
            obfuscatorFake.delegate?.obfuscator(obfuscatorFake, didObfuscateFile: file, newContents: contents)
        }

        XCTAssertNil(call())
        XCTAssertEqual(delegate.fileReceived, file)
        XCTAssertEqual(delegate.contentsReceived, contents)

        let someError = NSError(domain: "", code: 4, userInfo: nil)
        delegate.theReturn = someError

        XCTAssertTrue(someError === call()! as NSError)
    }

    func test_mapPreparation_isSentToDelegate() throws {
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: SchemeInfoProviderFake(),
            logger: DummyLogger(),
            obfuscator: ObfuscatorFake()
        )

        let delegate = FakeDelegate()
        interactor.delegate = delegate

        let map = ConversionMap(obfuscationDictionary: ["abc": "def"])
        let date = Date(timeIntervalSince1970: 1000)
        try interactor.prepare(map: map, date: date)

        let finalMapPath = map.outputPath(
            projectPath: "fakePath/path.xcodeproj",
            date: date,
            filePrefix: "fakeScheme"
        )
        let finalMapFile = File(path: finalMapPath)

        XCTAssertEqual(delegate.fileReceived, finalMapFile)
        XCTAssertEqual(delegate.contentsReceived, map.toString(info: "fakeScheme"))
    }

    func test_mapPreparation_throwsOnDelegateThrow() throws {
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: SchemeInfoProviderFake(),
            logger: DummyLogger(),
            obfuscator: ObfuscatorFake()
        )

        let delegate = FakeDelegate()
        interactor.delegate = delegate

        let someError = NSError(domain: "", code: 4, userInfo: nil)
        delegate.theReturn = someError

        let map = ConversionMap(obfuscationDictionary: ["abc": "def"])
        let date = Date(timeIntervalSince1970: 1000)
        XCTAssertThrowsError(try interactor.prepare(map: map, date: date))
    }

    func test_tagging_callsProvider_andSendsToDelegate() throws {
        let providerFake = SchemeInfoProviderFake()
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: providerFake,
            logger: DummyLogger(),
            obfuscator: ObfuscatorFake()
        )

        let delegate = FakeDelegate()
        interactor.delegate = delegate

        let fakeFile = File(path: "bla.xcodeproj")
        let fakeProject = Project(xcodeProjFile: fakeFile)
        providerFake.markedProjectsToReturn = [fakeProject.pbxProj: "bla"]
        try interactor.markProjectsAsObfuscated()

        XCTAssertTrue(providerFake.markProjectsAsObfuscatedCalled)
        XCTAssertEqual(delegate.fileReceived, fakeProject.pbxProj)
        XCTAssertEqual(delegate.contentsReceived, "bla")
    }

    func test_interactorHalts_ifTaggingDelegateThrows() throws {
        let providerFake = SchemeInfoProviderFake()
        let interactor = SwiftShieldInteractor(
            schemeInfoProvider: providerFake,
            logger: DummyLogger(),
            obfuscator: ObfuscatorFake()
        )

        let delegate = FakeDelegate()
        interactor.delegate = delegate

        let someError = NSError(domain: "", code: 4, userInfo: nil)
        delegate.theReturn = someError

        let fakeFile = File(path: "bla.xcodeproj")
        let fakeProject = Project(xcodeProjFile: fakeFile)
        providerFake.markedProjectsToReturn = [fakeProject.pbxProj: "bla"]

        XCTAssertThrowsError(try interactor.markProjectsAsObfuscated())
    }
}

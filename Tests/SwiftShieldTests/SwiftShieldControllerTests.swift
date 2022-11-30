@testable import SwiftShieldCore
import XCTest

final class SwiftShieldControllerTests: XCTestCase {
    func test_isInteractorDelegate() {
        let fakeInteractor = SwiftShieldInteractorFake()
        let controller = SwiftShieldController(
            interactor: fakeInteractor,
            logger: DummyLogger(),
            dryRun: false
        )
        XCTAssertTrue(controller.interactor.delegate === controller)
    }

    func test_delegate_writes() throws {
        let fakeInteractor = SwiftShieldInteractorFake()
        let controller = SwiftShieldController(
            interactor: fakeInteractor,
            logger: DummyLogger(),
            dryRun: false
        )

        let fakeFilePath = temporaryFilePath(forFile: "contwrite.txt")
        let file = File(path: fakeFilePath)

        XCTAssertNil(controller.interactor(fakeInteractor, didPrepare: file, withContents: "bla"))
        XCTAssertEqual(try file.read(), "bla")
    }

    func test_delegate_failsIfWritingFileFails() throws {
        let fakeInteractor = SwiftShieldInteractorFake()
        let controller = SwiftShieldController(
            interactor: fakeInteractor,
            logger: DummyLogger(),
            dryRun: false
        )

        let fakeFilePath = temporaryFilePath(forFile: "contwrite.xcodeproj/cantWriteInMissingFolder")
        let file = File(path: fakeFilePath)

        XCTAssertNotNil(controller.interactor(fakeInteractor, didPrepare: file, withContents: "bla"))
        XCTAssertThrowsError(try file.read())
    }

    func test_delegate_doesntWriteInDryRun() throws {
        let fakeInteractor = SwiftShieldInteractorFake()
        let controller = SwiftShieldController(
            interactor: fakeInteractor,
            logger: DummyLogger(),
            dryRun: true
        )

        let fakeFilePath = temporaryFilePath(forFile: "contwritedryRun.txt")
        let file = File(path: fakeFilePath)

        XCTAssertNil(controller.interactor(fakeInteractor, didPrepare: file, withContents: "bla"))
        XCTAssertThrowsError(try file.read())
    }

    func test_run() throws {
        let fakeInteractor = SwiftShieldInteractorFake()
        let controller = SwiftShieldController(
            interactor: fakeInteractor,
            logger: DummyLogger(),
            dryRun: true
        )

        let module = Module(name: "foo", sourceFiles: [], plists: [], ibxmls: [], compilerArguments: [])
        fakeInteractor.modulesToReturn = [module]
        let map = ConversionMap(obfuscationDictionary: ["foo": "bar"])
        fakeInteractor.conversionMapToReturn = map

        try controller.run()

        XCTAssertEqual(fakeInteractor.obfuscateReceivedModule, [module])
        XCTAssertTrue(fakeInteractor.markProjectsCalled)
        XCTAssertEqual(fakeInteractor.prepareMapSentMap, map)
    }
}

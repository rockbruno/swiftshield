@testable import SwiftShieldCore
import XCTest

func temporaryFilePath(forFile path: String) -> String {
    let dict = NSTemporaryDirectory()
    return dict.appending("/").appending(path)
}

final class FileTests: XCTestCase {
    func test_read_readsFile() throws {
        let tempFile = "ssdFileRead.txt"
        let contents = "testContents"
        let path = temporaryFilePath(forFile: tempFile)
        let file = File(path: path)

        try contents.write(toFile: path, atomically: false, encoding: .utf8)

        let readContents = try file.read()
        XCTAssertEqual(readContents, contents)
    }

    func test_write_writesContentsToFile() throws {
        let tempFile = "ssdFileWrite.txt"
        let contents = "testContents"
        let path = temporaryFilePath(forFile: tempFile)
        let file = File(path: path)

        try file.write(contents: contents)

        let readContents = try file.read()
        XCTAssertEqual(readContents, contents)
    }

    func test_name() throws {
        let tempFile = "ssdName.txt"
        let path = temporaryFilePath(forFile: tempFile)
        let file = File(path: path)
        XCTAssertEqual(file.name, "ssdName.txt")
        XCTAssertNotEqual(file.path, "ssdName.txt")
        XCTAssertTrue(file.path.hasSuffix("ssdName.txt"))
    }
}

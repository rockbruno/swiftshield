import XCTest
@testable import MyLibrary

final class MyLibraryTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MyLibrary().text, "Hello, World!")
    }
}

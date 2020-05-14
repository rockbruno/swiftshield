@testable import SwiftShieldCore
import XCTest

final class TaskRunnerTests: XCTestCase {
    func test_successfulEcho() {
        let runner = TaskRunner()
        let result = runner.runTask(withCommand: "/bin/echo", arguments: ["foo"])
        XCTAssertEqual(result.output, "foo\n")
        XCTAssertEqual(result.terminationStatus, 0)
    }

    func test_failedCommand() {
        let runner = TaskRunner()
        let result = runner.runTask(withCommand: "/bin/kill", arguments: ["bar"])
        XCTAssertEqual(result.output, "kill: illegal process id: bar\n")
        XCTAssertEqual(result.terminationStatus, 2)
    }
}

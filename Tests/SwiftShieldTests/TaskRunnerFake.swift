import Foundation
@testable import SwiftShieldCore

final class TaskRunnerFake: TaskRunnerProtocol {
    var shouldFail = false
    var mockOutput: String? = ""
    var receivedCommand = ""
    var receivedArgs: [String] = []

    func runTask(withCommand command: String, arguments: [String]) -> TaskRunnerOutput {
        receivedCommand = command
        receivedArgs = arguments
        if shouldFail {
            return TaskRunnerOutput(output: "", terminationStatus: 1)
        } else {
            return TaskRunnerOutput(output: mockOutput, terminationStatus: 0)
        }
    }
}

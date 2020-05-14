import Foundation

protocol TaskRunnerProtocol {
    func runTask(withCommand command: String, arguments: [String]) -> TaskRunnerOutput
}

struct TaskRunnerOutput: Hashable {
    let output: String?
    let terminationStatus: Int32
}

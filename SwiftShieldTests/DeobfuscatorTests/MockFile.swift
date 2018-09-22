import Foundation

final class MockFile: File {
    let data: String
    var writtenData: String = ""

    init(data: String) {
        self.data = data
        super.init(filePath: "")
    }

    override func read() -> String {
        return data
    }

    override func write(_ text: String) {
        writtenData = text
    }
}

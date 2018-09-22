import Foundation

class File {
    let path: String

    var name: String {
        return (path as NSString).lastPathComponent
    }
    
    init(filePath: String) {
        self.path = filePath
    }

    func read() -> String {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            Logger.log(.fatal(error: error.localizedDescription))
            exit(error: true)
        }
    }

    func write(_ text: String) {
        do {
            try text.write(toFile: path, atomically: false, encoding: .utf8)
        } catch {
            Logger.log(.fatal(error: error.localizedDescription))
            exit(error: true)
        }
    }
}

extension File: Hashable {
    var hashValue: Int {
        return path.hashValue
    }

    static func ==(lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
}

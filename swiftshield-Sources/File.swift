import Foundation

struct File {
    let path: String

    var name: String {
        return (path as NSString).lastPathComponent
    }
    
    init(filePath: String) {
        self.path = filePath
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

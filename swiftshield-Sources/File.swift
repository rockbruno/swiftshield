import Foundation

class File: Hashable {
    let path: String
    var name: String {
        return (path as NSString).lastPathComponent
    }
    
    var hashValue: Int {
        return path.hashValue
    }
    
    public static func ==(lhs: File, rhs: File) -> Bool {
        return lhs.path == rhs.path
    }
    
    init(filePath: String) {
        self.path = filePath
    }
}

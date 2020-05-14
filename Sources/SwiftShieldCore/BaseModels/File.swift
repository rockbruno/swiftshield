import Foundation

/// Object representation of an xcodeproj's file entry.
struct File: Hashable {
    let path: String

    /// The name portion of the file's path.
    var name: String {
        (path as NSString).pathComponents.last ?? ""
    }

    /// Returns the disk contents of the file.
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Writes contents to the file.
    func write(contents: String) throws {
        try contents.write(toFile: path, atomically: false, encoding: .utf8)
    }
}

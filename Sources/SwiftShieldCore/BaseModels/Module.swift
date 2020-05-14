import Foundation

/// The representation of a Xcode project's target.
struct Module: Hashable {
    let name: String
    let sourceFiles: Set<File>
    let plists: Set<File>
    let compilerArguments: [String]
}

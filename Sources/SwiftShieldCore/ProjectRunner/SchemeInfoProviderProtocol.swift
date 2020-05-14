import Foundation

/// A protocol representing a type that extracts information from a Xcode project, relevant to a specific scheme.
protocol SchemeInfoProviderProtocol {
    /// The project file represented by this protocol.
    var projectFile: File { get }

    /// The scheme from where information should be extracted from.
    var schemeName: String { get }

    /// The modules to ignore.
    var modulesToIgnore: Set<String> { get }

    /// Retrieves .pbxproj targets from the relevant Xcode project by building it.
    func getModulesFromProject() throws -> [Module]

    /// Returns the contents of the projects with SWIFTSHIELDED=TRUE
    func markProjectsAsObfuscated() throws -> [File: String]
}

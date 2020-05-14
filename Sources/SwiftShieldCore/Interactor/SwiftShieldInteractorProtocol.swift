import Foundation

protocol SwiftShieldInteractorProtocol: AnyObject {
    var delegate: SwiftShieldInteractorDelegate? { get set }

    /// Retrieves .pbxproj targets from the relevant Xcode project.
    func getModulesFromProject() throws -> [Module]

    /// Starts the obfuscation process for a set of modules.
    /// During the obfuscation process, the status each individual file is sent to the delegate.
    ///
    /// - Parameters:
    ///   - modules: The modules to obfuscate.
    /// - Returns: The final conversion map.
    func obfuscate(modules: [Module]) throws -> ConversionMap

    /// Tags projects with SWIFTSHIELDED=TRUE
    func markProjectsAsObfuscated() throws

    func prepare(map: ConversionMap, date: Date) throws
}

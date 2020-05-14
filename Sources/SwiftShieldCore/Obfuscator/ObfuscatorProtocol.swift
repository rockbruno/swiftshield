import Foundation

/// An `ObfuscatorProtocol` abstracts the process of obfuscating files from a module.
/// Modules are registered to the obfuscator, which can be used to pre-process information inside the obfuscator.
/// After all modules were registered, the `Obfuscator` can start sending events to the assigned delegate.
protocol ObfuscatorProtocol: AnyObject {
    var delegate: ObfuscatorDelegate? { get set }

    /// Registers a module to be obfuscated.
    ///
    /// - Parameters:
    ///   - module: The module to register.
    func registerModuleForObfuscation(_ module: Module) throws

    /// Obfuscates the registered modules.
    /// To register modules for obfuscation, call `registerModuleForObfuscation`.
    /// During obfuscation, each obfuscated file will result in a single delegate call indicating the status of the obfuscation.
    /// Returns the final conversion map.
    func obfuscate() throws -> ConversionMap
}

protocol ObfuscatorDelegate: AnyObject {
    /// Delegate method called when a file was successfully obfuscated.
    ///
    /// - Parameters:
    ///   - obfuscator: The obfuscator.
    ///   - file: The file that was obfuscated.
    ///   - newContents: The obfuscated contents of the file.
    /// - Returns: An error indicating if the obfuscation process should stop, for example if saving the file fails.
    func obfuscator(
        _ obfuscator: ObfuscatorProtocol,
        didObfuscateFile file: File,
        newContents: String
    ) -> Error?
}

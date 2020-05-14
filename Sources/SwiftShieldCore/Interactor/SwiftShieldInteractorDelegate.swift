import Foundation

protocol SwiftShieldInteractorDelegate: AnyObject {
    /// A delegate method called when a file's contents are ready to be saved.
    ///
    /// - Parameters:
    ///   - file: The file that needs to be saved.
    ///   - newContents: The new contents of the file.
    /// - Returns: An error indicating if the interactor should stop, for example if saving the file fails.
    func interactor(
        _ interactor: SwiftShieldInteractorProtocol,
        didPrepare file: File,
        withContents contents: String
    ) -> Error?
}

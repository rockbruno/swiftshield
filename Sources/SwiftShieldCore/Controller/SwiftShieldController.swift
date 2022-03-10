import Foundation

public final class SwiftShieldController {
    let interactor: SwiftShieldInteractorProtocol
    let logger: LoggerProtocol
    let dryRun: Bool

    init(
        interactor: SwiftShieldInteractorProtocol,
        logger: LoggerProtocol,
        dryRun: Bool
    ) {
        self.interactor = interactor
        self.logger = logger
        self.dryRun = dryRun
        interactor.delegate = self
    }

    public func run() throws {
        do {
            logger.log("--- Getting modules from Xcode")
            let modules = try interactor.getModulesFromProject()
            logger.log("--- Starting main obfuscation procedure")
            if let map = try? interactor.obfuscate(modules: modules) {
                logger.log("--- Tagging projects")
                try interactor.markProjectsAsObfuscated()
                logger.log("--- Preparing conversion map")
                try interactor.prepare(map: map, date: Date())
            }
        } catch {
            logger.log("❌ Run Error: \(error)")
            throw error
        }
    }
}

extension SwiftShieldController: SwiftShieldInteractorDelegate {
    func interactor(_: SwiftShieldInteractorProtocol, didPrepare file: File, withContents contents: String) -> Error? {
        guard dryRun == false else {
            return nil
        }
        logger.log("--- Saving \(file.name)")
        logger.log("--- Full path: \(file.path)", verbose: true)
        do {
            try file.write(contents: contents)
            return nil
        } catch {
            return error
        }
    }
}

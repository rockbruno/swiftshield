import Foundation

final class SwiftShieldInteractor: SwiftShieldInteractorProtocol {
    weak var delegate: SwiftShieldInteractorDelegate?

    let schemeInfoProvider: SchemeInfoProviderProtocol
    let logger: LoggerProtocol
    let obfuscator: ObfuscatorProtocol

    init(
        schemeInfoProvider: SchemeInfoProviderProtocol,
        logger: LoggerProtocol,
        obfuscator: ObfuscatorProtocol
    ) {
        self.schemeInfoProvider = schemeInfoProvider
        self.logger = logger
        self.obfuscator = obfuscator
        obfuscator.delegate = self
    }

    func getModulesFromProject() throws -> [Module] {
        try schemeInfoProvider.getModulesFromProject()
    }

    func obfuscate(modules: [Module]) throws -> ConversionMap {
        try modules.forEach(obfuscator.registerModuleForObfuscation)
        return try obfuscator.obfuscate()
    }

    func markProjectsAsObfuscated() throws {
        let contents = try schemeInfoProvider.markProjectsAsObfuscated()
        try contents.forEach {
            if let error = delegate?.interactor(self, didPrepare: $0.key, withContents: $0.value) {
                throw error
            }
        }
    }

    func prepare(map: ConversionMap, date: Date) throws {
        let outputPrefix = schemeInfoProvider.schemeName
        let projectPath = schemeInfoProvider.projectFile.path
        let finalMapPath = map.outputPath(
            projectPath: projectPath,
            date: date,
            filePrefix: outputPrefix
        )
        let mapFile = File(path: finalMapPath)
        let content = map.toString(info: outputPrefix)
        if let error = delegate?.interactor(self, didPrepare: mapFile, withContents: content) {
            throw error
        }
    }
}

extension SwiftShieldInteractor: ObfuscatorDelegate {
    func obfuscator(_: ObfuscatorProtocol, didObfuscateFile file: File, newContents: String) -> Error? {
        delegate?.interactor(self, didPrepare: file, withContents: newContents)
    }
}

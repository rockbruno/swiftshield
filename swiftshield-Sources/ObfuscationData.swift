import Foundation

class ObfuscationData {
    let files: [File]
    let storyboards: [File]

    var obfuscationDict: [String: String] = [:]

    var allObfuscatedNames: Set<String> {
        return Set(obfuscationDict.values)
    }

    init(files: [File] = [], storyboards: [File] = []) {
        self.files = files
        self.storyboards = storyboards
    }
}

final class AutomaticObfuscationData: ObfuscationData {

    let modules: [Module]

    var usrDict: Set<String> = []
    var referencesDict: [File: [ReferenceData]] = [:]
    var usrRelationDict: [String: sourcekitd_variant_t] = [:]
    var indexedFiles: [(File,sourcekitd_response_t)] = []

    var moduleNames: Set<String> {
        return Set(modules.compactMap { $0.name })
    }

    var plists: [File] {
        return modules.compactMap { $0.plist }
    }

    var mainPlist: File? {
        return modules.last?.plist
    }

    init(modules: [Module] = []) {
        self.modules = modules
        let files = modules.flatMap { $0.sourceFiles }
        let storyboards = modules.flatMap { $0.xibFiles }
        super.init(files: files, storyboards: storyboards)
    }
}

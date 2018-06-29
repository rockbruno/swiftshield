import Foundation

final class ObfuscationData {
    var usrDict: Set<String> = []
    var referencesDict: [File:[ReferenceData]] = [:]
    var obfuscationDict: [String:String] = [:]
    var indexedFiles: [(File,sourcekitd_response_t)] = []
    
    func add(reference: ReferenceData, toFile file: File) {
        if referencesDict[file] == nil {
            referencesDict[file] = []
        }
        referencesDict[file]?.append(reference)
    }
}

import Foundation

final class ObfuscationData {
    var usrDict: Set<String> = []
    var referencesDict: [File: [ReferenceData]] = [:]
    var obfuscationDict: [String: String] = [:]
    var usrRelationDict: [String: sourcekitd_variant_t] = [:]
    var indexedFiles: [(File,sourcekitd_response_t)] = []
    var allObfuscatedNames: Set<String> = []
    var storyboardsToObfuscate: [File] = []
    var moduleNames: Set<String>? = nil
}

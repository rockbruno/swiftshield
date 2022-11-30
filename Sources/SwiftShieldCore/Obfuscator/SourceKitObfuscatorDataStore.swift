import Foundation

final class SourceKitObfuscatorDataStore {
    var processedUsrs = Set<String>()
    var obfuscationDictionary = [String: String]()
    var obfuscatedNames = Set<String>()
    var usrRelationDictionary = [String: SKResponseDictionary]()
    var indexedFiles = [IndexedFile]()
    var plists = Set<File>()
    var ibxmls = Set<File>()
    var inheritsFromX = [String: [String: Bool]]()
    var fileForUSR = [String: File]()
}

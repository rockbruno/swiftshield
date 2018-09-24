import Foundation

struct Deobfuscator {
    static func deobfuscate(file: File, mapFile: File) {
        let namesDictionary = Deobfuscator.process(mapFileContent: mapFile.read())
        let content = file.read()
        let result = replace(content: content, withContentsOf: namesDictionary)
        file.write(result)
    }

    static func process(mapFileContent: String) -> [String: String] {
        let regex = mapFileContent.match(regex: "(.*) ===> (.*)")
        var dictionary = [String: String]()
        for match in regex {
            let originalName = match.captureGroup(1, originalString: mapFileContent)
            let obfuscatedName = match.captureGroup(2, originalString: mapFileContent)
            dictionary[obfuscatedName] = originalName
        }
        return dictionary
    }

    static func replace(content: String, withContentsOf dictionary: [String: String]) -> String {
        let regexString = Array(dictionary.keys).joined(separator: "|")
        var offset = 0
        var content = content
        for match in content.match(regex: regexString) {
            let range = match.adjustingRanges(offset: offset).range
            let startIndex = content.index(content.startIndex, offsetBy: range.location)
            let endIndex = content.index(startIndex, offsetBy: range.length)
            let obfuscatedName = String(content[startIndex..<endIndex])
            let originalName = dictionary[obfuscatedName]!
            offset += originalName.count - obfuscatedName.count
            content.replaceSubrange(startIndex..<endIndex, with: originalName)
        }
        return content
    }
}

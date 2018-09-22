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
            dictionary[originalName] = obfuscatedName
        }
        return dictionary
    }

    static func replace(content: String, withContentsOf dictionary: [String: String]) -> String {
        var content = content
        for (key, value) in dictionary {
            content = content.replacingOccurrences(of: value, with: key)
        }
        return content
    }
}

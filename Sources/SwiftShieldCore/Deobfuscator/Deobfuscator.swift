import Foundation

public struct Deobfuscator {
    let logger: LoggerProtocol

    public init(logger: LoggerProtocol = Logger()) {
        self.logger = logger
    }

    public func deobfuscate(crashFilePath: String, mapPath: String) throws {
        let crashFile = File(path: crashFilePath)
        let crash = try crashFile.read()
        let mapString = try File(path: mapPath).read()
        guard let map = ConversionMap(mapString: mapString) else {
            throw logger.fatalError(forMessage: "Failed to parse conversion map. Have you passed the correct file?")
        }
        let result = replace(crashLog: crash, withContentsOfMap: map)
        try crashFile.write(contents: result)
    }

    func replace(crashLog content: String, withContentsOfMap map: ConversionMap) -> String {
        logger.log("Deobfuscating crash log. This may take several minutes.")
        let dictionary = map.deobfuscationDictionary
        let regexString = Array(dictionary.keys).joined(separator: "|")
        var offset = 0
        var content = content
        for match in content.match(regex: regexString) {
            let range = match.adjustingRanges(offset: offset).range
            let startIndex = content.index(content.startIndex, offsetBy: range.location)
            let endIndex = content.index(startIndex, offsetBy: range.length)
            let obfuscatedName = String(content[startIndex ..< endIndex])
            let originalName = dictionary[obfuscatedName]!
            logger.log("Found obfuscated reference '\(obfuscatedName)' (originally '\(originalName)')", verbose: true)
            offset += originalName.count - obfuscatedName.count
            content.replaceSubrange(startIndex ..< endIndex, with: originalName)
        }
        return content
    }
}

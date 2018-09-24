import Foundation

final class ManualSwiftShield: Protector {
    let tag: String

    init(basePath: String, tag: String, protectedClassNameSize: Int) {
        self.tag = tag
        super.init(basePath: basePath, protectedClassNameSize: protectedClassNameSize)
    }

    override func protect() -> ObfuscationData {
        Logger.log(.tag(tag: tag))
        let files = getSourceFiles()
        Logger.log(.scanningDeclarations)
        let obfsData = ObfuscationData(files: files, storyboards: getStoryboardsAndXibs())
        obfsData.files.forEach { protect(file: $0, obfsData: obfsData) }
        return obfsData
    }

    private func protect(file: File, obfsData: ObfuscationData) {
        Logger.log(.checking(file: file))
        do {
            let fileString = try String(contentsOfFile: file.path, encoding: .utf8)
            let newFile = obfuscateReferences(fileString: fileString, obfsData: obfsData)
            try newFile.write(toFile: file.path, atomically: false, encoding: .utf8)
        } catch {
            Logger.log(.fatal(error: error.localizedDescription))
            exit(1)
        }
    }

    func obfuscateReferences(fileString content: String, obfsData: ObfuscationData) -> String {
        let regexString = "[a-zA-Z0-9_$]*\(tag)"
        var offset = 0
        var content = content
        for match in content.match(regex: regexString) {
            let range = match.adjustingRanges(offset: offset).range
            let startIndex = content.index(content.startIndex, offsetBy: range.location)
            let endIndex = content.index(startIndex, offsetBy: range.length)
            let originalName = String(content[startIndex..<endIndex])
            let obfuscatedName: String = {
                guard let protected = obfsData.obfuscationDict[originalName] else {
                    let protected = String.random(length: protectedClassNameSize,
                                                  excluding: obfsData.allObfuscatedNames)
                    obfsData.obfuscationDict[originalName] = protected
                    return protected
                }
                return protected
            }()
            Logger.log(.protectedReference(originalName: originalName,
                                           protectedName: obfuscatedName))
            offset += obfuscatedName.count - originalName.count
            content.replaceSubrange(startIndex..<endIndex, with: obfuscatedName)
        }
        return content
    }

    override func writeToFile(data: ObfuscationData) {
        writeToFile(data: data, path: "Manual", info: "Manual mode")
    }
}

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
        var obfsData = ObfuscationData()
        obfsData.storyboardsToObfuscate = getStoryboardsAndXibs()
        files.forEach { protect(file: $0, obfsData: &obfsData) }
        return obfsData
    }

    private func protect(file: File, obfsData: inout ObfuscationData) {
        Logger.log(.checking(file: file))
        do {
            let fileString = try String(contentsOfFile: file.path, encoding: .utf8)
            let newFile = obfuscateReferences(fileString: fileString, obfsData: &obfsData)
            try newFile.write(toFile: file.path, atomically: false, encoding: .utf8)
        } catch {
            Logger.log(.fatal(error: error.localizedDescription))
            exit(1)
        }
    }

    private func obfuscateReferences(fileString data: String, obfsData: inout ObfuscationData) -> String {
        var currentIndex = data.startIndex
        let matches = data.match(regex: String.regexFor(tag: tag))
        return matches.compactMap { result in
            let word = (data as NSString).substring(with: result.range(at: 0))
            let protectedName: String = {
                guard let protected = obfsData.obfuscationDict[word] else {
                    let protected = String.random(length: protectedClassNameSize, excluding: obfsData.allObfuscatedNames)
                    obfsData.obfuscationDict[word] = protected
                    obfsData.allObfuscatedNames.insert(protected)
                    return protected
                }
                return protected
            }()
            Logger.log(.protectedReference(originalName: word, protectedName: protectedName))
            let range: Range = currentIndex..<data.index(data.startIndex, offsetBy: result.range.location)
            currentIndex = data.index(range.upperBound, offsetBy: result.range.length)
            return data[range] + protectedName
        }.joined() + (currentIndex < data.endIndex ? data[currentIndex..<data.endIndex] : "")
    }

    override func writeToFile(data: ObfuscationData) {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        writeToFile(data: data, path: "Manual \(dateString)", fileName: "conversionMap.txt")
    }
}

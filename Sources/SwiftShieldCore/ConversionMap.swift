import Foundation

struct ConversionMap: Hashable {
    let obfuscationDictionary: [String: String]

    var deobfuscationDictionary: [String: String] {
        let deobfuscationArray = obfuscationDictionary.map { ($1, $0) }
        return Dictionary(uniqueKeysWithValues: deobfuscationArray)
    }

    init?(mapString: String) {
        let regex = mapString.match(regex: "(.*) ===> (.*)")
        guard regex.isEmpty == false else {
            return nil
        }
        var dictionary = [String: String]()
        for match in regex {
            let originalName = match.captureGroup(1, originalString: mapString)
            let obfuscatedName = match.captureGroup(2, originalString: mapString)
            dictionary[originalName] = obfuscatedName
        }
        obfuscationDictionary = dictionary
    }

    init(obfuscationDictionary: [String: String]) {
        self.obfuscationDictionary = obfuscationDictionary
    }

    func toString(info: String = "") -> String {
        let sortedDict = obfuscationDictionary.map { ($0.key, $0.value) }.sorted(by: <)
        return """
        //
        // SwiftShield Conversion Map
        // \(info)
        // Deobfuscate crash logs (or any text file) by running:
        // swiftshield deobfuscate
        //

        """ + sortedDict.reduce("") {
            $0 + "\n\($1.0) ===> \($1.1)"
        }
    }

    func outputPath(
        projectPath: String,
        date: Date = Date(),
        locale: Locale = Locale.current,
        timeZone: TimeZone = TimeZone.current,
        filePrefix: String = ""
    ) -> String {
        try? FileManager.default.createDirectory(at:
            URL(fileURLWithPath: outputPath(forProjectPath: projectPath)),
                                                 withIntermediateDirectories: false,
                                                 attributes: nil)
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: date)
        return "\(outputPath(forProjectPath: projectPath))/\(filePrefix)_\(dateString).txt"
    }

    private func outputPath(forProjectPath path: String) -> String {
        URL(fileURLWithPath: path).deletingLastPathComponent().relativePath + "/swiftshield-output"
    }
}

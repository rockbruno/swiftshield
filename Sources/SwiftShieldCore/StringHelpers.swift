import Foundation

typealias RegexClosure = ((NSTextCheckingResult) -> String?)

func firstMatch(for regex: String, in text: String) -> String? {
    matches(for: regex, in: text).first
}

func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range) }
    } catch {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

extension String {
    func match(regex: String) -> [NSTextCheckingResult] {
        let regex = try! NSRegularExpression(pattern: regex, options: [.caseInsensitive])
        let nsString = self as NSString
        return regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
    }
}

extension String {
    static var storyboardClassNameRegex: String {
        "((?<=customClass=\").*?(?=\" customModule)|(?<=action selector=\").*?(?=:\"))"
    }
}

extension String {
    var removingParameterInformation: String {
        components(separatedBy: "(").first ?? self
    }
}

extension String {
    private var spacedFolderPlaceholder: String {
        "\u{0}"
    }

    var replacingEscapedSpaces: String {
        replacingOccurrences(of: "\\ ", with: spacedFolderPlaceholder)
    }
    
    var removeEscapedSpaces: String {
        replacingOccurrences(of: "\\ ", with: " ")
    }

    var removingPlaceholder: String {
        replacingOccurrences(of: spacedFolderPlaceholder, with: " ")
    }
}

extension NSTextCheckingResult {
    func captureGroup(_ index: Int, originalString: String) -> String {
        let range = captureGroupRange(index, originalString: originalString)
        let substring = originalString[range]
        return String(substring)
    }

    func captureGroupRange(_ index: Int, originalString: String) -> Range<String.Index> {
        let groupRange = range(at: index)
        let groupStartIndex = originalString.index(originalString.startIndex,
                                                   offsetBy: groupRange.location)
        let groupEndIndex = originalString.index(groupStartIndex,
                                                 offsetBy: groupRange.length)
        return groupStartIndex ..< groupEndIndex
    }
}

extension String {
    /// Considers emoji scalars when counting.
    var utf8Count: Int {
        return utf8.count
    }
}

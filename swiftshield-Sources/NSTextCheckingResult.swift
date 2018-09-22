import Foundation

extension NSTextCheckingResult {
    func captureGroup(_ index: Int, originalString: String) -> String {
        let groupRange = range(at: index)
        let groupStartIndex = originalString.index(originalString.startIndex,
                                                   offsetBy: groupRange.location)
        let groupEndIndex = originalString.index(groupStartIndex,
                                                 offsetBy: groupRange.length)
        let substring = originalString[groupStartIndex..<groupEndIndex]
        return String(substring)
    }
}

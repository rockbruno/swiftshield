import Foundation

extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }

    func filter(_ array: [Element]) -> [Element] {
        var filtered = self
        for filter in array {
            guard let indexOf = filtered.firstIndex(of: filter) else {
                continue
            }
            filtered.remove(at: indexOf)
        }
        return filtered
    }
    
    //prevent index out of range
    public subscript(safe index: Index) -> Element? {
        (startIndex <= index && index < endIndex) ? self[index] : nil
    }
}

extension Array {
    func filterDuplicates(includeElement: (_ lhs: Element, _ rhs: Element) -> Bool) -> [Element] {
        var results = [Element]()

        forEach { element in
            let existingElements = results.filter {
                includeElement(element, $0)
            }
            if existingElements.count == 0 {
                results.append(element)
            }
        }

        return results
    }
}

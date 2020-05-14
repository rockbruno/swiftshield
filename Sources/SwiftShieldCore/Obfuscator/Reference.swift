import Foundation

struct Reference: Comparable, Hashable {
    let name: String
    let line: Int
    let column: Int

    static func < (lhs: Reference, rhs: Reference) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        } else if lhs.column != rhs.column {
            return lhs.column < rhs.column
        } else {
            return false
        }
    }
}

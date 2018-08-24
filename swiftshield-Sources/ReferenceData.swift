import Cocoa

class ReferenceData {
    let name: String
    let line: Int
    let column: Int
    
    init(name: String, line: Int, column: Int) {
        self.name = name
        self.line = line
        self.column = column
    }
}

func lesserPosition(_ e1: ReferenceData, _ e2: ReferenceData) -> Bool {
    if e1.line != e2.line {
        return e1.line < e2.line
    } else {
        return e1.column < e2.column
    }
}

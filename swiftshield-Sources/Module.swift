import Cocoa

struct Module {
    let name: String
    let sourceFiles: [File]
    let xibFiles: [File]
    let compilerArguments: [String]
    
    init(name: String, sourceFiles: [File], xibFiles: [File], compilerArguments: [String]) {
        self.name = name
        self.sourceFiles = sourceFiles
        self.xibFiles = xibFiles
        self.compilerArguments = compilerArguments
    }
}

extension Module: Equatable {
    static func ==(lhs: Module, rhs: Module) -> Bool {
        return lhs.name == rhs.name &&
               lhs.sourceFiles == rhs.sourceFiles &&
               lhs.xibFiles == rhs.xibFiles &&
               lhs.compilerArguments == rhs.compilerArguments
    }
}

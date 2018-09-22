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
               Set(lhs.sourceFiles) == Set(rhs.sourceFiles) &&
               Set(lhs.xibFiles) == Set(rhs.xibFiles) &&
               Set(lhs.compilerArguments) == Set(rhs.compilerArguments)
    }
}

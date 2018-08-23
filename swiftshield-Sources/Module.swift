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

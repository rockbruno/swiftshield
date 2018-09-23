import Cocoa

struct Module: Equatable {
    let name: String
    let sourceFiles: [File]
    let xibFiles: [File]
    let compilerArguments: [String]
    let plists: [File]

    var mainPlist: File? {
        return plists.last
    }
    
    init(name: String,
         sourceFiles: [File] = [],
         xibFiles: [File] = [],
         plists: [File] = [],
         compilerArguments: [String] = []) {
        self.name = name
        self.sourceFiles = sourceFiles
        self.xibFiles = xibFiles
        self.compilerArguments = compilerArguments
        self.plists = plists
    }
}

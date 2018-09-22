import Cocoa

struct Module: Equatable {
    let name: String
    let sourceFiles: [File]
    let xibFiles: [File]
    let compilerArguments: [String]
    let plist: File?
    
    init(name: String,
         sourceFiles: [File] = [],
         xibFiles: [File] = [],
         plist: File? = nil,
         compilerArguments: [String] = []) {
        self.name = name
        self.sourceFiles = sourceFiles
        self.xibFiles = xibFiles
        self.compilerArguments = compilerArguments
        self.plist = plist
    }
}

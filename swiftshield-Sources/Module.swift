import Cocoa

struct Module {
    let name: String
    let files: [File]
    let compilerArguments: [String]
    
    init(name: String, files: [File], compilerArguments: [String]) {
        self.name = name
        self.files = files
        self.compilerArguments = compilerArguments
    }
}

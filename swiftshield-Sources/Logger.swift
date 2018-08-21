import Foundation

enum LogType {
    //Automatic mode
    case buildingProject
    case compilerArgumentsError
    case found(module: String)
    case indexing(file: File)
    case indexError(file: File, error: String)
    case foundDeclaration(name: String, usr: String, newName: String)
    case searchingReferencesOfUsr
    case foundReference(name: String, usr: String, at: File, line: Int, column: Int)
    case projectError
    
    //Shared
    case overwriting(file: File)
    case fatal(error: String)
    case overwritingStoryboards
    case checking(file: File)
    case protectedReference(originalName: String, protectedName: String)
    case fileNotModified(file: File)
    case saving(file: File)
    case generatingConversionMap
    case foundNothingError
    case taggingProjects
    case finished
    
    //Manual
    case scanningDeclarations
    
    //Misc
    case version
    case verbose
    case helpText
    case mode
    
    var description: String {
        switch self {
        case .buildingProject:
            return "Building project to gather modules and compiler arguments..."
        case .compilerArgumentsError:
            return "Failed to retrieve compiler argments."
        case let .found(module):
            return "Found module \(module)"
        case let .indexing(file):
            return "-- Indexing \(file.name) --"
        case let .indexError(file, error):
            return "ERROR: Could not index \(file.name), aborting. SK Error: \(error)"
        case let .foundDeclaration(name, usr, newName):
            return "Found declaration of \(name) (\(usr)) -> now \(newName)"
        case .searchingReferencesOfUsr:
            return "-- Searching for references of the retrieved USRs --"
        case let .foundReference(name, usr, file, line, column):
            return "Found \(name) (\(usr)) at \(file.name) (L:\(line) C: \(column))"
        case let .overwriting(file):
            return "--- Overwriting \(file.name) ---"
        case let .fatal(error):
            return "FATAL: \(error)"
        case .overwritingStoryboards:
            return "--- Overwriting Storyboards ---"
        case let .checking(file):
            return "--- Checking \(file.name) ---"
        case let .protectedReference(originalName, protectedName):
            return "\(originalName) -> \(protectedName)"
        case let .fileNotModified(file):
            return "--- \(file.name) was not modified, continuing ---"
        case let .saving(file):
            return "--- Saving \(file.name) ---"
        case .generatingConversionMap:
            return "--- Generating conversion map ---"
        case .scanningDeclarations:
            return "--- Searching for tagged objects ---"
        case .helpText:
            return String.helpText
        case .projectError:
            return "Project file provided is not a project or workspace."
        case .foundNothingError:
            return "Found nothing to obfuscate. Finishing..."
        case .finished:
            return "Finished."
        case .version:
            return "SwiftShield 3.1.0"
        case .verbose:
            return "Verbose Mode"
        case .mode:
            return automatic ? "Automatic mode" : "Manual mode"
        case .taggingProjects:
            return "-- Adding SWIFTSHIELDED=true to projects --"
        }
    }
    
    var verbose: Bool {
        switch self {
        case .fileNotModified(_), .saving(_), .found(_), .verbose:
            return true
        default:
            return false
        }
    }
}

final class Logger {
    static var verbose = false

    static func log(_ log: LogType) {
        if (log.verbose && verbose) || !log.verbose {
            print(log.description)
        }
    }
}

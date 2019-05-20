import Foundation

enum LogType {
    //Automatic mode
    case buildingProject
    case compilerArgumentsError
    case found(module: String)
    case indexing(file: File)
    case indexError(file: File, error: String)
    case foundDeclaration(name: String, usr: String)
    case searchingReferencesOfUsr
    case foundReference(name: String, usr: String, at: File, line: Int, column: Int, newName: String)
    case projectError
    case ignoreModules(modules: Set<String>)
    case plistError(info: String)

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
    case tag(tag: String)

    //Deobfuscator
    case deobfuscatorStarted
    case foundObfuscatedReference(ref: String, original: String)

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
        case let .foundDeclaration(name, usr):
            return "Found declaration of \(name) (\(usr))"
        case .searchingReferencesOfUsr:
            return "-- Searching for references of the retrieved USRs --"
        case let .foundReference(name, usr, file, line, column, newName):
            return "Found \(name) (\(usr)) at \(file.name) (L:\(line) C: \(column) -> now \(newName))"
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
            return "\n\n--\n\nAUTOMATIC MODE:\n\nExample: swiftshield -automatic -project-root /app/MyApp -automatic-project-file /app/MyApp/MyApp.xcworkspace -automatic-project-scheme MyApp-AppStore \n\nRequired parameters:\n\n-automatic -project-root PATH_TO_PROJECTS_ROOT_FOLDER \n\n-automatic-project-file PATH_TO_PROJECT_FILE \n\n-automatic-project-scheme SCHEME_NAME_TO_BUILD\n\nOptional parameters:\n\n-verbose (Uses verbose mode)\n\n-show-sourcekit-queries (Prints queries made to SourceKit)\n\n-ignore-modules MyLib,MyAppExtension (Prevents obfuscation of certain modules)\n\n-obfuscation-character-count 32 (Obfuscated name size)\n\n-dry-run (Doesn't actually overwrite files)" +
            "\n\nMANUAL MODE:\n\nExample: swiftshield -project-root /app/MyApp -tag myTag\n\nRequired parameters:\n\n-project-root PATH_TO_PROJECTS_ROOT_FOLDER \n\nOptional parameters:\n\n-tag myTag (Custom tag to use. If not provided, '__s' will be used.)\n\n-verbose (Uses verbose mode)\n\n-obfuscation-character-count 32 (Obfuscated name size)\n\n-dry-run (Doesn't actually overwrite files)"
        case .projectError:
            return "Project file provided is not a project or workspace."
        case .foundNothingError:
            return "Found nothing to obfuscate. Finishing..."
        case .finished:
            return "Finished."
        case .version:
            return "SwiftShield 3.3.4"
        case .verbose:
            return "Verbose Mode"
        case .mode:
            return automatic ? "Automatic mode" : "Manual mode"
        case .taggingProjects:
            return "-- Adding SWIFTSHIELDED=true to projects --"
        case let .tag(tag):
            return "Using tag: \(tag)"
        case let .ignoreModules(modules):
            return "Ignoring modules: \(modules.joined(separator: ", "))"
        case .deobfuscatorStarted:
            return "Deobfuscating..."
        case let .foundObfuscatedReference(ref, original):
            return "Found \(ref) (\(original))"
        case let .plistError(info):
            return "Fatal Plist Error: \(info)"
        }
    }

    var verbose: Bool {
        switch self {
        case .fileNotModified, .saving, .found, .foundObfuscatedReference, .verbose:
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

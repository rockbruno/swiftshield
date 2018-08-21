import Foundation

struct DynamicLinkLibrary {
    let path: String
    let handle: UnsafeMutableRawPointer

    func load<T>(symbol: String) -> T {
        if let sym = dlsym(handle, symbol) {
            return unsafeBitCast(sym, to: T.self)
        }
        let errorString = String(validatingUTF8: dlerror()) ?? ""
        fatalError("Finding symbol \(symbol) failed: \(errorString)")
    }
}

func appsIn( dir: String, matcher: (_ name: String) -> Bool ) -> [String] {
    return (try! FileManager.default.contentsOfDirectory(atPath: dir))
        .filter( matcher ).sorted().reversed().map { "\(dir)/\($0)" }
}

#if os(Linux)
let toolchainLoader = Loader(searchPaths: [linuxSourceKitLibPath])
#else
let toolchainLoader = Loader(searchPaths: (["/Applications/Xcode.app"] +
    appsIn( dir: "/Applications", matcher: { $0.hasPrefix("Xcode") } ) )
    .map { $0+"/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/" } )
#endif

struct Loader {
    let searchPaths: [String]

    func load(path: String) -> DynamicLinkLibrary {
        let fullPaths = searchPaths.map { $0.appending(path) }

        // try all fullPaths that contains target file,
        // then try loading with simple path that depends resolving to DYLD
        for fullPath in fullPaths + [path] {
            if let handle = dlopen(fullPath, RTLD_LAZY) {
                return DynamicLinkLibrary(path: path, handle: handle)
            }
        }

        fatalError("Loading \(path) from \(searchPaths)")
    }
}

#if os(Linux)
private let path = "libsourcekitdInProc.so"
#else
private let path = "sourcekitd.framework/Versions/A/sourcekitd"
#endif
let library = toolchainLoader.load(path: path)

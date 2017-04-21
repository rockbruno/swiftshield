//
//  SourceKit.swift
//  refactord
//
//  Created by John Holdsworth on 19/12/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/Refactorator/refactord/SourceKit.swift#25 $
//
//  Repo: https://github.com/johnno1962/Refactorator
//

import Foundation

var isTTY = isatty( STDERR_FILENO ) != 0

protocol Visualiser {

    func enter()
    func present( dict: sourcekitd_variant_t, indent: String )
    func exit()

}

extension sourcekitd_variant_t {

    func getInt( key: sourcekitd_uid_t ) -> Int {
        return Int(SKApi.sourcekitd_variant_dictionary_get_int64( self, key ))
    }

    func getString( key: sourcekitd_uid_t ) -> String? {
        let cstr = SKApi.sourcekitd_variant_dictionary_get_string( self, key )
        if cstr != nil {
            return String( cString: cstr! )
        }
        return nil
    }

    func getUUIDString( key: sourcekitd_uid_t ) -> String {
        let uuid = SKApi.sourcekitd_variant_dictionary_get_uid( self, key )
        return String( cString: SKApi.sourcekitd_uid_get_string_ptr( uuid! ) )// ?: "NOUUID"
    }

}

/** Thanks to: https://github.com/jpsim/SourceKitten/blob/master/Source/SourceKittenFramework/library_wrapper_sourcekitd.swift **/

struct DynamicLinkLibrary {
    let path: String
    let handle: UnsafeMutableRawPointer

    func load<T>(symbol: String) -> T {
        if let sym = dlsym(handle, symbol) {
            return unsafeBitCast(sym, to: T.self)
        }
        let errorString = String(validatingUTF8: dlerror())
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
private let library = toolchainLoader.load(path: path)

class SKAPI {

    internal let sourcekitd_initialize: @convention(c) () -> () = library.load(symbol: "sourcekitd_initialize")
    internal let sourcekitd_shutdown: @convention(c) () -> () = library.load(symbol: "sourcekitd_shutdown")
    internal let sourcekitd_set_interrupted_connection_handler: @convention(c) (@escaping sourcekitd_interrupted_connection_handler_t) -> () = library.load(symbol: "sourcekitd_set_interrupted_connection_handler")
    internal let sourcekitd_uid_get_from_cstr: @convention(c) (UnsafePointer<Int8>) -> (sourcekitd_uid_t!) = library.load(symbol: "sourcekitd_uid_get_from_cstr")
    internal let sourcekitd_uid_get_from_buf: @convention(c) (UnsafePointer<Int8>, Int) -> (sourcekitd_uid_t!) = library.load(symbol: "sourcekitd_uid_get_from_buf")
    internal let sourcekitd_uid_get_length: @convention(c) (sourcekitd_uid_t) -> (Int) = library.load(symbol: "sourcekitd_uid_get_length")
    internal let sourcekitd_uid_get_string_ptr: @convention(c) (sourcekitd_uid_t) -> (UnsafePointer<Int8>!) = library.load(symbol: "sourcekitd_uid_get_string_ptr")
    internal let sourcekitd_request_retain: @convention(c) (sourcekitd_object_t) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_retain")
    internal let sourcekitd_request_release: @convention(c) (sourcekitd_object_t) -> () = library.load(symbol: "sourcekitd_request_release")
    internal let sourcekitd_request_dictionary_create: @convention(c) (UnsafePointer<sourcekitd_uid_t?>?, UnsafePointer<sourcekitd_object_t?>?, Int) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_dictionary_create")
    internal let sourcekitd_request_dictionary_set_value: @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, sourcekitd_object_t) -> () = library.load(symbol: "sourcekitd_request_dictionary_set_value")
    internal let sourcekitd_request_dictionary_set_string: @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, UnsafePointer<Int8>) -> () = library.load(symbol: "sourcekitd_request_dictionary_set_string")
    internal let sourcekitd_request_dictionary_set_stringbuf: @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, UnsafePointer<Int8>, Int) -> () = library.load(symbol: "sourcekitd_request_dictionary_set_stringbuf")
    internal let sourcekitd_request_dictionary_set_int64: @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, Int64) -> () = library.load(symbol: "sourcekitd_request_dictionary_set_int64")
    internal let sourcekitd_request_dictionary_set_uid: @convention(c) (sourcekitd_object_t, sourcekitd_uid_t, sourcekitd_uid_t) -> () = library.load(symbol: "sourcekitd_request_dictionary_set_uid")
    internal let sourcekitd_request_array_create: @convention(c) (UnsafePointer<sourcekitd_object_t?>?, Int) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_array_create")
    internal let sourcekitd_request_array_set_value: @convention(c) (sourcekitd_object_t, Int, sourcekitd_object_t) -> () = library.load(symbol: "sourcekitd_request_array_set_value")
    internal let sourcekitd_request_array_set_string: @convention(c) (sourcekitd_object_t, Int, UnsafePointer<Int8>) -> () = library.load(symbol: "sourcekitd_request_array_set_string")
    internal let sourcekitd_request_array_set_stringbuf: @convention(c) (sourcekitd_object_t, Int, UnsafePointer<Int8>, Int) -> () = library.load(symbol: "sourcekitd_request_array_set_stringbuf")
    internal let sourcekitd_request_array_set_int64: @convention(c) (sourcekitd_object_t, Int, Int64) -> () = library.load(symbol: "sourcekitd_request_array_set_int64")
    internal let sourcekitd_request_array_set_uid: @convention(c) (sourcekitd_object_t, Int, sourcekitd_uid_t) -> () = library.load(symbol: "sourcekitd_request_array_set_uid")
    internal let sourcekitd_request_int64_create: @convention(c) (Int64) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_int64_create")
    internal let sourcekitd_request_string_create: @convention(c) (UnsafePointer<Int8>) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_string_create")
    internal let sourcekitd_request_uid_create: @convention(c) (sourcekitd_uid_t) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_uid_create")
    internal let sourcekitd_request_create_from_yaml: @convention(c) (UnsafePointer<Int8>, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> (sourcekitd_object_t!) = library.load(symbol: "sourcekitd_request_create_from_yaml")
    internal let sourcekitd_request_description_dump: @convention(c) (sourcekitd_object_t) -> () = library.load(symbol: "sourcekitd_request_description_dump")
    internal let sourcekitd_request_description_copy: @convention(c) (sourcekitd_object_t) -> (UnsafeMutablePointer<Int8>!) = library.load(symbol: "sourcekitd_request_description_copy")
    internal let sourcekitd_response_dispose: @convention(c) (sourcekitd_response_t) -> () = library.load(symbol: "sourcekitd_response_dispose")
    internal let sourcekitd_response_is_error: @convention(c) (sourcekitd_response_t) -> (Bool) = library.load(symbol: "sourcekitd_response_is_error")
    internal let sourcekitd_response_error_get_kind: @convention(c) (sourcekitd_response_t) -> (sourcekitd_error_t) = library.load(symbol: "sourcekitd_response_error_get_kind")
    internal let sourcekitd_response_error_get_description: @convention(c) (sourcekitd_response_t) -> (UnsafePointer<Int8>!) = library.load(symbol: "sourcekitd_response_error_get_description")
    internal let sourcekitd_response_get_value: @convention(c) (sourcekitd_response_t) -> (sourcekitd_variant_t) = library.load(symbol: "sourcekitd_response_get_value")
    internal let sourcekitd_variant_get_type: @convention(c) (sourcekitd_variant_t) -> (sourcekitd_variant_type_t) = library.load(symbol: "sourcekitd_variant_get_type")
    internal let sourcekitd_variant_dictionary_get_value: @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (sourcekitd_variant_t) = library.load(symbol: "sourcekitd_variant_dictionary_get_value")
    internal let sourcekitd_variant_dictionary_get_string: @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (UnsafePointer<Int8>!) = library.load(symbol: "sourcekitd_variant_dictionary_get_string")
    internal let sourcekitd_variant_dictionary_get_int64: @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (Int64) = library.load(symbol: "sourcekitd_variant_dictionary_get_int64")
    internal let sourcekitd_variant_dictionary_get_bool: @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (Bool) = library.load(symbol: "sourcekitd_variant_dictionary_get_bool")
    internal let sourcekitd_variant_dictionary_get_uid: @convention(c) (sourcekitd_variant_t, sourcekitd_uid_t) -> (sourcekitd_uid_t!) = library.load(symbol: "sourcekitd_variant_dictionary_get_uid")
    internal let sourcekitd_variant_dictionary_apply_f: @convention(c) (sourcekitd_variant_t, @escaping sourcekitd_variant_dictionary_applier_f_t, UnsafeMutableRawPointer?) -> (Bool) = library.load(symbol: "sourcekitd_variant_dictionary_apply_f")
    internal let sourcekitd_variant_array_get_count: @convention(c) (sourcekitd_variant_t) -> (Int) = library.load(symbol: "sourcekitd_variant_array_get_count")
    internal let sourcekitd_variant_array_get_value: @convention(c) (sourcekitd_variant_t, Int) -> (sourcekitd_variant_t) = library.load(symbol: "sourcekitd_variant_array_get_value")
    internal let sourcekitd_variant_array_get_string: @convention(c) (sourcekitd_variant_t, Int) -> (UnsafePointer<Int8>!) = library.load(symbol: "sourcekitd_variant_array_get_string")
    internal let sourcekitd_variant_array_get_int64: @convention(c) (sourcekitd_variant_t, Int) -> (Int64) = library.load(symbol: "sourcekitd_variant_array_get_int64")
    internal let sourcekitd_variant_array_get_bool: @convention(c) (sourcekitd_variant_t, Int) -> (Bool) = library.load(symbol: "sourcekitd_variant_array_get_bool")
    internal let sourcekitd_variant_array_get_uid: @convention(c) (sourcekitd_variant_t, Int) -> (sourcekitd_uid_t!) = library.load(symbol: "sourcekitd_variant_array_get_uid")
    internal let sourcekitd_variant_array_apply_f: @convention(c) (sourcekitd_variant_t, @escaping sourcekitd_variant_array_applier_f_t, UnsafeMutableRawPointer?) -> (Bool) = library.load(symbol: "sourcekitd_variant_array_apply_f")
    internal let sourcekitd_variant_array_apply: @convention(c) (sourcekitd_variant_t, @escaping sourcekitd_variant_array_applier_t) -> (Bool) = library.load(symbol: "sourcekitd_variant_array_apply")
    internal let sourcekitd_variant_int64_get_value: @convention(c) (sourcekitd_variant_t) -> (Int64) = library.load(symbol: "sourcekitd_variant_int64_get_value")
    internal let sourcekitd_variant_bool_get_value: @convention(c) (sourcekitd_variant_t) -> (Bool) = library.load(symbol: "sourcekitd_variant_bool_get_value")
    internal let sourcekitd_variant_string_get_length: @convention(c) (sourcekitd_variant_t) -> (Int) = library.load(symbol: "sourcekitd_variant_string_get_length")
    internal let sourcekitd_variant_string_get_ptr: @convention(c) (sourcekitd_variant_t) -> (UnsafePointer<Int8>!) = library.load(symbol: "sourcekitd_variant_string_get_ptr")
    internal let sourcekitd_variant_uid_get_value: @convention(c) (sourcekitd_variant_t) -> (sourcekitd_uid_t!) = library.load(symbol: "sourcekitd_variant_uid_get_value")
    internal let sourcekitd_response_description_dump: @convention(c) (sourcekitd_response_t) -> () = library.load(symbol: "sourcekitd_response_description_dump")
    internal let sourcekitd_response_description_dump_filedesc: @convention(c) (sourcekitd_response_t, Int32) -> () = library.load(symbol: "sourcekitd_response_description_dump_filedesc")
    internal let sourcekitd_response_description_copy: @convention(c) (sourcekitd_response_t) -> (UnsafeMutablePointer<Int8>!) = library.load(symbol: "sourcekitd_response_description_copy")
    internal let sourcekitd_variant_description_dump: @convention(c) (sourcekitd_variant_t) -> () = library.load(symbol: "sourcekitd_variant_description_dump")
    internal let sourcekitd_variant_description_dump_filedesc: @convention(c) (sourcekitd_variant_t, Int32) -> () = library.load(symbol: "sourcekitd_variant_description_dump_filedesc")
    internal let sourcekitd_variant_description_copy: @convention(c) (sourcekitd_variant_t) -> (UnsafeMutablePointer<Int8>!) = library.load(symbol: "sourcekitd_variant_description_copy")
    internal let sourcekitd_variant_json_description_copy: @convention(c) (sourcekitd_variant_t) -> (UnsafeMutablePointer<Int8>!) = library.load(symbol: "sourcekitd_variant_json_description_copy")
    internal let sourcekitd_send_request_sync: @convention(c) (sourcekitd_object_t) -> (sourcekitd_response_t!) = library.load(symbol: "sourcekitd_send_request_sync")
    internal let sourcekitd_send_request: @convention(c) (sourcekitd_object_t, UnsafeMutablePointer<sourcekitd_request_handle_t?>?, sourcekitd_response_receiver_t?) -> () = library.load(symbol: "sourcekitd_send_request")
    internal let sourcekitd_cancel_request: @convention(c) (sourcekitd_request_handle_t?) -> () = library.load(symbol: "sourcekitd_cancel_request")
    internal let sourcekitd_set_notification_handler: @convention(c) (sourcekitd_response_receiver_t?) -> () = library.load(symbol: "sourcekitd_set_notification_handler")
    internal let sourcekitd_set_uid_handler: @convention(c) (sourcekitd_uid_handler_t?) -> () = library.load(symbol: "sourcekitd_set_uid_handler")
    internal let sourcekitd_set_uid_handlers: @convention(c) (sourcekitd_uid_from_str_handler_t?, sourcekitd_str_from_uid_handler_t?) -> () = library.load(symbol: "sourcekitd_set_uid_handlers")

}

let SKApi = SKAPI()

class SourceKit {

    /** request types */
    private lazy var requestID = SKApi.sourcekitd_uid_get_from_cstr("key.request")!
    private lazy var cursorRequestID = SKApi.sourcekitd_uid_get_from_cstr("source.request.cursorinfo")!
    private lazy var indexRequestID = SKApi.sourcekitd_uid_get_from_cstr("source.request.indexsource")!
    private lazy var editorCloseID = SKApi.sourcekitd_uid_get_from_cstr("source.request.editor.close")!
    private lazy var editorOpenID = SKApi.sourcekitd_uid_get_from_cstr("source.request.editor.open")!
    private lazy var symbolContainsID =
        SKApi.sourcekitd_uid_get_from_cstr("source.request.indexer.srv.symbol-contains")!
    private lazy var symbolOccurencesID = SKApi.sourcekitd_uid_get_from_cstr("source.request.document.symbol-occurrences")!

    private lazy var enableMapID = SKApi.sourcekitd_uid_get_from_cstr("key.enablesyntaxmap")!
    private lazy var enableSubID = SKApi.sourcekitd_uid_get_from_cstr("key.enablesubstructure")!
    private lazy var syntaxOnlyID = SKApi.sourcekitd_uid_get_from_cstr("key.syntactic_only")!

    /** request arguments */
    lazy var offsetID = SKApi.sourcekitd_uid_get_from_cstr("key.offset")!
    lazy var nameOffsetID = SKApi.sourcekitd_uid_get_from_cstr("key.nameoffset")!
    lazy var sourceFileID = SKApi.sourcekitd_uid_get_from_cstr("key.sourcefile")!
    lazy var compilerArgsID = SKApi.sourcekitd_uid_get_from_cstr("key.compilerargs")!
    lazy var enableSyntaxMapId = SKApi.sourcekitd_uid_get_from_cstr("key.enablesyntaxmap")!

    /** sub entity lists */
    lazy var depedenciesID = SKApi.sourcekitd_uid_get_from_cstr("key.dependencies")!
    lazy var overridesID = SKApi.sourcekitd_uid_get_from_cstr("key.overrides")!
    lazy var entitiesID = SKApi.sourcekitd_uid_get_from_cstr("key.entities")!
    lazy var relatedID = SKApi.sourcekitd_uid_get_from_cstr("key.related")!
    lazy var syntaxID = SKApi.sourcekitd_uid_get_from_cstr("key.syntaxmap")!
    lazy var substructureID = SKApi.sourcekitd_uid_get_from_cstr("key.substructure")!

    /** entity attributes */
    lazy var receiverID = SKApi.sourcekitd_uid_get_from_cstr("key.receiver_usr")!
    lazy var isDynamicID = SKApi.sourcekitd_uid_get_from_cstr("key.is_dynamic")!
    lazy var isSystemID = SKApi.sourcekitd_uid_get_from_cstr("key.is_system")!
    lazy var moduleID = SKApi.sourcekitd_uid_get_from_cstr("key.modulename")!
    lazy var lengthID = SKApi.sourcekitd_uid_get_from_cstr("key.length")!
    lazy var kindID = SKApi.sourcekitd_uid_get_from_cstr("key.kind")!
    lazy var nameID = SKApi.sourcekitd_uid_get_from_cstr("key.name")!
    lazy var lineID = SKApi.sourcekitd_uid_get_from_cstr("key.line")!
    lazy var colID = SKApi.sourcekitd_uid_get_from_cstr("key.column")!
    lazy var usrID = SKApi.sourcekitd_uid_get_from_cstr("key.usr")!
    lazy var runtimeNameID = SKApi.sourcekitd_uid_get_from_cstr("key.runtime_name")!
    lazy var typeUsrID = SKApi.sourcekitd_uid_get_from_cstr("key.typeusr")!
    
    /** indexer */
    lazy var isAnchorEndID = SKApi.sourcekitd_uid_get_from_cstr("key.indexer.arg.symbol.is-anchor-end")!
    lazy var isSubsequenceID = SKApi.sourcekitd_uid_get_from_cstr("key.indexer.arg.symbol.is-subsequence")!
    lazy var ignoreCaseID = SKApi.sourcekitd_uid_get_from_cstr("key.indexer.arg.symbol.is-ignore-case")!
    
    /** kinds */
    lazy var clangID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.import.module.clang")!

    /** declarations */
    
    fileprivate static let classIDString = "source.lang.swift.decl.class"
    fileprivate static let structIDString = "source.lang.swift.decl.struct"
    fileprivate static let protocolIDString = "source.lang.swift.decl.protocol"
    fileprivate static let enumIDString = "source.lang.swift.decl.enum"
    
    lazy var protocolID = SKApi.sourcekitd_uid_get_from_cstr(SourceKit.protocolIDString)!
    lazy var structID = SKApi.sourcekitd_uid_get_from_cstr(SourceKit.structIDString)!
    lazy var classID = SKApi.sourcekitd_uid_get_from_cstr(SourceKit.classIDString)!
    lazy var enumID = SKApi.sourcekitd_uid_get_from_cstr(SourceKit.enumIDString)!
    
    func isObjectDeclaration(kind: String) -> Bool {
        return kind == SourceKit.classIDString || kind == SourceKit.structIDString || kind == SourceKit.enumIDString || kind == SourceKit.protocolIDString
    }
    
    func isObjectReference(kind: String) -> Bool {
        return isObjectDeclaration(kind: kind) || kind.contains("ref.class") || kind.contains("ref.struct") || kind.contains("ref.enum") || kind.contains("ref.protocol")
    }

    /** references */
    lazy var classVarID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.function.var.class")!
    lazy var classMethodID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.function.method.class")!
    lazy var initID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.function.constructor")!
    lazy var varID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.var.instance")!
    lazy var methodID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.function.method.instance")!
    lazy var elementID = SKApi.sourcekitd_uid_get_from_cstr("source.lang.swift.ref.enumelement")!

    init() {
        SKApi.sourcekitd_initialize()
    }

    func array( argv: [String] ) -> sourcekitd_object_t {
        let objects = argv.map { SKApi.sourcekitd_request_string_create( $0 ) }
        return SKApi.sourcekitd_request_array_create( objects, objects.count )
    }

    func error( resp: sourcekitd_response_t ) -> String? {
        if SKApi.sourcekitd_response_is_error( resp ) {
            return String( cString: SKApi.sourcekitd_response_error_get_description( resp ) )
        }
        return nil
    }

    func sendRequest( req: sourcekitd_object_t ) -> sourcekitd_response_t {

        if isTTY && verbose {
            SKApi.sourcekitd_request_description_dump( req )
        }

        var resp: sourcekitd_response_t?
        while true {
            resp = SKApi.sourcekitd_send_request_sync( req )
            let err = error( resp: resp! )
            if err == "restoring service" || err == "semantic editor is disabled" {
                sleep(1)
                continue
            }
            else {
                break
            }
        }

        SKApi.sourcekitd_request_release( req )

        if isTTY && !SKApi.sourcekitd_response_is_error( resp! ) && verbose {
            SKApi.sourcekitd_response_description_dump_filedesc( resp!, STDERR_FILENO )
        }

        return resp!
    }

    func cursorInfo( filePath: String, byteOffset: Int32, compilerArgs: sourcekitd_object_t ) -> sourcekitd_response_t {
        let req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )!

        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, cursorRequestID )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
        SKApi.sourcekitd_request_dictionary_set_int64( req, offsetID, Int64(byteOffset) )
        SKApi.sourcekitd_request_dictionary_set_value( req, compilerArgsID, compilerArgs )

        return sendRequest( req: req )
    }

    func indexFile( filePath: String, compilerArgs: sourcekitd_object_t ) -> sourcekitd_response_t {
        let req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )!

        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, indexRequestID )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
        SKApi.sourcekitd_request_dictionary_set_value( req, compilerArgsID, compilerArgs )

        return sendRequest( req: req )
    }
    
    func editorOpen( filePath: String, compilerArgs: sourcekitd_object_t ) -> sourcekitd_response_t {
        var req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )!
        
        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, editorOpenID )
        SKApi.sourcekitd_request_dictionary_set_string( req, nameID, "annotate-source-text" )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
        SKApi.sourcekitd_request_dictionary_set_int64( req, enableSyntaxMapId, 1 )
        SKApi.sourcekitd_request_dictionary_set_value( req, compilerArgsID, compilerArgs)
        
        return sendRequest( req: req )
    }
    
    func symbolOccurrences( filePath: String, compilerArgs: sourcekitd_object_t ) -> sourcekitd_response_t {
        var req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )!
        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, symbolOccurencesID )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
        
        return sendRequest( req: req )
    }
    
    func syntaxMap( filePath: String ) -> sourcekitd_response_t {
        var req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )!

        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, editorOpenID )
        SKApi.sourcekitd_request_dictionary_set_string( req, nameID, filePath )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
//        SKApi.sourcekitd_request_dictionary_set_value( req, compilerArgsID, compilerArgs )
        SKApi.sourcekitd_request_dictionary_set_int64( req, enableMapID, 1 )
        SKApi.sourcekitd_request_dictionary_set_int64( req, enableSubID, 0 )
        SKApi.sourcekitd_request_dictionary_set_int64( req, syntaxOnlyID, 1 )

        let resp = sendRequest( req: req )

        req = SKApi.sourcekitd_request_dictionary_create( nil, nil, 0 )
        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, editorCloseID )
        SKApi.sourcekitd_request_dictionary_set_string( req, nameID, filePath )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )

        SKApi.sourcekitd_response_dispose( sendRequest( req: req ) )

        return resp
    }

    func recurseOver( childID: sourcekitd_uid_t, resp: sourcekitd_variant_t,
        indent: String = "", visualiser: Visualiser? = nil,
        block: @escaping ( _ dict: sourcekitd_variant_t ) -> ()) {

            let children = SKApi.sourcekitd_variant_dictionary_get_value( resp, childID )
            if SKApi.sourcekitd_variant_get_type( children ) == SOURCEKITD_VARIANT_TYPE_ARRAY {

                visualiser?.enter()
                _ = SKApi.sourcekitd_variant_array_apply( children ) { (_,dict) in

                    block( dict )
                    visualiser?.present( dict: dict, indent: indent )

                    self.recurseOver( childID: childID, resp: dict, indent: indent+"  ", visualiser: visualiser, block: block )
                    return true
                }
                visualiser?.exit()
            }
    }

    func disectUSR( usr: NSString ) -> [String]? {
        guard usr.hasPrefix( "s:" ) else { return nil }

        let digits = CharacterSet.decimalDigits
        let scanner = Scanner( string: usr as String )
        var out = [String]()
        var wasZero = false

        while !scanner.isAtEnd {

            var name: NSString?
            scanner.scanUpToCharacters( from: digits, into: &name )
            if name != nil, let name = name as? String {
                if wasZero {
                    out[out.count-1] += "0" + name
                    wasZero = false
                }
                else {
                    out.append( name )
                }
            }

            var len = 0
            scanner.scanInt( &len )
            wasZero = len == 0
            if wasZero {
                continue
            }

            if len > usr.length-scanner.scanLocation {
                len = usr.length-scanner.scanLocation
            }
            
            let range = NSMakeRange( scanner.scanLocation, len )
            out.append( usr.substring( with: range ) )
            scanner.scanLocation += len
        }
        
        return out
    }
    
}

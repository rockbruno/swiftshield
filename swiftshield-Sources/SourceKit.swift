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

/** Thanks to: https://github.com/jpsim/SourceKitten/blob/master/Source/SourceKittenFramework/library_wrapper_sourcekitd.swift **/

let SKApi = SKAPI()

class SourceKit {
    /** request types */
    private lazy var indexRequestID = SKApi.sourcekitd_uid_get_from_cstr("source.request.indexsource")!
    private lazy var requestID = SKApi.sourcekitd_uid_get_from_cstr("key.request")!

    /** request arguments */
    lazy var sourceFileID = SKApi.sourcekitd_uid_get_from_cstr("key.sourcefile")!
    lazy var compilerArgsID = SKApi.sourcekitd_uid_get_from_cstr("key.compilerargs")!

    /** sub entity lists */
    lazy var entitiesID = SKApi.sourcekitd_uid_get_from_cstr("key.entities")!
    lazy var relatedID = SKApi.sourcekitd_uid_get_from_cstr("key.related")!

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

    /** declarations */

    fileprivate static let swiftLangPrefix = "source.lang.swift"
    fileprivate static let classIDString = "source.lang.swift.decl.class"
    fileprivate static let structIDString = "source.lang.swift.decl.struct"
    fileprivate static let protocolIDString = "source.lang.swift.decl.protocol"
    fileprivate static let enumIDString = "source.lang.swift.decl.enum"
    fileprivate static let enumCaseIDString = "source.lang.swift.decl.enumelement"
    fileprivate static let typealiasIDString = "source.lang.swift.decl.typealias"
    fileprivate static let associatedTypeIDString = "source.lang.swift.decl.associatedtype"

    fileprivate static let instanceMethodIDString = "source.lang.swift.decl.function.method.instance"
    fileprivate static let globalInstanceMethodIDString = "source.lang.swift.decl.function.free"
    fileprivate static let staticMethodIDString = "source.lang.swift.decl.function.method.static"
    fileprivate static let classMethodIDString = "source.lang.swift.decl.function.method.class"

    fileprivate static let instancePropertyIDString = "source.lang.swift.decl.var.instance"
    fileprivate static let classPropertyIDString = "source.lang.swift.decl.var.class"

    init() {
        SKApi.sourcekitd_initialize()
    }

    func referenceType(kind: String) -> DeclarationType? {
        if let type = declarationType(for: kind) {
            return type
        }
        if kind.contains("ref.class") ||
            kind.contains("ref.struct") ||
            kind.contains("ref.protocol") ||
            kind.contains("ref.typealias") {
            return .object
        } else if kind.contains("ref.var.instance") ||
            kind.contains("ref.var.class") {
            return .property
        } else if kind.contains("ref.function.method.instance") ||
            kind.contains("ref.function.free") ||
            kind.contains("ref.function.method.static") ||
            kind.contains("ref.function.method.class") {
            return .method
        } else {
            return nil
        }
    }

    func declarationType(for kind: String) -> DeclarationType? {
        switch kind {
        case SourceKit.classIDString,
             SourceKit.structIDString,
             SourceKit.protocolIDString:
            return .object
        case SourceKit.instancePropertyIDString,
             SourceKit.classPropertyIDString:
            return .property
        case SourceKit.instanceMethodIDString,
             SourceKit.globalInstanceMethodIDString,
             SourceKit.staticMethodIDString,
             SourceKit.classMethodIDString:
            return .method
        default:
            return nil
        }
    }

    func array(argv: [String]) -> sourcekitd_object_t {
        let objects = argv.map { SKApi.sourcekitd_request_string_create($0) }
        return SKApi.sourcekitd_request_array_create(objects, objects.count)
    }

    func error(resp: sourcekitd_response_t) -> String? {
        if SKApi.sourcekitd_response_is_error(resp) {
            return String(cString: SKApi.sourcekitd_response_error_get_description(resp))
        }
        return nil
    }

    func sendRequest( req: sourcekitd_object_t ) -> sourcekitd_response_t {
        if isTTY && SKAPI.verbose {
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
        if isTTY && !SKApi.sourcekitd_response_is_error( resp! ) && SKAPI.verbose {
            SKApi.sourcekitd_response_description_dump_filedesc( resp!, STDERR_FILENO )
        }
        return resp!
    }

    func indexFile( filePath: String, compilerArgs: sourcekitd_object_t ) -> sourcekitd_response_t {
        let req = SKApi.sourcekitd_request_dictionary_create(nil, nil, 0)!
        SKApi.sourcekitd_request_dictionary_set_uid( req, requestID, indexRequestID )
        SKApi.sourcekitd_request_dictionary_set_string( req, sourceFileID, filePath )
        SKApi.sourcekitd_request_dictionary_set_value( req, compilerArgsID, compilerArgs )
        return sendRequest( req: req )
    }

    func recurseOver(childID: sourcekitd_uid_t, resp: sourcekitd_variant_t,
        indent: String = "", visualiser: Visualiser? = nil,
        block: @escaping (_ dict: sourcekitd_variant_t) -> ()) {
        let children = SKApi.sourcekitd_variant_dictionary_get_value(resp, childID)
        if SKApi.sourcekitd_variant_get_type(children) == SOURCEKITD_VARIANT_TYPE_ARRAY {
            visualiser?.enter()
            _ = SKApi.sourcekitd_variant_array_apply(children) { [unowned self] (_, dict) in
                block(dict)
                visualiser?.present(dict: dict, indent: indent)
                self.recurseOver(childID: childID, resp: dict, indent: indent + "  ", visualiser: visualiser, block: block)
                return true
            }
            visualiser?.exit()
        }
    }
}

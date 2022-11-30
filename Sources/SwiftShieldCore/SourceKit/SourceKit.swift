//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import sourcekitd

// Adapted from SourceKit-LSP.

/// A wrapper for accessing the API of a sourcekitd library loaded via `dlopen`.
class SourceKit {
    /// The path to the sourcekitd dylib.
    public let path: String

    /// The handle to the dylib.
    let dylib: DLHandle!

    /// The sourcekitd API functions.
    public let api: sourcekitd_functions_t!

    /// Convenience for accessing known keys.
    public let keys: sourcekitd_keys!

    /// Convenience for accessing known keys.
    public let requests: sourcekitd_requests!

    /// Convenience for accessing known keys.
    public let values: sourcekitd_values!

    let logger: LoggerProtocol?

    enum Error: Swift.Error {
        case missingRequiredSymbol(String)
    }

    static func getToolchainPath() -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "xcode-select -p"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let developer = String(data: data, encoding: .utf8), developer.isEmpty == false else {
            preconditionFailure("Xcode toolchain path not found. (xcode-select -p)")
        }
        let oneLined = developer.replacingOccurrences(of: "\n", with: "")
        return oneLined + "/Toolchains/XcodeDefault.xctoolchain/usr/lib/sourcekitd.framework/sourcekitd"
    }

    public init(logger: LoggerProtocol?) {
        self.logger = logger
        path = Self.getToolchainPath()
        dylib = try! dlopen(path, mode: [.lazy, .local, .first, .deepBind])

        func dlsym_required<T>(_ handle: DLHandle, symbol: String) throws -> T {
            guard let sym: T = dlsym(handle, symbol: symbol) else {
                throw Error.missingRequiredSymbol(symbol)
            }
            return sym
        }

        // Workaround rdar://problem/43656704 by not constructing the value directly.
        // self.api = sourcekitd_functions_t(
        let ptr = UnsafeMutablePointer<sourcekitd_functions_t>.allocate(capacity: 1)
        bzero(UnsafeMutableRawPointer(ptr), MemoryLayout<sourcekitd_functions_t>.stride)
        var api = ptr.pointee
        ptr.deallocate()

        // The following crashes the compiler rdar://43658464
        // api.variant_dictionary_apply = try dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_apply")
        // api.variant_array_apply = try dlsym_required(dylib, symbol: "sourcekitd_variant_array_apply")

        api.initialize = try! dlsym_required(dylib, symbol: "sourcekitd_initialize")
        api.shutdown = try! dlsym_required(dylib, symbol: "sourcekitd_shutdown")
        api.uid_get_from_cstr = try! dlsym_required(dylib, symbol: "sourcekitd_uid_get_from_cstr")
        api.uid_get_from_buf = try! dlsym_required(dylib, symbol: "sourcekitd_uid_get_from_buf")
        api.uid_get_length = try! dlsym_required(dylib, symbol: "sourcekitd_uid_get_length")
        api.uid_get_string_ptr = try! dlsym_required(dylib, symbol: "sourcekitd_uid_get_string_ptr")
        api.request_retain = try! dlsym_required(dylib, symbol: "sourcekitd_request_retain")
        api.request_release = try! dlsym_required(dylib, symbol: "sourcekitd_request_release")
        api.request_dictionary_create = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_create")
        api.request_dictionary_set_value = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_set_value")
        api.request_dictionary_set_string = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_set_string")
        api.request_dictionary_set_stringbuf = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_set_stringbuf")
        api.request_dictionary_set_int64 = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_set_int64")
        api.request_dictionary_set_uid = try! dlsym_required(dylib, symbol: "sourcekitd_request_dictionary_set_uid")
        api.request_array_create = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_create")
        api.request_array_set_value = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_set_value")
        api.request_array_set_string = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_set_string")
        api.request_array_set_stringbuf = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_set_stringbuf")
        api.request_array_set_int64 = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_set_int64")
        api.request_array_set_uid = try! dlsym_required(dylib, symbol: "sourcekitd_request_array_set_uid")
        api.request_int64_create = try! dlsym_required(dylib, symbol: "sourcekitd_request_int64_create")
        api.request_string_create = try! dlsym_required(dylib, symbol: "sourcekitd_request_string_create")
        api.request_uid_create = try! dlsym_required(dylib, symbol: "sourcekitd_request_uid_create")
        api.request_create_from_yaml = try! dlsym_required(dylib, symbol: "sourcekitd_request_create_from_yaml")
        api.request_description_dump = try! dlsym_required(dylib, symbol: "sourcekitd_request_description_dump")
        api.request_description_copy = try! dlsym_required(dylib, symbol: "sourcekitd_request_description_copy")
        api.response_dispose = try! dlsym_required(dylib, symbol: "sourcekitd_response_dispose")
        api.response_is_error = try! dlsym_required(dylib, symbol: "sourcekitd_response_is_error")
        api.response_error_get_kind = try! dlsym_required(dylib, symbol: "sourcekitd_response_error_get_kind")
        api.response_error_get_description = try! dlsym_required(dylib, symbol: "sourcekitd_response_error_get_description")
        api.response_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_response_get_value")
        api.variant_get_type = try! dlsym_required(dylib, symbol: "sourcekitd_variant_get_type")
        api.variant_dictionary_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_get_value")
        api.variant_dictionary_get_string = try! dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_get_string")
        api.variant_dictionary_get_int64 = try! dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_get_int64")
        api.variant_dictionary_get_bool = try! dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_get_bool")
        api.variant_dictionary_get_uid = try! dlsym_required(dylib, symbol: "sourcekitd_variant_dictionary_get_uid")

        api.variant_array_get_count = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_count")
        api.variant_array_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_value")
        api.variant_array_get_string = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_string")
        api.variant_array_get_int64 = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_int64")
        api.variant_array_get_bool = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_bool")
        api.variant_array_get_uid = try! dlsym_required(dylib, symbol: "sourcekitd_variant_array_get_uid")

        api.variant_int64_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_variant_int64_get_value")
        api.variant_bool_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_variant_bool_get_value")
        api.variant_string_get_length = try! dlsym_required(dylib, symbol: "sourcekitd_variant_string_get_length")
        api.variant_string_get_ptr = try! dlsym_required(dylib, symbol: "sourcekitd_variant_string_get_ptr")
        api.variant_data_get_size = dlsym(dylib, symbol: "sourcekitd_variant_data_get_size") // Optional
        api.variant_data_get_ptr = dlsym(dylib, symbol: "sourcekitd_variant_data_get_ptr") // Optional
        api.variant_uid_get_value = try! dlsym_required(dylib, symbol: "sourcekitd_variant_uid_get_value")
        api.response_description_dump = try! dlsym_required(dylib, symbol: "sourcekitd_response_description_dump")
        api.response_description_dump_filedesc = try! dlsym_required(dylib, symbol: "sourcekitd_response_description_dump_filedesc")
        api.response_description_copy = try! dlsym_required(dylib, symbol: "sourcekitd_response_description_copy")
        api.variant_description_dump = try! dlsym_required(dylib, symbol: "sourcekitd_variant_description_dump")
        api.variant_description_dump_filedesc = try! dlsym_required(dylib, symbol: "sourcekitd_variant_description_dump_filedesc")
        api.variant_description_copy = try! dlsym_required(dylib, symbol: "sourcekitd_variant_description_copy")
        api.send_request_sync = try! dlsym_required(dylib, symbol: "sourcekitd_send_request_sync")
        api.send_request = try! dlsym_required(dylib, symbol: "sourcekitd_send_request")
        api.cancel_request = try! dlsym_required(dylib, symbol: "sourcekitd_cancel_request")
        api.set_notification_handler = try! dlsym_required(dylib, symbol: "sourcekitd_set_notification_handler")
        api.set_uid_handlers = try! dlsym_required(dylib, symbol: "sourcekitd_set_uid_handlers")

        self.api = api

        keys = sourcekitd_keys(api: self.api)
        requests = sourcekitd_requests(api: self.api)
        values = sourcekitd_values(api: self.api)

        api.initialize()
    }

    deinit {
        // FIXME: is it safe to dlclose() sourcekitd? If so, do that here. For now, let the handle leak.
        guard dylib != nil else {
            return
        }
        dylib.leak()
    }
}

public enum SKResult<T> {
    case success(T)
    case failure(String)
}

extension SourceKit {
    // MARK: - Convenience API for requests.

    /// Send the given request and synchronously receive a reply dictionary (or error).
    public func sendSync(_ req: SKRequestDictionary) throws -> SKResponseDictionary {
        logger?.log(req.description, sourceKit: true)
        let resp = SKResponse(api.send_request_sync(req.dict), sourcekitd: self)
        logger?.log(resp.description, sourceKit: true)
        guard let dict = resp.value else {
            throw (logger ?? Logger()).fatalError(forMessage: resp.error!)
        }
        return dict
    }
}

public struct sourcekitd_keys {
    let request: sourcekitd_uid_t
    let compilerargs: sourcekitd_uid_t
    let offset: sourcekitd_uid_t
    let length: sourcekitd_uid_t
    let sourcefile: sourcekitd_uid_t
    let sourcetext: sourcekitd_uid_t
    let results: sourcekitd_uid_t
    let description: sourcekitd_uid_t
    let name: sourcekitd_uid_t
    let kind: sourcekitd_uid_t
    let notification: sourcekitd_uid_t
    let diagnostics: sourcekitd_uid_t
    let severity: sourcekitd_uid_t
    let line: sourcekitd_uid_t
    let column: sourcekitd_uid_t
    let endline: sourcekitd_uid_t
    let endcolumn: sourcekitd_uid_t
    let filepath: sourcekitd_uid_t
    let ranges: sourcekitd_uid_t
    let usr: sourcekitd_uid_t
    let typename: sourcekitd_uid_t
    let annotated_decl: sourcekitd_uid_t
    let doc_full_as_xml: sourcekitd_uid_t
    let syntactic_only: sourcekitd_uid_t
    let substructure: sourcekitd_uid_t
    let bodyoffset: sourcekitd_uid_t
    let bodylength: sourcekitd_uid_t
    let syntaxmap: sourcekitd_uid_t
    let retrieve_refactor_actions: sourcekitd_uid_t
    let refactor_actions: sourcekitd_uid_t
    let actionname: sourcekitd_uid_t
    let actionuid: sourcekitd_uid_t
    let categorizededits: sourcekitd_uid_t
    let edits: sourcekitd_uid_t
    let text: sourcekitd_uid_t
    let entities: sourcekitd_uid_t
    let receiver: sourcekitd_uid_t
    let attributes: sourcekitd_uid_t
    let attribute: sourcekitd_uid_t
    let related: sourcekitd_uid_t
    let effectiveAccess: sourcekitd_uid_t

    init(api: sourcekitd_functions_t) {
        request = api.uid_get_from_cstr("key.request")!
        compilerargs = api.uid_get_from_cstr("key.compilerargs")!
        offset = api.uid_get_from_cstr("key.offset")!
        length = api.uid_get_from_cstr("key.length")!
        sourcefile = api.uid_get_from_cstr("key.sourcefile")!
        sourcetext = api.uid_get_from_cstr("key.sourcetext")!
        results = api.uid_get_from_cstr("key.results")!
        description = api.uid_get_from_cstr("key.description")!
        name = api.uid_get_from_cstr("key.name")!
        kind = api.uid_get_from_cstr("key.kind")!
        notification = api.uid_get_from_cstr("key.notification")!
        diagnostics = api.uid_get_from_cstr("key.diagnostics")!
        severity = api.uid_get_from_cstr("key.severity")!
        line = api.uid_get_from_cstr("key.line")!
        column = api.uid_get_from_cstr("key.column")!
        endline = api.uid_get_from_cstr("key.endline")!
        endcolumn = api.uid_get_from_cstr("key.endcolumn")!
        filepath = api.uid_get_from_cstr("key.filepath")!
        ranges = api.uid_get_from_cstr("key.ranges")!
        usr = api.uid_get_from_cstr("key.usr")!
        typename = api.uid_get_from_cstr("key.typename")!
        annotated_decl = api.uid_get_from_cstr("key.annotated_decl")!
        doc_full_as_xml = api.uid_get_from_cstr("key.doc.full_as_xml")!
        syntactic_only = api.uid_get_from_cstr("key.syntactic_only")!
        substructure = api.uid_get_from_cstr("key.substructure")!
        bodyoffset = api.uid_get_from_cstr("key.bodyoffset")!
        bodylength = api.uid_get_from_cstr("key.bodylength")!
        syntaxmap = api.uid_get_from_cstr("key.syntaxmap")!
        retrieve_refactor_actions = api.uid_get_from_cstr("key.retrieve_refactor_actions")!
        refactor_actions = api.uid_get_from_cstr("key.refactor_actions")!
        actionname = api.uid_get_from_cstr("key.actionname")!
        actionuid = api.uid_get_from_cstr("key.actionuid")!
        categorizededits = api.uid_get_from_cstr("key.categorizededits")!
        edits = api.uid_get_from_cstr("key.edits")!
        text = api.uid_get_from_cstr("key.text")!
        entities = api.uid_get_from_cstr("key.entities")!
        receiver = api.uid_get_from_cstr("key.receiver_usr")!
        attributes = api.uid_get_from_cstr("key.attributes")!
        attribute = api.uid_get_from_cstr("key.attribute")!
        related = api.uid_get_from_cstr("key.related")!
        effectiveAccess = api.uid_get_from_cstr("key.effective_access")!
    }
}

public struct sourcekitd_requests {
    let editor_open: sourcekitd_uid_t
    let editor_close: sourcekitd_uid_t
    let editor_replacetext: sourcekitd_uid_t
    let codecomplete: sourcekitd_uid_t
    let cursorinfo: sourcekitd_uid_t
    let relatedidents: sourcekitd_uid_t
    let semantic_refactoring: sourcekitd_uid_t
    let indexsource: sourcekitd_uid_t
    let typecontextinfo: sourcekitd_uid_t
    let conformingmethods: sourcekitd_uid_t

    init(api: sourcekitd_functions_t) {
        editor_open = api.uid_get_from_cstr("source.request.editor.open")!
        editor_close = api.uid_get_from_cstr("source.request.editor.close")!
        editor_replacetext = api.uid_get_from_cstr("source.request.editor.replacetext")!
        codecomplete = api.uid_get_from_cstr("source.request.codecomplete")!
        cursorinfo = api.uid_get_from_cstr("source.request.cursorinfo")!
        relatedidents = api.uid_get_from_cstr("source.request.relatedidents")!
        semantic_refactoring = api.uid_get_from_cstr("source.request.semantic.refactoring")!
        indexsource = api.uid_get_from_cstr("source.request.indexsource")!
        typecontextinfo = api.uid_get_from_cstr("source.request.typecontextinfo")!
        conformingmethods = api.uid_get_from_cstr("source.request.conformingmethods")!
    }
}

public struct sourcekitd_values {
    let notification_documentupdate: sourcekitd_uid_t
    let diag_error: sourcekitd_uid_t
    let diag_warning: sourcekitd_uid_t
    let diag_note: sourcekitd_uid_t

    // MARK: Symbol Kinds

    let decl_function_free: sourcekitd_uid_t
    let ref_function_free: sourcekitd_uid_t
    let decl_function_method_instance: sourcekitd_uid_t
    let ref_function_method_instance: sourcekitd_uid_t
    let decl_function_method_static: sourcekitd_uid_t
    let ref_function_method_static: sourcekitd_uid_t
    let decl_function_method_class: sourcekitd_uid_t
    let ref_function_method_class: sourcekitd_uid_t
    let decl_function_accessor_getter: sourcekitd_uid_t
    let ref_function_accessor_getter: sourcekitd_uid_t
    let decl_function_accessor_setter: sourcekitd_uid_t
    let ref_function_accessor_setter: sourcekitd_uid_t
    let decl_function_accessor_willset: sourcekitd_uid_t
    let ref_function_accessor_willset: sourcekitd_uid_t
    let decl_function_accessor_didset: sourcekitd_uid_t
    let ref_function_accessor_didset: sourcekitd_uid_t
    let decl_function_accessor_address: sourcekitd_uid_t
    let ref_function_accessor_address: sourcekitd_uid_t
    let decl_function_accessor_mutableaddress: sourcekitd_uid_t
    let ref_function_accessor_mutableaddress: sourcekitd_uid_t
    let decl_function_accessor_read: sourcekitd_uid_t
    let ref_function_accessor_read: sourcekitd_uid_t
    let decl_function_accessor_modify: sourcekitd_uid_t
    let ref_function_accessor_modify: sourcekitd_uid_t
    let decl_function_constructor: sourcekitd_uid_t
    let ref_function_constructor: sourcekitd_uid_t
    let decl_function_destructor: sourcekitd_uid_t
    let ref_function_destructor: sourcekitd_uid_t
    let decl_function_operator_prefix: sourcekitd_uid_t
    let decl_function_operator_postfix: sourcekitd_uid_t
    let decl_function_operator_infix: sourcekitd_uid_t
    let ref_function_operator_prefix: sourcekitd_uid_t
    let ref_function_operator_postfix: sourcekitd_uid_t
    let ref_function_operator_infix: sourcekitd_uid_t
    let decl_precedencegroup: sourcekitd_uid_t
    let ref_precedencegroup: sourcekitd_uid_t
    let decl_function_subscript: sourcekitd_uid_t
    let ref_function_subscript: sourcekitd_uid_t
    let decl_var_global: sourcekitd_uid_t
    let ref_var_global: sourcekitd_uid_t
    let decl_var_instance: sourcekitd_uid_t
    let ref_var_instance: sourcekitd_uid_t
    let decl_var_static: sourcekitd_uid_t
    let ref_var_static: sourcekitd_uid_t
    let decl_var_class: sourcekitd_uid_t
    let ref_var_class: sourcekitd_uid_t
    let decl_var_local: sourcekitd_uid_t
    let ref_var_local: sourcekitd_uid_t
    let decl_var_parameter: sourcekitd_uid_t
    let decl_module: sourcekitd_uid_t
    let decl_class: sourcekitd_uid_t
    let ref_class: sourcekitd_uid_t
    let decl_struct: sourcekitd_uid_t
    let ref_struct: sourcekitd_uid_t
    let decl_enum: sourcekitd_uid_t
    let ref_enum: sourcekitd_uid_t
    let decl_enumcase: sourcekitd_uid_t
    let decl_enumelement: sourcekitd_uid_t
    let ref_enumelement: sourcekitd_uid_t
    let decl_protocol: sourcekitd_uid_t
    let ref_protocol: sourcekitd_uid_t
    let decl_extension: sourcekitd_uid_t
    let decl_extension_struct: sourcekitd_uid_t
    let decl_extension_class: sourcekitd_uid_t
    let decl_extension_enum: sourcekitd_uid_t
    let decl_extension_protocol: sourcekitd_uid_t
    let decl_associatedtype: sourcekitd_uid_t
    let ref_associatedtype: sourcekitd_uid_t
    let decl_typealias: sourcekitd_uid_t
    let ref_typealias: sourcekitd_uid_t
    let decl_generic_type_param: sourcekitd_uid_t
    let ref_generic_type_param: sourcekitd_uid_t
    let ref_module: sourcekitd_uid_t
    let syntaxtype_comment: sourcekitd_uid_t
    let syntaxtype_comment_marker: sourcekitd_uid_t
    let syntaxtype_comment_url: sourcekitd_uid_t
    let syntaxtype_doccomment: sourcekitd_uid_t
    let syntaxtype_doccomment_field: sourcekitd_uid_t

    let kind_keyword: sourcekitd_uid_t

    init(api: sourcekitd_functions_t) {
        notification_documentupdate = api.uid_get_from_cstr("source.notification.editor.documentupdate")!
        diag_error = api.uid_get_from_cstr("source.diagnostic.severity.error")!
        diag_warning = api.uid_get_from_cstr("source.diagnostic.severity.warning")!
        diag_note = api.uid_get_from_cstr("source.diagnostic.severity.note")!

        // MARK: Symbol Kinds

        decl_function_free = api.uid_get_from_cstr("source.lang.swift.decl.function.free")!
        ref_function_free = api.uid_get_from_cstr("source.lang.swift.ref.function.free")!
        decl_function_method_instance = api.uid_get_from_cstr("source.lang.swift.decl.function.method.instance")!
        ref_function_method_instance = api.uid_get_from_cstr("source.lang.swift.ref.function.method.instance")!
        decl_function_method_static = api.uid_get_from_cstr("source.lang.swift.decl.function.method.static")!
        ref_function_method_static = api.uid_get_from_cstr("source.lang.swift.ref.function.method.static")!
        decl_function_method_class = api.uid_get_from_cstr("source.lang.swift.decl.function.method.class")!
        ref_function_method_class = api.uid_get_from_cstr("source.lang.swift.ref.function.method.class")!
        decl_function_accessor_getter = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.getter")!
        ref_function_accessor_getter = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.getter")!
        decl_function_accessor_setter = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.setter")!
        ref_function_accessor_setter = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.setter")!
        decl_function_accessor_willset = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.willset")!
        ref_function_accessor_willset = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.willset")!
        decl_function_accessor_didset = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.didset")!
        ref_function_accessor_didset = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.didset")!
        decl_function_accessor_address = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.address")!
        ref_function_accessor_address = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.address")!
        decl_function_accessor_mutableaddress = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.mutableaddress")!
        ref_function_accessor_mutableaddress = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.mutableaddress")!
        decl_function_accessor_read = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.read")!
        ref_function_accessor_read = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.read")!
        decl_function_accessor_modify = api.uid_get_from_cstr("source.lang.swift.decl.function.accessor.modify")!
        ref_function_accessor_modify = api.uid_get_from_cstr("source.lang.swift.ref.function.accessor.modify")!
        decl_function_constructor = api.uid_get_from_cstr("source.lang.swift.decl.function.constructor")!
        ref_function_constructor = api.uid_get_from_cstr("source.lang.swift.ref.function.constructor")!
        decl_function_destructor = api.uid_get_from_cstr("source.lang.swift.decl.function.destructor")!
        ref_function_destructor = api.uid_get_from_cstr("source.lang.swift.ref.function.destructor")!
        decl_function_operator_prefix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.prefix")!
        decl_function_operator_postfix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.postfix")!
        decl_function_operator_infix = api.uid_get_from_cstr("source.lang.swift.decl.function.operator.infix")!
        ref_function_operator_prefix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.prefix")!
        ref_function_operator_postfix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.postfix")!
        ref_function_operator_infix = api.uid_get_from_cstr("source.lang.swift.ref.function.operator.infix")!
        decl_precedencegroup = api.uid_get_from_cstr("source.lang.swift.decl.precedencegroup")!
        ref_precedencegroup = api.uid_get_from_cstr("source.lang.swift.ref.precedencegroup")!
        decl_function_subscript = api.uid_get_from_cstr("source.lang.swift.decl.function.subscript")!
        ref_function_subscript = api.uid_get_from_cstr("source.lang.swift.ref.function.subscript")!
        decl_var_global = api.uid_get_from_cstr("source.lang.swift.decl.var.global")!
        ref_var_global = api.uid_get_from_cstr("source.lang.swift.ref.var.global")!
        decl_var_instance = api.uid_get_from_cstr("source.lang.swift.decl.var.instance")!
        ref_var_instance = api.uid_get_from_cstr("source.lang.swift.ref.var.instance")!
        decl_var_static = api.uid_get_from_cstr("source.lang.swift.decl.var.static")!
        ref_var_static = api.uid_get_from_cstr("source.lang.swift.ref.var.static")!
        decl_var_class = api.uid_get_from_cstr("source.lang.swift.decl.var.class")!
        ref_var_class = api.uid_get_from_cstr("source.lang.swift.ref.var.class")!
        decl_var_local = api.uid_get_from_cstr("source.lang.swift.decl.var.local")!
        ref_var_local = api.uid_get_from_cstr("source.lang.swift.ref.var.local")!
        decl_var_parameter = api.uid_get_from_cstr("source.lang.swift.decl.var.parameter")!
        decl_module = api.uid_get_from_cstr("source.lang.swift.decl.module")!
        decl_class = api.uid_get_from_cstr("source.lang.swift.decl.class")!
        ref_class = api.uid_get_from_cstr("source.lang.swift.ref.class")!
        decl_struct = api.uid_get_from_cstr("source.lang.swift.decl.struct")!
        ref_struct = api.uid_get_from_cstr("source.lang.swift.ref.struct")!
        decl_enum = api.uid_get_from_cstr("source.lang.swift.decl.enum")!
        ref_enum = api.uid_get_from_cstr("source.lang.swift.ref.enum")!
        decl_enumcase = api.uid_get_from_cstr("source.lang.swift.decl.enumcase")!
        decl_enumelement = api.uid_get_from_cstr("source.lang.swift.decl.enumelement")!
        ref_enumelement = api.uid_get_from_cstr("source.lang.swift.ref.enumelement")!
        decl_protocol = api.uid_get_from_cstr("source.lang.swift.decl.protocol")!
        ref_protocol = api.uid_get_from_cstr("source.lang.swift.ref.protocol")!
        decl_extension = api.uid_get_from_cstr("source.lang.swift.decl.extension")!
        decl_extension_struct = api.uid_get_from_cstr("source.lang.swift.decl.extension.struct")!
        decl_extension_class = api.uid_get_from_cstr("source.lang.swift.decl.extension.class")!
        decl_extension_enum = api.uid_get_from_cstr("source.lang.swift.decl.extension.enum")!
        decl_extension_protocol = api.uid_get_from_cstr("source.lang.swift.decl.extension.protocol")!
        decl_associatedtype = api.uid_get_from_cstr("source.lang.swift.decl.associatedtype")!
        ref_associatedtype = api.uid_get_from_cstr("source.lang.swift.ref.associatedtype")!
        decl_typealias = api.uid_get_from_cstr("source.lang.swift.decl.typealias")!
        ref_typealias = api.uid_get_from_cstr("source.lang.swift.ref.typealias")!
        decl_generic_type_param = api.uid_get_from_cstr("source.lang.swift.decl.generic_type_param")!
        ref_generic_type_param = api.uid_get_from_cstr("source.lang.swift.ref.generic_type_param")!
        ref_module = api.uid_get_from_cstr("source.lang.swift.ref.module")!
        syntaxtype_comment = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment")!
        syntaxtype_comment_marker = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment.mark")!
        syntaxtype_comment_url = api.uid_get_from_cstr("source.lang.swift.syntaxtype.comment.url")!
        syntaxtype_doccomment = api.uid_get_from_cstr("source.lang.swift.syntaxtype.doccomment")!
        syntaxtype_doccomment_field = api.uid_get_from_cstr("source.lang.swift.syntaxtype.doccomment.field")!

        kind_keyword = api.uid_get_from_cstr("source.lang.swift.keyword")!
    }
}

final class SKRequestDictionary {
    let dict: sourcekitd_object_t?
    let sourcekitd: SourceKit

    init(_ dict: sourcekitd_object_t? = nil, sourcekitd: SourceKit) {
        self.dict = dict ?? sourcekitd.api.request_dictionary_create(nil, nil, 0)
        self.sourcekitd = sourcekitd
    }

    deinit {
        sourcekitd.api.request_release(dict)
    }

    public subscript(key: sourcekitd_uid_t?) -> String {
        get { fatalError("request is set-only") }
        set { sourcekitd.api.request_dictionary_set_string(dict, key, newValue) }
    }

    public subscript(key: sourcekitd_uid_t?) -> Int {
        get { fatalError("request is set-only") }
        set { sourcekitd.api.request_dictionary_set_int64(dict, key, Int64(newValue)) }
    }

    public subscript(key: sourcekitd_uid_t?) -> sourcekitd_uid_t? {
        get { fatalError("request is set-only") }
        set { sourcekitd.api.request_dictionary_set_uid(dict, key, newValue) }
    }

    public subscript(key: sourcekitd_uid_t?) -> SKRequestDictionary {
        get { fatalError("request is set-only") }
        set { sourcekitd.api.request_dictionary_set_value(dict, key, newValue.dict) }
    }

    public subscript<S>(key: sourcekitd_uid_t?) -> S where S: Sequence, S.Element == String {
        get { fatalError("request is set-only") }
        set {
            let array = SKRequestArray(sourcekitd: sourcekitd)
            newValue.forEach { array.append($0) }
            sourcekitd.api.request_dictionary_set_value(dict, key, array.array)
        }
    }

    subscript(key: sourcekitd_uid_t?) -> SKRequestArray {
        get { fatalError("request is set-only") }
        set { sourcekitd.api.request_dictionary_set_value(dict, key, newValue.array) }
    }
}

final class SKRequestArray {
    let array: sourcekitd_object_t?
    let sourcekitd: SourceKit

    init(_ array: sourcekitd_object_t? = nil, sourcekitd: SourceKit) {
        self.array = array ?? sourcekitd.api.request_array_create(nil, 0)
        self.sourcekitd = sourcekitd
    }

    deinit {
        sourcekitd.api.request_release(array)
    }

    func append(_ value: String) {
        sourcekitd.api.request_array_set_string(array, -1, value)
    }
}

final class SKResponse {
    let response: sourcekitd_response_t?
    let sourcekitd: SourceKit

    init(_ response: sourcekitd_response_t?, sourcekitd: SourceKit) {
        self.response = response
        self.sourcekitd = sourcekitd
    }

    deinit {
        sourcekitd.api.response_dispose(response)
    }

    var error: String? {
        if !sourcekitd.api.response_is_error(response) {
            return nil
        }
        return description
    }

    var value: SKResponseDictionary? {
        if sourcekitd.api.response_is_error(response) {
            return nil
        }
        return SKResponseDictionary(sourcekitd.api.response_get_value(response), response: self)
    }
}

final class SKResponseDictionary {
    let dict: sourcekitd_variant_t
    let resp: SKResponse
    let parent: SKResponseDictionary!
    var sourcekitd: SourceKit { resp.sourcekitd }

    init(_ dict: sourcekitd_variant_t, response: SKResponse, parent: SKResponseDictionary! = nil) {
        self.dict = dict
        self.parent = parent
        resp = response
    }

    subscript(key: sourcekitd_uid_t?) -> String? {
        sourcekitd.api.variant_dictionary_get_string(dict, key).map(String.init(cString:))
    }

    subscript(key: sourcekitd_uid_t?) -> Int? {
        Int(sourcekitd.api.variant_dictionary_get_int64(dict, key))
    }

    subscript(key: sourcekitd_uid_t?) -> SKUID? {
        guard let uid = sourcekitd.api.variant_dictionary_get_uid(dict, key) else {
            return nil
        }
        return SKUID(uid: uid, sourcekitd: sourcekitd)
    }

    subscript(key: sourcekitd_uid_t?) -> SKResponseArray? {
        SKResponseArray(sourcekitd.api.variant_dictionary_get_value(dict, key), response: resp)
    }

    func recurseEntities(block: @escaping (SKResponseDictionary) throws -> Void) rethrows {
        try recurse(uid: sourcekitd.keys.entities, block: block)
    }

    func recurse(uid: sourcekitd_uid_t, block: @escaping (SKResponseDictionary) throws -> Void) rethrows {
        guard let array: SKResponseArray = self[uid] else {
            return
        }
        try array.forEach(parent: self) { (_, dict) -> Bool in
            try block(dict)
            try dict.recurseEntities(block: block)
            return true
        }
    }
}

final class SKResponseArray {
    let array: sourcekitd_variant_t
    let resp: SKResponse
    var sourcekitd: SourceKit { resp.sourcekitd }

    init(_ array: sourcekitd_variant_t, response: SKResponse) {
        self.array = array
        resp = response
    }

    var count: Int { sourcekitd.api.variant_array_get_count(array) }

    subscript(i: Int) -> SKResponseDictionary {
        return get(i, parent: nil)
    }

    private func get(_ i: Int, parent: SKResponseDictionary!) -> SKResponseDictionary {
        SKResponseDictionary(sourcekitd.api.variant_array_get_value(array, i), response: resp, parent: parent)
    }

    /// If the `applier` returns `false`, iteration terminates.
    @discardableResult
    func forEach(parent: SKResponseDictionary, _ applier: (Int, SKResponseDictionary) throws -> Bool) rethrows -> Bool {
        for i in 0 ..< count {
            if try applier(i, get(i, parent: parent)) == false {
                return false
            }
        }
        return true
    }
}

extension SKRequestDictionary: CustomStringConvertible {
    public var description: String {
        let ptr = sourcekitd.api.request_description_copy(dict)!
        defer { free(ptr) }
        return String(cString: ptr)
    }
}

extension SKRequestArray: CustomStringConvertible {
    var description: String {
        let ptr = sourcekitd.api.request_description_copy(array)!
        defer { free(ptr) }
        return String(cString: ptr)
    }
}

extension SKResponse: CustomStringConvertible {
    public var description: String {
        let ptr = sourcekitd.api.response_description_copy(response)!
        defer { free(ptr) }
        return String(cString: ptr)
    }
}

extension SKResponseDictionary: CustomStringConvertible {
    public var description: String {
        let ptr = sourcekitd.api.variant_description_copy(dict)!
        defer { free(ptr) }
        return String(cString: ptr)
    }
}

extension SKResponseArray: CustomStringConvertible {
    var description: String {
        let ptr = sourcekitd.api.variant_description_copy(array)!
        defer { free(ptr) }
        return String(cString: ptr)
    }
}

struct Variant: CustomStringConvertible {
    // The lifetime of this sourcekitd_variant_t is tied to the response it came
    // from, so keep a reference to the response too.
    let val: sourcekitd_variant_t
    let context: SKResponse
    var sourcekitd: SourceKit { context.sourcekitd }

    fileprivate init(val: sourcekitd_variant_t, context: SKResponse) {
        self.val = val
        self.context = context
    }

    func getString() -> String {
        let value = sourcekitd.api.variant_string_get_ptr(val)!
        let length = sourcekitd.api.variant_string_get_length(val)
        return fromCStringLen(value, length: length)!
    }

    func getStringBuffer() -> UnsafeBufferPointer<Int8> {
        UnsafeBufferPointer(start: sourcekitd.api.variant_string_get_ptr(val),
                            count: sourcekitd.api.variant_string_get_length(val))
    }

    func getInt() -> Int {
        let value = sourcekitd.api.variant_int64_get_value(val)
        return Int(value)
    }

    func getBool() -> Bool {
        let value = sourcekitd.api.variant_bool_get_value(val)
        return value
    }

    func getArray() -> SKResponseArray {
        SKResponseArray(val, response: context)
    }

    func getDictionary() -> SKResponseDictionary {
        SKResponseDictionary(val, response: context)
    }

    var description: String {
        let utf8Str = sourcekitd.api.variant_description_copy(val)!
        let result = String(cString: utf8Str)
        free(utf8Str)
        return result
    }

    func recurseOver(uid: sourcekitd_uid_t, block: @escaping (Variant) -> Void) {
        let children = sourcekitd.api.variant_dictionary_get_value(val, uid)
        guard sourcekitd.api.variant_get_type(children) == SOURCEKITD_VARIANT_TYPE_ARRAY else {
            return
        }
        _ = sourcekitd.api.variant_array_apply(children) { _, val in
            let variant = Variant(val: val, context: self.context)
            block(variant)
            variant.recurseOver(uid: uid, block: block)
            return true
        }
    }
}

private func fromCStringLen(_ ptr: UnsafePointer<Int8>, length: Int) -> String? {
    String(decoding: Array(UnsafeBufferPointer(start: ptr, count: length)).map {
        UInt8(bitPattern: $0)
    }, as: UTF8.self)
}

public struct SKUID: CustomStringConvertible {
    public let uid: sourcekitd_uid_t
    let sourcekitd: SourceKit

    init(uid: sourcekitd_uid_t, sourcekitd: SourceKit) {
        self.uid = uid
        self.sourcekitd = sourcekitd
    }

    public var description: String {
        String(cString: sourcekitd.api.uid_get_string_ptr(uid)!)
    }

    public var asString: String {
        String(cString: sourcekitd.api.uid_get_string_ptr(uid)!)
    }

    func referenceType() -> SourceKit.DeclarationType? {
        declarationType(firstSuffix: ".ref.")
    }

    func declarationType() -> SourceKit.DeclarationType? {
        declarationType(firstSuffix: ".decl.")
    }

    func declarationType(firstSuffix: String) -> SourceKit.DeclarationType? {
        let kind = description
        let prefix = "source.lang.swift" + firstSuffix
        guard kind.hasPrefix(prefix) else {
            return nil
        }
        let prefixIndex = kind.index(kind.startIndex, offsetBy: prefix.count)
        let kindSuffix = String(kind[prefixIndex...])
        switch kindSuffix {
        case "class",
             "struct":
            return .object
        case "protocol":
            return .protocol
        case "var.instance",
             "var.static",
             "var.global",
             "var.class":
            return .property
        case "function.free",
             "function.method.instance",
             "function.method.static",
             "function.method.class":
            return .method
        case "enum":
            return .enum
        case "enumelement":
            return .enumelement
        default:
            return nil
        }
    }
}

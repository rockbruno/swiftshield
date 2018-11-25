//===--------------------- SourceKitdResponse.swift -----------------------===//
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
// This file provides convenient APIs to interpret a SourceKitd response.
//===----------------------------------------------------------------------===//

import Foundation

public struct SourceKitdUID: Equatable, Hashable, CustomStringConvertible {
    public let uid: sourcekitd_uid_t

    init(uid: sourcekitd_uid_t) {
        self.uid = uid
    }

    public init(string: String) {
        self.uid = sourcekitd_uid_get_from_cstr(string)
    }

    public var description: String {
        return String(cString: sourcekitd_uid_get_string_ptr(uid))
    }

    public var asString: String {
        return String(cString: sourcekitd_uid_get_string_ptr(uid))
    }

    public var hashValue: Int {
        return uid.hashValue
    }
}

extension SourceKitdUID {
    static let kindId = SourceKitdUID(uid: get("key.kind"))
    static let nameId = SourceKitdUID(uid: get("key.name"))
    static let usrId = SourceKitdUID(uid: get("key.usr"))
    static let receiverId = SourceKitdUID(uid: get("key.receiver_usr"))
    static let entitiesId = SourceKitdUID(uid: get("key.entities"))
    static let lineId = SourceKitdUID(uid: get("key.line"))
    static let colId = SourceKitdUID(uid: get("key.column"))
    static let relatedId = SourceKitdUID(uid: get("key.related"))
    static let sourceFileId = SourceKitdUID(uid: get("key.sourcefile"))
    static let indexRequestId = SourceKitdUID(uid: get("source.request.indexsource"))

    private static func get(_ cstr: String) -> sourcekitd_uid_t {
        return sourcekitd_uid_get_from_cstr(cstr)
    }
}

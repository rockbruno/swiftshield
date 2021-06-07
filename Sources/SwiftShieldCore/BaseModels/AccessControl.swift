import Foundation

enum AccessControl: String {
    case open = "source.decl.attribute.open"
    case `public` = "source.decl.attribute.public"
    case `private` = "source.decl.attribute.private"
    case `fileprivate` = "source.decl.attribute.fileprivate"
    case `internal` = "source.decl.attribute.internal"
}

//see tools/SourceKit/lib/SwiftLang/SwiftLangSupport.cpp
enum EffectiveAccess: String {
    case `public` = "source.decl.effective_access.public"
    case `internal` = "source.decl.effective_access.internal"
    case `filePrivate` = "source.decl.effective_access.fileprivate"
    case lessThanFilePrivate = "source.decl.effective_access.less_than_fileprivate"
}

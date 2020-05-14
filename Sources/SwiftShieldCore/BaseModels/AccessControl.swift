import Foundation

enum AccessControl: String {
    case open = "source.decl.attribute.open"
    case `public` = "source.decl.attribute.public"
    case `private` = "source.decl.attribute.private"
    case `fileprivate` = "source.decl.attribute.fileprivate"
    case `internal` = "source.decl.attribute.internal"
}

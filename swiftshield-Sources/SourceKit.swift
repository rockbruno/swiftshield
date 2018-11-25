final class SourceKit {
    fileprivate static let swiftLangPrefix = "source.lang.swift"

    static var verbose = false

    static func start() {
        sourcekitd_initialize()
    }

    static func stop() {
        sourcekitd_shutdown()
    }

    public func sendSyn(request: SourceKitdRequest) -> SourceKitdResponse {
        let response = SourceKitdResponse(resp: sourcekitd_send_request_sync(request.rawRequest))
        if SourceKit.verbose {
            print(response.description)
        }
        return response
    }

    func referenceType(kind: String) -> DeclarationType? {
        return declarationType(for: kind) ?? declarationType(kind: kind, firstSuffix: ".ref.")
    }

    func declarationType(for kind: String) -> DeclarationType? {
        return declarationType(kind: kind, firstSuffix: ".decl.")
    }

    func declarationType(kind: String, firstSuffix: String) -> DeclarationType? {
        let prefix = SourceKit.swiftLangPrefix + firstSuffix
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
             "var.class":
            return .property
        case "function.free",
             "function.method.instance",
             "function.method.static",
             "function.method.class":
            return .method
        default:
            return nil
        }
    }

    func indexFile(filePath: String, compilerArgs: [String]) -> SourceKitdResponse {
        let request = SourceKitdRequest(uid: .indexRequestId)
        request.addParameter(.sourceFileId, value: filePath)
        request.addCompilerArgsToRequest(compilerArgs)
        return sendSyn(request: request)
    }
}

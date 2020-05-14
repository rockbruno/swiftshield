import Foundation

public protocol LoggerProtocol {
    func log(_ message: String, verbose: Bool, sourceKit: Bool)
    func fatalError(forMessage message: String) -> NSError
}

extension LoggerProtocol {
    func log(_ message: String) {
        log(message, verbose: false, sourceKit: false)
    }

    func log(_ message: String, verbose: Bool) {
        log(message, verbose: verbose, sourceKit: false)
    }

    func log(_ message: String, sourceKit: Bool) {
        log(message, verbose: false, sourceKit: sourceKit)
    }
}

public struct Logger: LoggerProtocol {
    let verbose: Bool
    let printSourceKit: Bool

    public init(
        verbose: Bool = false,
        printSourceKit: Bool = false
    ) {
        self.verbose = verbose
        self.printSourceKit = printSourceKit
    }

    public func fatalError(forMessage message: String) -> NSError {
        NSError(
            domain: "com.rockbruno.swiftshield",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }

    public func log(_ message: String, verbose: Bool, sourceKit: Bool) {
        if sourceKit && !printSourceKit {
            return
        }
        guard verbose == false || self.verbose else {
            return
        }
        print(message)
    }
}

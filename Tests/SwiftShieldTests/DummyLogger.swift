import Foundation
@testable import SwiftShieldCore

final class DummyLogger: LoggerProtocol {
    func log(_: String, verbose _: Bool, sourceKit _: Bool) {}

    func fatalError(forMessage message: String) -> NSError {
        NSError(domain: "test_failed", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

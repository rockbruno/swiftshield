import Foundation
@testable import SwiftShieldCore

final class ObfuscatorDelegateSpy: ObfuscatorDelegate {
    var receivedNewContent = ""
    var receivedContent = [String: String]()
    var failAfter: Int = 0
    var error: Error?
    func obfuscator(_: ObfuscatorProtocol, didObfuscateFile file: File, newContents: String) -> Error? {
        receivedNewContent = newContents
        receivedContent[file.path] = newContents
        if receivedContent.count >= failAfter {
            return error
        } else {
            return nil
        }
    }
}

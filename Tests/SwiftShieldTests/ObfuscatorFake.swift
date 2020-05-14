@testable import SwiftShieldCore
import XCTest

final class ObfuscatorFake: ObfuscatorProtocol {
    var delegate: ObfuscatorDelegate?

    var registered = Set<Module>()
    func registerModuleForObfuscation(_ module: Module) throws {
        registered.insert(module)
    }

    var registerCountWhenCallingObfuscate = 0
    var mapToReturn: ConversionMap!
    func obfuscate() throws -> ConversionMap {
        registerCountWhenCallingObfuscate = registered.count
        return mapToReturn
    }
}

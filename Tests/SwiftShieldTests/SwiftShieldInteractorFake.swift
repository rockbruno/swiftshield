@testable import SwiftShieldCore
import XCTest

final class SwiftShieldInteractorFake: SwiftShieldInteractorProtocol {
    var delegate: SwiftShieldInteractorDelegate?

    var modulesToReturn = [Module]()
    func getModulesFromProject() throws -> [Module] {
        modulesToReturn
    }

    var obfuscateReceivedModule = [Module]()
    var conversionMapToReturn: ConversionMap!
    func obfuscate(modules: [Module]) throws -> ConversionMap {
        obfuscateReceivedModule = modules
        return conversionMapToReturn
    }

    var markProjectsCalled = false
    func markProjectsAsObfuscated() throws {
        markProjectsCalled = true
    }

    var prepareMapSentMap: ConversionMap!
    func prepare(map: ConversionMap, date _: Date) throws {
        prepareMapSentMap = map
    }
}

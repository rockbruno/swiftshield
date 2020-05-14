@testable import SwiftShieldCore
import XCTest

final class SchemeInfoProviderFake: SchemeInfoProviderProtocol {
    var projectFile: File = File(path: "fakePath/path.xcodeproj")

    var schemeName: String {
        "fakeScheme"
    }

    var modulesToIgnore: Set<String> {
        []
    }

    var modulesToReturn = [Module]()
    func getModulesFromProject() throws -> [Module] {
        modulesToReturn
    }

    var markProjectsAsObfuscatedCalled = false
    var markedProjectsToReturn = [File: String]()
    func markProjectsAsObfuscated() throws -> [File: String] {
        markProjectsAsObfuscatedCalled = true
        return markedProjectsToReturn
    }
}

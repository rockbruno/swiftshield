@testable import SwiftShieldCore
import XCTest

final class FeatureTests: XCTestCase {
    func test_operators_areIgnored() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        struct Foo {
            public static func +(lhs: Foo, rhs: Foo) -> Foo { return lhs }
        }
        struct Bar {}
        func +(lhs: Bar, rhs: Bar) -> Bar { return lhs }
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"
        store.obfuscationDictionary["Bar"] = "OBS2"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        struct OBS1 {
            public static func +(lhs: OBS1, rhs: OBS1) -> OBS1 { return lhs }
        }
        struct OBS2 {}
        func +(lhs: OBS2, rhs: OBS2) -> OBS2 { return lhs }
        """)
    }

    func test_CodingKeys_isIgnored() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        struct Foo: Codable {
            enum FooCodingKeys: CodingKey {
                case a
                case b
                case c
            }
            enum RandomEnum {
                case d
                case e
                case f
            }
        }
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"
        store.obfuscationDictionary["a"] = "OBS2"
        store.obfuscationDictionary["b"] = "OBS3"
        store.obfuscationDictionary["c"] = "OBS4"
        store.obfuscationDictionary["d"] = "OBS5"
        store.obfuscationDictionary["e"] = "OBS6"
        store.obfuscationDictionary["f"] = "OBS7"
        store.obfuscationDictionary["RandomEnum"] = "OBS8"
        store.obfuscationDictionary["FooCodingKeys"] = "OBS9"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        struct OBS1: Codable {
            enum OBS9: CodingKey {
                case a
                case b
                case c
            }
            enum OBS8 {
                case OBS5
                case OBS6
                case OBS7
            }
        }
        """)
    }

    func test_internalFrameworkDelegateReferences_areIgnored() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        import UIKit

        class SomeClass: NSObject {}

        final class Foo: SomeClass, UITableViewDelegate {
            func notADelegate() {}
            var notADelegateProperty: Int { return 1 }

            override var hash: Int { return 1 }
            func tableView(
                _ tableView: UITableView,
                didSelectRowAt indexPath: IndexPath
            ) {}
        }
        """)

        store.obfuscationDictionary["Foo"] = "OBS1"
        store.obfuscationDictionary["notADelegate"] = "OBS2"
        store.obfuscationDictionary["notADelegateProperty"] = "OBS3"
        store.obfuscationDictionary["SomeClass"] = "OBS4"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        import UIKit

        class OBS4: NSObject {}

        final class OBS1: OBS4, UITableViewDelegate {
            func OBS2() {}
            var notADelegateProperty: Int { return 1 }

            override var hash: Int { return 1 }
            func tableView(
                _ tableView: UITableView,
                didSelectRowAt indexPath: IndexPath
            ) {}
        }
        """)
    }

    func test_ignorePublic_ignoresPublics() throws {
        let (obfs, store, delegate) = baseTestData(ignorePublic: true)
        let module = try testModule(withContents: """
        import UIKit

        open class Ignored {
            public func ignored2() {}
            open func ignored7() {}
            func notIgnored() {}
        }

        struct NotIgnored2 {}

        extension Int {
            public func ignored3() {}
            func notIgnored3() {}
        }

        public func ignored4() {}
        func notIgnored4() {}

        //public enum Bla {
        //    case abc
        //}

        //Broken.
        //public extension Int {
        //    func ignored5() {}
        //    func ignored6() {}
        //}
        """)

        store.obfuscationDictionary["notIgnored"] = "OBS1"
        store.obfuscationDictionary["NotIgnored2"] = "OBS2"
        store.obfuscationDictionary["notIgnored3"] = "OBS3"
        store.obfuscationDictionary["notIgnored4"] = "OBS4"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        import UIKit

        open class Ignored {
            public func ignored2() {}
            open func ignored7() {}
            func OBS1() {}
        }

        struct OBS2 {}

        extension Int {
            public func ignored3() {}
            func OBS3() {}
        }

        public func ignored4() {}
        func OBS4() {}

        //public enum Bla {
        //    case abc
        //}

        //Broken.
        //public extension Int {
        //    func ignored5() {}
        //    func ignored6() {}
        //}
        """)
    }
}

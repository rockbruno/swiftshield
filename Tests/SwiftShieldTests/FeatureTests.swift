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
            var OBS3: Int { return 1 }

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
            public var ignored8 = 0
            open var ignored12: Int { return 0 }
            func notIgnored() {}
            public static func ignored13() {}
        }

        struct NotIgnored2 {}

        extension Int {
            public func ignored3() {}
            public var ignored9: Int {
                return 0
            }
            func notIgnored3() {}
        }

        public var ignored11: String = ""
        public func ignored4() {}
        func notIgnored4() {}

        public enum Bla {
            case abc
        }

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
            public var ignored8 = 0
            open var ignored12: Int { return 0 }
            func OBS1() {}
            public static func ignored13() {}
        }

        struct OBS2 {}

        extension Int {
            public func ignored3() {}
            public var ignored9: Int {
                return 0
            }
            func OBS3() {}
        }

        public var ignored11: String = ""
        public func ignored4() {}
        func OBS4() {}

        public enum Bla {
            case abc
        }

        //Broken.
        //public extension Int {
        //    func ignored5() {}
        //    func ignored6() {}
        //}
        """)
    }

    func test_files_withEmojis() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        enum JSON {
            static func parse(_ a: String) -> String { return a }
        }

        extension String {
            func unobfuscate() -> String { return self }
        }

        func l3️⃣og(_ a: String) -> String { return JSON.parse("") }

        var paramsString = "foo"

        struct Logger {
            func log() {
                log("Hello 👨‍👩‍👧‍👧 3 A̛͚̖ 3️⃣ response up message 📲: \\(JSON.parse(paramsString.unobfuscate()).description) 🇹🇩👫👨‍👩‍👧‍👧👨‍👨‍👦"); log("")
            }

            func log(_ a: String) {
                _ = l3️⃣og("foo".unobfuscate())
            }
        }
        """)
        store.obfuscationDictionary["JSON"] = "OBS1"
        store.obfuscationDictionary["parse"] = "OBS2"
        store.obfuscationDictionary["unobfuscate"] = "OBS3"
        store.obfuscationDictionary["log"] = "OBS4"
        store.obfuscationDictionary["Logger"] = "OBS5"
        store.obfuscationDictionary["l3️⃣og"] = "OBS6"
        store.obfuscationDictionary["paramsString"] = "OBS7"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        enum OBS1 {
            static func OBS2(_ a: String) -> String { return a }
        }

        extension String {
            func OBS3() -> String { return self }
        }

        func OBS6(_ a: String) -> String { return OBS1.OBS2("") }

        var OBS7 = "foo"

        struct OBS5 {
            func OBS4() {
                OBS4("Hello 👨‍👩‍👧‍👧 3 A̛͚̖ 3️⃣ response up message 📲: \\(OBS1.OBS2(OBS7.OBS3()).description) 🇹🇩👫👨‍👩‍👧‍👧👨‍👨‍👦"); OBS4("")
            }

            func OBS4(_ a: String) {
                _ = OBS6("foo".OBS3())
            }
        }
        """)
    }

    func test_property_obfuscation() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        var prop1 = "a"
        struct Foo {
            static let prop2 = Foo()
            let prop3 = 1
            var prop4: String {
                return ""
            }
            lazy var prop5 = {
                return self.prop4
            }()
        }
        extension Foo {
            var prop6: String {
                return ""
            }
        }
        """)
        store.obfuscationDictionary["Foo"] = "OBSFOO"
        store.obfuscationDictionary["prop1"] = "OBS1"
        store.obfuscationDictionary["prop2"] = "OBS2"
        store.obfuscationDictionary["prop3"] = "OBS3"
        store.obfuscationDictionary["prop4"] = "OBS4"
        store.obfuscationDictionary["prop5"] = "OBS5"
        store.obfuscationDictionary["prop6"] = "OBS6"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        var OBS1 = "a"
        struct OBSFOO {
            static let OBS2 = OBSFOO()
            let OBS3 = 1
            var OBS4: String {
                return ""
            }
            lazy var OBS5 = {
                return self.OBS4
            }()
        }
        extension OBSFOO {
            var OBS6: String {
                return ""
            }
        }
        """)
    }

    func test_property_obfuscation_ignoresCodableChildren() throws {
        let (obfs, store, delegate) = baseTestData()
        let module = try testModule(withContents: """
        struct Foo {
            let prop1: String
            var prop2: String { return "" }
        }
        struct Bar: Codable {
            let prop3: String
            var prop4: String { return "" }
        }
        """)
        store.obfuscationDictionary["Foo"] = "OBSFOO"
        store.obfuscationDictionary["Bar"] = "OBSBAR"
        store.obfuscationDictionary["prop1"] = "OBS1"
        store.obfuscationDictionary["prop2"] = "OBS2"
        store.obfuscationDictionary["prop3"] = "OBS3"
        store.obfuscationDictionary["prop4"] = "OBS4"

        try obfs.registerModuleForObfuscation(module)
        try obfs.obfuscate()

        XCTAssertEqual(delegate.receivedContent[modifiableFilePath], """
        struct OBSFOO {
            let OBS1: String
            var OBS2: String { return "" }
        }
        struct OBSBAR: Codable {
            let prop3: String
            var prop4: String { return "" }
        }
        """)
    }
}

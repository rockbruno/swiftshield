@testable import SwiftShieldCore
import XCTest

final class ConversionMapTests: XCTestCase {
    func test_dictInit() {
        let dict = ["foo": "bar", "one": "two"]
        let map = ConversionMap(obfuscationDictionary: dict)
        XCTAssertEqual(map.toString(info: "someInfo"),
                       """
                       //
                       // SwiftShield Conversion Map
                       // someInfo
                       // Deobfuscate crash logs (or any text file) by running:
                       // swiftshield deobfuscate
                       //

                       foo ===> bar
                       one ===> two
                       """)

        XCTAssertEqual(map.obfuscationDictionary, dict)
        XCTAssertEqual(map.deobfuscationDictionary, ["bar": "foo", "two": "one"])
    }

    func test_stringInit() {
        let mapString =
            """
            //
            // SwiftShield Conversion Map
            // someInfo
            // Deobfuscate crash logs (or any text file) by running:
            // swiftshield deobfuscate
            //

            one ===> two
            foo ===> bar
            """

        let map = ConversionMap(mapString: mapString)

        XCTAssertEqual(map?.obfuscationDictionary, ["foo": "bar", "one": "two"])
        XCTAssertEqual(map?.deobfuscationDictionary, ["bar": "foo", "two": "one"])
    }

    func test_failedStringInit() {
        let mapString = "not a conversion map boyo"
        XCTAssertNil(ConversionMap(mapString: mapString))
    }

    func test_outputPath() {
        let map = ConversionMap(obfuscationDictionary: [:])
        let someDate = Date(timeIntervalSince1970: 1000)
        let locale = Locale(identifier: "pt-BR")
        let timeZone = TimeZone(secondsFromGMT: 60)!
        let path = map.outputPath(
            projectPath: "foo/bar.xcodeproj",
            date: someDate,
            locale: locale,
            timeZone: timeZone,
            filePrefix: "prefixy"
        )
        XCTAssertEqual(path, "foo/swiftshield-output/prefixy_1970-01-01_00-17-40.txt")
    }
}

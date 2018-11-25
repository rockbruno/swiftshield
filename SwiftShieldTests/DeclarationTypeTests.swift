import XCTest

class DeclarationTypeTests: XCTestCase {
    func testDeclarationTypes() {
        let prefix = "source.lang.swift"
        let declPrefix = prefix + ".decl."
        let refPrefix = prefix + ".ref."
        let sourceKit = SourceKit()
        for object in ["class", "struct"] {
            let declKind = declPrefix + object
            XCTAssertEqual(sourceKit.declarationType(for: declKind), .object)
            XCTAssertEqual(sourceKit.referenceType(kind: declKind), .object)
            let refKind = refPrefix + object
            XCTAssertEqual(sourceKit.declarationType(for: refKind), nil)
            XCTAssertEqual(sourceKit.referenceType(kind: refKind), .object)
        }
        for `protocol` in ["protocol"] {
            let declKind = declPrefix + `protocol`
            XCTAssertEqual(sourceKit.declarationType(for: declKind), .protocol)
            XCTAssertEqual(sourceKit.referenceType(kind: declKind), .protocol)
            let refKind = refPrefix + `protocol`
            XCTAssertEqual(sourceKit.declarationType(for: refKind), nil)
            XCTAssertEqual(sourceKit.referenceType(kind: refKind), .protocol)
        }
        for method in ["function.free", "function.method.instance", "function.method.static", "function.method.class"] {
            let declKind = declPrefix + method
            XCTAssertEqual(sourceKit.declarationType(for: declKind), .method)
            XCTAssertEqual(sourceKit.referenceType(kind: declKind), .method)
            let refKind = refPrefix + method
            XCTAssertEqual(sourceKit.declarationType(for: refKind), nil)
            XCTAssertEqual(sourceKit.referenceType(kind: refKind), .method)
        }
        for property in ["var.instance", "var.static", "var.class"] {
            let declKind = declPrefix + property
            XCTAssertEqual(sourceKit.declarationType(for: declKind), nil)
            XCTAssertEqual(sourceKit.referenceType(kind: declKind), nil)
            let refKind = refPrefix + property
            XCTAssertEqual(sourceKit.declarationType(for: refKind), nil)
            XCTAssertEqual(sourceKit.referenceType(kind: refKind), nil)
        }
    }
}

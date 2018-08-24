//
//  AutomaticSwiftShieldTests.swift
//  SwiftShieldTests
//
//  Created by Bruno Rocha on 8/24/18.
//  Copyright © 2018 Bruno Rocha. All rights reserved.
//

import XCTest

class AutomaticSwiftShieldTests: XCTestCase {
    func testObfuscationDataCreation() {
        let modules: [Module] = [Module(name: "test", sourceFiles: [], xibFiles: [File(filePath: "/Users/bruno.rocha/Desktop/test/test/BLABLA.xib"), File(filePath: "/Users/bruno.rocha/Desktop/test/test/Base.lproj/LaunchScreen.storyboard"), File(filePath: "/Users/bruno.rocha/Desktop/test/test/Base.lproj/Main.storyboard")], compilerArguments: []), Module(name: "MyLib", sourceFiles: [], xibFiles: [File(filePath: "/Users/bruno.rocha/Desktop/test/RapiddoUtils/Sources/Assets/StatusLine.xib")], compilerArguments: [])]
        let protector = AutomaticSwiftShield(basePath: "abc", projectToBuild: "abc", schemeToBuild: "abc", modulesToIgnore: [], protectedClassNameSize: 5)
        let obfuscationData = protector.getObfuscationData(from: modules)
        XCTAssertEqual(obfuscationData.storyboardsToObfuscate, modules.flatMap { $0.xibFiles })
        XCTAssertEqual(obfuscationData.moduleNames, ["test", "MyLib"])
    }
}

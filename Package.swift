// swift-tools-version:5.5

import PackageDescription
import Foundation

let package = Package(
    name: "swiftshield",
    products: [
        .executable(name: "swiftshield", targets: ["swiftshield"]),
        .library(name: "SwiftShieldCore", targets: ["SwiftShieldCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("0.0.2")),
        .package(url: "https://github.com/krzysztofzablocki/Difference", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.50500.0")),
    ],
    targets: [
        // Csourcekitd: C modules wrapper for sourcekitd.
        .target(
            name: "Csourcekitd",
            dependencies: []
        ),
        .executableTarget(
            name: "swiftshield",
            dependencies: ["SwiftShieldCore"]
        ),
        .target(
            name: "SwiftShieldCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                "Csourcekitd",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SwiftShieldTests",
            dependencies: ["SwiftShieldCore", "Difference"]
        ),
    ]
)

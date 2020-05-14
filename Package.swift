// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftshield",
    products: [
        .executable(name: "swiftshield", targets: ["swiftshield"]),
        .library(name: "SwiftShieldCore", targets: ["SwiftShieldCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("0.0.2")),
    ],
    targets: [
        // Csourcekitd: C modules wrapper for sourcekitd.
        .target(
            name: "Csourcekitd",
            dependencies: []
        ),
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swiftshield",
            dependencies: ["SwiftShieldCore"]
        ),
        .target(
            name: "SwiftShieldCore",
            dependencies: ["Csourcekitd", .product(name: "ArgumentParser", package: "swift-argument-parser")]
        ),
        .testTarget(
            name: "SwiftShieldTests",
            dependencies: ["SwiftShieldCore"]
        ),
    ]
)

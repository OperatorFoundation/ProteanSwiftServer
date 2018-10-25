// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProteanSwiftServer",
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Transport.git", from: "0.0.15"),
        .package(url: "https://github.com/OperatorFoundation/ProteanSwift", from: "0.0.6"),
        .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports.git", from: "0.1.8")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ProteanSwiftServer",
            dependencies: ["Protean", "ProteanSwift", "Transport"]),
        .testTarget(
            name: "ProteanSwiftServerTests",
            dependencies: ["ProteanSwiftServer"])
    ]
)

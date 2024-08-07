// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let FFIbinaryTarget: PackageDescription.Target

if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    FFIbinaryTarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.xcframework.zip")
}else {
    FFIbinaryTarget = .binaryTarget(
        name: "LoroFFI",
        url: "https://github.com/loro/loro-swift/releases/download/0.16.2-alpha.0/loroFFI.xcframework.zip",
        checksum: "a98119540ba962f1896243b27cc1e9f94629db831c9477a7fec388359d438c0c"
    )
}

let package = Package(
    name: "Loro",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Loro",
            targets: ["Loro"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        FFIbinaryTarget,
        .target(
            name: "Loro",
            dependencies: ["LoroFFI"]),
        .testTarget(
            name: "LoroTests",
            dependencies: ["Loro"]),
    ]
)

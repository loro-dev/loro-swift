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
        url: "https://github.com/loro-dev/loro-swift/releases/download/1.10.3/loroFFI.xcframework.zip",
        checksum: "0090b751b4c57e0b00eb8e3efcc4d9a7c9a237096acd80add79714ca5aa459b5"
    )
}

let package = Package(
    name: "Loro",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .visionOS(.v1)
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
            dependencies: ["LoroFFI"]
        ),
        .testTarget(
            name: "LoroTests",
            dependencies: ["Loro"]),
    ]
)

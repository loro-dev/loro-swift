// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let FFIbinaryTarget: PackageDescription.Target

// SE-0482: Cross-platform static library support via artifact bundles
// The artifact bundle supports macOS, Linux, and Windows
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    // Local/CI development: use locally built artifact bundle
    FFIbinaryTarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.artifactbundle")
} else {
    // Production: use cross-platform artifact bundle from GitHub releases
    // Contains static libraries for: macOS (arm64/x86_64), Linux (x86_64/arm64), Windows (x86_64)
    FFIbinaryTarget = .binaryTarget(
        name: "LoroFFI",
        url: "https://github.com/wendylabsinc/loro-swift/releases/download/v1.10.3/loroFFI.artifactbundle.zip",
        // TODO: Update checksum after first release is published
        checksum: "0000000000000000000000000000000000000000000000000000000000000000"
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
        .library(
            name: "Loro",
            targets: ["Loro"]),
    ],
    targets: [
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

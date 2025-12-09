// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let FFIbinaryTarget: PackageDescription.Target

// SE-0482: Cross-platform static library support via artifact bundles
// The artifact bundle is built from Rust source and supports macOS, Linux, and Windows
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    // Local development: use locally built artifact bundle
    FFIbinaryTarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.artifactbundle")
} else {
    // Release: use artifact bundle from GitHub releases
    // TODO: Update URL when cross-platform artifact bundle is published
    // For now, falls back to xcframework (Apple platforms only)
    FFIbinaryTarget = .binaryTarget(
        name: "LoroFFI",
        url: "https://github.com/loro-dev/loro-swift/releases/download/1.8.1/loroFFI.xcframework.zip",
        checksum: "6c723580b568aeccd05debc3cb40635912f5a882520cf42fe84c72220edd0f12"
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

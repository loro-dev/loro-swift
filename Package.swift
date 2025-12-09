// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let FFIbinaryTarget: PackageDescription.Target

// SE-0482: Cross-platform static library support via artifact bundles
// Supports macOS (arm64/x86_64), iOS (device + simulator), Linux (x86_64/arm64), and Windows (x86_64)
//
// For local development or CI, set LOCAL_BUILD=1 and run ./scripts/build_artifactbundle.sh first
// For releases, the artifact bundle is published to GitHub releases
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    FFIbinaryTarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.artifactbundle")
} else {
    // Cross-platform artifact bundle from GitHub releases
    FFIbinaryTarget = .binaryTarget(
        name: "LoroFFI",
        url: "https://github.com/wendylabsinc/loro-swift/releases/download/v1.10.3/loroFFI.artifactbundle.zip",
        checksum: "PLACEHOLDER_UPDATE_AFTER_RELEASE"
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
            dependencies: ["LoroFFI"],
            linkerSettings: [
                .linkedLibrary("ntdll", .when(platforms: [.windows]))
            ]
        ),
        .testTarget(
            name: "LoroTests",
            dependencies: ["Loro"]),
    ]
)

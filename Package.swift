// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let FFIbinaryTarget: PackageDescription.Target

if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    FFIbinaryTarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.xcframework.zip")
} else {
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

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// Detect the current platform
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
let isApplePlatform = true
#else
let isApplePlatform = false
#endif

// Determine which target to use for LoroFFI
let FFITarget: PackageDescription.Target
let loroDependencies: [PackageDescription.Target.Dependency]

if isApplePlatform {
    // Apple platforms use the xcframework
    if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
        FFITarget = .binaryTarget(name: "LoroFFI", path: "./loroFFI.xcframework.zip")
    } else {
        FFITarget = .binaryTarget(
            name: "LoroFFI",
            url: "https://github.com/loro-dev/loro-swift/releases/download/1.8.1/loroFFI.xcframework.zip",
            checksum: "6c723580b568aeccd05debc3cb40635912f5a882520cf42fe84c72220edd0f12"
        )
    }
    loroDependencies = ["LoroFFI"]
} else {
    // Linux/Windows use a system library target
    // The library must be built first using scripts/build_linux.sh or scripts/build_windows.ps1
    FFITarget = .systemLibrary(
        name: "LoroFFI",
        path: "Sources/LoroFFI",
        pkgConfig: nil,
        providers: []
    )
    loroDependencies = ["LoroFFI"]
}

// Define platforms - only specify for Apple platforms
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
let platforms: [SupportedPlatform] = [
    .iOS(.v13),
    .macOS(.v10_15),
    .visionOS(.v1)
]
#else
let platforms: [SupportedPlatform]? = nil
#endif

var package = Package(
    name: "Loro",
    products: [
        .library(
            name: "Loro",
            targets: ["Loro"]),
    ],
    targets: [
        FFITarget,
        .target(
            name: "Loro",
            dependencies: loroDependencies,
            linkerSettings: isApplePlatform ? nil : [
                .linkedLibrary("loro_swift", .when(platforms: [.linux])),
                .linkedLibrary("loro_swift", .when(platforms: [.windows])),
                .unsafeFlags(["-L", "Sources/LoroFFI/lib"], .when(platforms: [.linux, .windows]))
            ]
        ),
        .testTarget(
            name: "LoroTests",
            dependencies: ["Loro"]),
    ]
)

// Set platforms for Apple
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
package.platforms = [
    .iOS(.v13),
    .macOS(.v10_15),
    .visionOS(.v1)
]
#endif

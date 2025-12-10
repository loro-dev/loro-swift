<h1 align="center">loro-swift</h1>

<p align="center">
  <img alt="Swift 6.2+" src="https://img.shields.io/badge/Swift-6.2%2B-orange?logo=swift&logoColor=white">
  <img alt="Platforms" src="https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux%20%7C%20Windows-blue">
</p>

<p align="center">
  <a aria-label="X" href="https://x.com/loro_dev" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Twitter-black?style=for-the-badge&logo=Twitter">
  </a>
  <a aria-label="Discord-Link" href="https://discord.gg/tUsBSVfqzf" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Discord-black?style=for-the-badge&logo=discord">
  </a>
</p>

This repository contains experimental Swift bindings for
[Loro CRDT](https://github.com/loro-dev/loro).

If you have any suggestions for API, please feel free to create an issue or join
our [Discord](https://discord.gg/tUsBSVfqzf) community.

> Requires Swift 6.2 or newer. We rely on SE-0482 cross-platform static library artifact bundles.

Supported platforms (artifact bundle):
- macOS: arm64, x86_64
- iOS: arm64 (device), arm64/x86_64 (simulator)
- tvOS: arm64 (device), arm64/x86_64 (simulator)
- watchOS: arm64 (device), arm64/x86_64 (simulator)
- visionOS: arm64 (device), arm64 (simulator)
- Linux: x86_64-unknown-linux-gnu, aarch64-unknown-linux-gnu
- Windows: x86_64-unknown-windows-msvc


## Usage

Add the dependency in your `Package.swift`.

```swift
let package = Package(
    name: "your-project",
    products: [......],
    dependencies:[
        ...,
        .package(url: "https://github.com/loro-dev/loro-swift.git", from: "1.8.1")
    ],
    targets:[
        .executableTarget(
            ...,
            dependencies:[.product(name: "Loro", package: "loro-swift")],
        )
    ]
)
```

## Examples

```swift
import Loro

// create a Loro document
let doc = LoroDoc()

// create Root Container by getText, getList, getMap, getTree, getMovableList, getCounter
let text = doc.getText(id: "text")

try! text.insert(pos: 0, s: "abc")
try! text.delete(pos: 0, len: 1)
let s = text.toString()
// XCTAssertEqual(s, "bc")

// subscribe the event
let sub = doc.subscribeRoot{ diffEvent in
    print(diffEvent)
}

// export updates or snapshot
let doc2 = LoroDoc()
let snapshot = doc.export(mode: ExportMode.snapshot)
let updates = doc.export(mode: ExportMode.updates(from: VersionVector()))

// import updates or snapshot
let status = try! doc2.import(snapshot)
let status2 = try! doc2.import(updates)
// import batch of updates or snapshot
try! doc2.importBatch(bytes: [snapshot, updates])

// checkout to any version
let startFrontiers = doc.oplogFrontiers()
try! doc.checkout(frontiers: startFrontiers)
doc.checkoutToLatest()
```

## Develop

If you wanna build and develop this project with MacOS, you need first run this
script:

```bash
sh ./scripts/build_macos.sh
LOCAL_BUILD=1 swift test
```

The script will run `uniffi` and generate the `loroFFI.xcframework.zip`.

## Releases (cross-platform static library)

- We use Swift 6.2+ because SE-0482 enables cross-platform `staticLibrary` artifact bundles for SwiftPM (see the [proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0482-swiftpm-static-library-binary-target-non-apple-platforms.md)).
- Tag `x.y.z-pre-release` to run the pre-release workflow: it builds macOS/iOS/Linux/Windows static libs, assembles the artifact bundle, computes the checksum, and opens/updates a PR (branch `pre-release`) that updates `Package.swift` and `README.md` (Swift 6.2+ required).
- Merge the pre-release PR; when it’s merged, the release workflow for the final tag publishes the cross-platform artifact bundle used by `Package.swift`.
- Use Swift 6.2 locally (e.g., `swiftly use 6.2`) to match the toolchain required by SE-0482.

# Credits
- [uniffi-rs](https://github.com/mozilla/uniffi-rs): a multi-language bindings generator for rust
- [Automerge-swift](https://github.com/automerge/automerge-swift): `loro-swift`
    uses many of `automerge-swift`'s scripts for building and CI.

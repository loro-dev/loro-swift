<h1 align="center">loro-swift</h1>

<p align="center">
  <a aria-label="X" href="https://x.com/loro_dev" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Twitter-black?style=for-the-badge&logo=Twitter">
  </a>
  <a aria-label="Discord-Link" href="https://discord.gg/tUsBSVfqzf" target="_blank">
    <img alt="" src="https://img.shields.io/badge/Discord-black?style=for-the-badge&logo=discord">
  </a>
</p>

This repository contains experimental Swift bindings for [Loro CRDT](https://github.com/loro-dev/loro).

If you have any suggestions for API, please feel free to create an issue or join our [Discord](https://discord.gg/tUsBSVfqzf) community.

## TODO

- [x] `LoroDoc` export and import
- [x] `List`/`Map`/`Text`/`Tree`/`MovableList`/`Counter` Container
- [x] Checkout
- [x] Subscribe Event
- [x] UndoManager
- [ ] Bindings for all types in Loro
- [ ] Tests
- [ ] Benchmarks

## Usage

**Note: Loro-swift is still under development and no package has been released yet.**

Add the dependency in your `Package.swift`.

```swift
let package = Package(
    name: "your-project",
    products: [......],
    dependencies:[
        ...,
        .package(url: "https://github.com/loro-dev/loro-swift.git", from: "0.16.2-alpha.0")
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
let subId = doc.subscribeRoot{ diffEvent in
    print(diffEvent)
}
// unsubscribe
doc.unsubscribe(subId: id)

// export updates or snapshot
let doc2 = LoroDoc()
let snapshot = doc.exportSnapshot()
let updates = doc.exportFrom(vv: VersionVector())

// import updates or snapshot
try! doc2.import(snapshot)
try! doc2.import(updates)
// import batch of updates or snapshot
try! doc2.importBatch(bytes: [snapshot, updates])

// checkout to any version
let startFrontiers = doc.oplogFrontiers()
try! doc.checkout(frontiers: startFrontiers)
doc.checkoutToLatest()
```

## Develop

If you wanna build and develop this project with MacOS, you need first run this script:

```bash
sh ./scripts/build_macos.sh
```

The script will run `uniffi` and generate the `loroFFI.xcframework.zip`.

# Credits

- [Automerge-swift](https://github.com/automerge/automerge-swift): `loro-swift` uses many of `automerge-swift`'s scripts for building and CI.

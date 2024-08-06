# Loro-swift

This repository contains experimental Swift bindings for [Loro CRDT](https://github.com/loro-dev/loro).

If you have any suggestions for API, please feel free to create an issue.

## Usage

Add the dependency in your `Package.swift`.

```swift
let package = Package(
    name: "your-project",
    products: [......],
    dependencies:[
        ...,
        .package(url: "https://github.com/loro-dev/loro-swift.git")
    ],
    targets:[
        .executableTarget(
            ...,
            dependencies:[.product(name: "Loro", package: "loro-swift")],
        )
    ]
)

```

## Develop

If you wanna build and develop this project, you need first run this script:

```bash
sh ./scripts/build_swift_ffi.sh
```

The script will run `uniffi` and generate the `loroFFI.xcframework.zip`.

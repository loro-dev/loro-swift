#!/usr/bin/env bash

# Build script to create a cross-platform artifact bundle for Swift 6.2+
# This creates loroFFI.artifactbundle with static libraries for all platforms

set -euxo pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
RUST_FOLDER="$THIS_SCRIPT_DIR/../loro-swift"
SWIFT_FOLDER="$THIS_SCRIPT_DIR/../gen-swift"
BUILD_FOLDER="$RUST_FOLDER/target"
BUNDLE_FOLDER="$THIS_SCRIPT_DIR/../loroFFI.artifactbundle"
VERSION="1.10.3"

cargo_build="cargo build --manifest-path $RUST_FOLDER/Cargo.toml --features cli"

echo "▸ Clean state"
rm -rf "${BUNDLE_FOLDER}"
rm -rf "${SWIFT_FOLDER}"
mkdir -p "${SWIFT_FOLDER}"
mkdir -p "${BUNDLE_FOLDER}"

echo "▸ Detect current platform"
UNAME_S=$(uname -s)
UNAME_M=$(uname -m)

# Build for current platform
echo "▸ Build release library for current platform"
$cargo_build --release

# Generate Swift bindings
echo "▸ Generate Swift bindings"
cd "$RUST_FOLDER"

# Detect the library extension based on platform
if [[ "$UNAME_S" == "Darwin" ]]; then
    LIB_EXT="dylib"
    LIB_PREFIX="lib"
    STATIC_EXT="a"
elif [[ "$UNAME_S" == "Linux" ]]; then
    LIB_EXT="so"
    LIB_PREFIX="lib"
    STATIC_EXT="a"
else
    # Windows (MINGW/MSYS)
    LIB_EXT="dll"
    LIB_PREFIX=""
    STATIC_EXT="lib"
fi

cargo run --release \
    --features=cli \
    --bin uniffi-bindgen generate \
    --library "$BUILD_FOLDER/release/${LIB_PREFIX}loro_swift.${LIB_EXT}" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"
cd ..

# Setup artifact bundle structure
echo "▸ Create artifact bundle structure"
mkdir -p "${BUNDLE_FOLDER}/include"

# Copy header and create module map
cp "${SWIFT_FOLDER}/loroFFI.h" "${BUNDLE_FOLDER}/include/"
cat > "${BUNDLE_FOLDER}/include/module.modulemap" << 'EOF'
module LoroFFI {
    header "loroFFI.h"
    export *
}
EOF

# Copy generated Swift bindings
echo "▸ Updating LoroFFI.swift"
cp -f "${SWIFT_FOLDER}/loro.swift" "$THIS_SCRIPT_DIR/../Sources/Loro/LoroFFI.swift"

# Fix Swift 6 compatibility issues in generated code
echo "▸ Fixing Swift 6 compatibility"
LORO_FFI_SWIFT="$THIS_SCRIPT_DIR/../Sources/Loro/LoroFFI.swift"

# Fix module import capitalization (loroFFI -> LoroFFI)
if [[ "$UNAME_S" == "Darwin" ]]; then
    sed -i '' 's/canImport(loroFFI)/canImport(LoroFFI)/g' "$LORO_FFI_SWIFT"
    sed -i '' 's/import loroFFI/import LoroFFI/g' "$LORO_FFI_SWIFT"
    # Add nonisolated(unsafe) for Swift 6 strict concurrency
    sed -i '' 's/static var vtable:/nonisolated(unsafe) static var vtable:/g' "$LORO_FFI_SWIFT"
    sed -i '' 's/fileprivate static var handleMap/nonisolated(unsafe) fileprivate static var handleMap/g' "$LORO_FFI_SWIFT"
    # Fix initializationResult global var
    sed -i '' 's/private var initializationResult/nonisolated(unsafe) private var initializationResult/g' "$LORO_FFI_SWIFT"
    # Fix protocols to allow struct conformance (remove AnyObject constraint)
    sed -i '' 's/protocol LoroValueLike : AnyObject/protocol LoroValueLike/g' "$LORO_FFI_SWIFT"
    sed -i '' 's/protocol ContainerIdLike : AnyObject/protocol ContainerIdLike/g' "$LORO_FFI_SWIFT"
else
    sed -i 's/canImport(loroFFI)/canImport(LoroFFI)/g' "$LORO_FFI_SWIFT"
    sed -i 's/import loroFFI/import LoroFFI/g' "$LORO_FFI_SWIFT"
    # Add nonisolated(unsafe) for Swift 6 strict concurrency
    sed -i 's/static var vtable:/nonisolated(unsafe) static var vtable:/g' "$LORO_FFI_SWIFT"
    sed -i 's/fileprivate static var handleMap/nonisolated(unsafe) fileprivate static var handleMap/g' "$LORO_FFI_SWIFT"
    # Fix initializationResult global var
    sed -i 's/private var initializationResult/nonisolated(unsafe) private var initializationResult/g' "$LORO_FFI_SWIFT"
    # Fix protocols to allow struct conformance (remove AnyObject constraint)
    sed -i 's/protocol LoroValueLike : AnyObject/protocol LoroValueLike/g' "$LORO_FFI_SWIFT"
    sed -i 's/protocol ContainerIdLike : AnyObject/protocol ContainerIdLike/g' "$LORO_FFI_SWIFT"
fi

# Platform-specific library setup
if [[ "$UNAME_S" == "Darwin" ]]; then
    echo "▸ Building for macOS"

    # Build for both architectures
    rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true

    CFLAGS_aarch64_apple_darwin="-target aarch64-apple-darwin" \
    $cargo_build --target aarch64-apple-darwin --release

    CFLAGS_x86_64_apple_darwin="-target x86_64-apple-darwin" \
    $cargo_build --target x86_64-apple-darwin --release

    # Create universal binary
    mkdir -p "${BUNDLE_FOLDER}/loroFFI-macos"
    lipo -create \
        "${BUILD_FOLDER}/x86_64-apple-darwin/release/libloro_swift.a" \
        "${BUILD_FOLDER}/aarch64-apple-darwin/release/libloro_swift.a" \
        -output "${BUNDLE_FOLDER}/loroFFI-macos/libloro_swift.a"

    MACOS_VARIANT='{
          "path": "loroFFI-macos/libloro_swift.a",
          "supportedTriples": ["arm64-apple-macosx", "x86_64-apple-macosx"],
          "staticLibraryMetadata": {
            "headerPaths": ["include"],
            "moduleMapPath": "include/module.modulemap"
          }
        }'

elif [[ "$UNAME_S" == "Linux" ]]; then
    echo "▸ Building for Linux"

    mkdir -p "${BUNDLE_FOLDER}/loroFFI-linux"
    cp "${BUILD_FOLDER}/release/libloro_swift.a" "${BUNDLE_FOLDER}/loroFFI-linux/"

    if [[ "$UNAME_M" == "x86_64" ]]; then
        TRIPLE="x86_64-unknown-linux-gnu"
    else
        TRIPLE="aarch64-unknown-linux-gnu"
    fi

    LINUX_VARIANT='{
          "path": "loroFFI-linux/libloro_swift.a",
          "supportedTriples": ["'"$TRIPLE"'"],
          "staticLibraryMetadata": {
            "headerPaths": ["include"],
            "moduleMapPath": "include/module.modulemap"
          }
        }'
fi

# Create info.json based on platform
echo "▸ Create info.json"

if [[ "$UNAME_S" == "Darwin" ]]; then
    cat > "${BUNDLE_FOLDER}/info.json" << EOF
{
  "schemaVersion": "1.0",
  "artifacts": {
    "LoroFFI": {
      "version": "${VERSION}",
      "type": "staticLibrary",
      "variants": [
        ${MACOS_VARIANT}
      ]
    }
  }
}
EOF
elif [[ "$UNAME_S" == "Linux" ]]; then
    cat > "${BUNDLE_FOLDER}/info.json" << EOF
{
  "schemaVersion": "1.0",
  "artifacts": {
    "LoroFFI": {
      "version": "${VERSION}",
      "type": "staticLibrary",
      "variants": [
        ${LINUX_VARIANT}
      ]
    }
  }
}
EOF
fi

echo "▸ Artifact bundle created at: ${BUNDLE_FOLDER}"
echo "▸ Contents:"
find "${BUNDLE_FOLDER}" -type f

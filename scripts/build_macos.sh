#!/usr/bin/env bash

# This script was cribbed from https://github.com/automerge/automerge-swift/blob/main/scripts/build-xcframework.sh
# which was cribbed from https://github.com/y-crdt/y-uniffi/blob/7cd55266c11c424afa3ae5b3edae6e9f70d9a6bb/lib/build-xcframework.sh
# which was written by Joseph Heck and  Aidar Nugmanoff and licensed under the MIT license.

set -euxo pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LIB_NAME="libloro.a"
RUST_FOLDER="$THIS_SCRIPT_DIR/../loro-ffi"
FRAMEWORK_NAME="loroFFI"

SWIFT_FOLDER="$THIS_SCRIPT_DIR/../gen-swift"
BUILD_FOLDER="$RUST_FOLDER/target"

XCFRAMEWORK_FOLDER="$THIS_SCRIPT_DIR/../${FRAMEWORK_NAME}.xcframework"


echo "▸ Install toolchains"
rustup target add aarch64-apple-darwin # macOS ARM/M1
rustup target add x86_64-apple-darwin # macOS Intel/x86
cargo_build="cargo build --manifest-path $RUST_FOLDER/Cargo.toml"

echo "▸ Clean state"
rm -rf "${XCFRAMEWORK_FOLDER}"
rm -rf "${SWIFT_FOLDER}"
mkdir -p "${SWIFT_FOLDER}"
echo "▸ Generate Swift Scaffolding Code"
cargo run --manifest-path "$RUST_FOLDER/Cargo.toml"  \
    --features=cli \
    --bin uniffi-bindgen generate \
    "$RUST_FOLDER/src/loro.udl" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"

bash "${THIS_SCRIPT_DIR}/refine_trait.sh"

echo "▸ Building for aarch64-apple-darwin"
CFLAGS_aarch64_apple_darwin="-target aarch64-apple-darwin" \
$cargo_build --target aarch64-apple-darwin --locked --release

echo "▸ Building for x86_64-apple-darwin"
CFLAGS_x86_64_apple_darwin="-target x86_64-apple-darwin" \
$cargo_build --target x86_64-apple-darwin --locked --release

# copies the generated header into the build folder structure for local XCFramework usage
mkdir -p "${BUILD_FOLDER}/includes/loroFFI"
cp "${SWIFT_FOLDER}/loroFFI.h" "${BUILD_FOLDER}/includes/loroFFI"
cp "${SWIFT_FOLDER}/loroFFI.modulemap" "${BUILD_FOLDER}/includes/loroFFI/module.modulemap"
cp -f "${SWIFT_FOLDER}/loro.swift" "${THIS_SCRIPT_DIR}/../Sources/Loro/LoroFFI.swift"

echo "▸ Lipo (merge) x86 and arm macOS static libraries into a fat static binary"
mkdir -p "${BUILD_FOLDER}/apple-darwin/release"
lipo -create  \
    "${BUILD_FOLDER}/x86_64-apple-darwin/release/${LIB_NAME}" \
    "${BUILD_FOLDER}/aarch64-apple-darwin/release/${LIB_NAME}" \
    -output "${BUILD_FOLDER}/apple-darwin/release/${LIB_NAME}"

xcodebuild -create-xcframework \
    -library "$BUILD_FOLDER/apple-darwin/release/$LIB_NAME" \
    -headers "${BUILD_FOLDER}/includes" \
    -output "${XCFRAMEWORK_FOLDER}"

echo "▸ Compress xcframework"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_FOLDER" "$XCFRAMEWORK_FOLDER.zip"

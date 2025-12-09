#!/usr/bin/env bash

# Build script for Linux
# This builds the Rust FFI library and prepares it for Swift Package Manager

set -euxo pipefail
THIS_SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
LIB_NAME="libloro_swift.a"
RUST_FOLDER="$THIS_SCRIPT_DIR/../loro-swift"
SWIFT_FOLDER="$THIS_SCRIPT_DIR/../gen-swift"
BUILD_FOLDER="$RUST_FOLDER/target"

cargo_build="cargo build --manifest-path $RUST_FOLDER/Cargo.toml"

echo "▸ Clean state"
rm -rf "${SWIFT_FOLDER}"
mkdir -p "${SWIFT_FOLDER}"

echo "▸ Build release library"
$cargo_build --release

echo "▸ Generate Swift bindings"
cd "$RUST_FOLDER"
cargo run --release \
    --features=cli \
    --bin uniffi-bindgen generate \
    --library "$BUILD_FOLDER/release/libloro_swift.so" \
    --language swift \
    --out-dir "${SWIFT_FOLDER}"
cd ..

echo "▸ Setup headers for system library"
mkdir -p "$THIS_SCRIPT_DIR/../Sources/LoroFFI/include"
cp "${SWIFT_FOLDER}/loroFFI.h" "$THIS_SCRIPT_DIR/../Sources/LoroFFI/include/"

# Create module.modulemap
cat > "$THIS_SCRIPT_DIR/../Sources/LoroFFI/include/module.modulemap" << 'EOF'
module LoroFFI {
    header "loroFFI.h"
    export *
}
EOF

# Copy the static library
mkdir -p "$THIS_SCRIPT_DIR/../Sources/LoroFFI/lib"
cp "$BUILD_FOLDER/release/$LIB_NAME" "$THIS_SCRIPT_DIR/../Sources/LoroFFI/lib/"

echo "▸ Update LoroFFI.swift if needed"
if [ -f "${SWIFT_FOLDER}/loro.swift" ]; then
    cp -f "${SWIFT_FOLDER}/loro.swift" "$THIS_SCRIPT_DIR/../Sources/Loro/LoroFFI.swift"
fi

echo "▸ Linux build complete!"
echo "  Static library: Sources/LoroFFI/lib/$LIB_NAME"
echo "  Headers: Sources/LoroFFI/include/"

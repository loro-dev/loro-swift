rm -rf gen-swift
mkdir -p gen-swift/includes
cd loro-rs
cargo build -r
cargo run -r --bin uniffi-bindgen generate src/loro.udl --language swift --out-dir ../gen-swift
cd ..
mv gen-swift/loroFFI.h gen-swift/includes/loroFFI.h
mv gen-swift/loroFFI.modulemap gen-swift/includes/module.modulemap
xcodebuild -create-xcframework -library loro-rs/target/release/libloro.a -headers gen-swift/includes -output loroFFI.xcframework
zip -r loroFFI.xcframework.zip loroFFI.xcframework
mv gen-swift/loro.swift Sources/Loro/loroFFI.swift
sh scripts/refine_trait.sh
rm -rf gen-swift loroFFI.xcframework

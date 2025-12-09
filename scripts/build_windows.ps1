# Build script for Windows
# This builds the Rust FFI library and prepares it for Swift Package Manager

$ErrorActionPreference = "Stop"

$ThisScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibName = "loro_swift.lib"
$RustFolder = Join-Path $ThisScriptDir "..\loro-swift"
$SwiftFolder = Join-Path $ThisScriptDir "..\gen-swift"
$BuildFolder = Join-Path $RustFolder "target"

Write-Host "▸ Clean state"
if (Test-Path $SwiftFolder) {
    Remove-Item -Recurse -Force $SwiftFolder
}
New-Item -ItemType Directory -Force -Path $SwiftFolder | Out-Null

Write-Host "▸ Build release library"
cargo build --manifest-path "$RustFolder\Cargo.toml" --release

Write-Host "▸ Generate Swift bindings"
Push-Location $RustFolder
cargo run --release `
    --features=cli `
    --bin uniffi-bindgen generate `
    --library "$BuildFolder\release\loro_swift.dll" `
    --language swift `
    --out-dir $SwiftFolder
Pop-Location

Write-Host "▸ Setup headers for system library"
$IncludeDir = Join-Path $ThisScriptDir "..\Sources\LoroFFI\include"
New-Item -ItemType Directory -Force -Path $IncludeDir | Out-Null
Copy-Item "$SwiftFolder\loroFFI.h" $IncludeDir

# Create module.modulemap
$ModuleMap = @"
module LoroFFI {
    header "loroFFI.h"
    export *
}
"@
Set-Content -Path "$IncludeDir\module.modulemap" -Value $ModuleMap

# Copy the static library with SwiftPM-required lib* prefix
$LibDir = Join-Path $ThisScriptDir "..\Sources\LoroFFI\lib"
New-Item -ItemType Directory -Force -Path $LibDir | Out-Null
Copy-Item "$BuildFolder\release\$LibName" (Join-Path $LibDir "libloro_swift.lib")

Write-Host "▸ Update LoroFFI.swift if needed"
$LoroSwift = Join-Path $SwiftFolder "loro.swift"
if (Test-Path $LoroSwift) {
    Copy-Item -Force $LoroSwift (Join-Path $ThisScriptDir "..\Sources\Loro\LoroFFI.swift")
}

Write-Host "▸ Windows build complete!"
Write-Host "  Static library: Sources\LoroFFI\lib\$LibName"
Write-Host "  Headers: Sources\LoroFFI\include\"

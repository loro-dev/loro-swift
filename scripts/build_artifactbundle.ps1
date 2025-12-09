# Build script to create artifact bundle for Windows
# This creates loroFFI.artifactbundle with static libraries

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RustFolder = Join-Path $ScriptDir "..\loro-swift"
$SwiftFolder = Join-Path $ScriptDir "..\gen-swift"
$BuildFolder = Join-Path $RustFolder "target"
$BundleFolder = Join-Path $ScriptDir "..\loroFFI.artifactbundle"
$Version = "1.10.3"

$CargoBuild = "cargo build --manifest-path `"$RustFolder\Cargo.toml`" --features cli"

Write-Host "▸ Clean state"
if (Test-Path $BundleFolder) { Remove-Item -Recurse -Force $BundleFolder }
if (Test-Path $SwiftFolder) { Remove-Item -Recurse -Force $SwiftFolder }
New-Item -ItemType Directory -Force -Path $SwiftFolder | Out-Null
New-Item -ItemType Directory -Force -Path $BundleFolder | Out-Null

Write-Host "▸ Build release library for Windows"
Invoke-Expression "$CargoBuild --release"

Write-Host "▸ Generate Swift bindings"
Push-Location $RustFolder
cargo run --release --features=cli --bin uniffi-bindgen generate --library "$BuildFolder\release\loro_swift.dll" --language swift --out-dir $SwiftFolder
Pop-Location

Write-Host "▸ Create artifact bundle structure"
$IncludeFolder = Join-Path $BundleFolder "include"
New-Item -ItemType Directory -Force -Path $IncludeFolder | Out-Null

# Copy header
Copy-Item "$SwiftFolder\loroFFI.h" $IncludeFolder

# Create module map
@"
module LoroFFI {
    header "loroFFI.h"
    export *
}
"@ | Set-Content "$IncludeFolder\module.modulemap"

Write-Host "▸ Updating LoroFFI.swift"
$LoroFFISwift = Join-Path $ScriptDir "..\Sources\Loro\LoroFFI.swift"
Copy-Item "$SwiftFolder\loro.swift" $LoroFFISwift -Force

Write-Host "▸ Fixing Swift 6 compatibility"
$Content = Get-Content $LoroFFISwift -Raw
$Content = $Content -replace 'canImport\(loroFFI\)', 'canImport(LoroFFI)'
$Content = $Content -replace 'import loroFFI', 'import LoroFFI'
$Content = $Content -replace 'static var vtable:', 'nonisolated(unsafe) static var vtable:'
$Content = $Content -replace 'fileprivate static var handleMap', 'nonisolated(unsafe) fileprivate static var handleMap'
$Content = $Content -replace 'private var initializationResult', 'nonisolated(unsafe) private var initializationResult'
$Content = $Content -replace 'protocol LoroValueLike : AnyObject', 'protocol LoroValueLike'
$Content = $Content -replace 'protocol ContainerIdLike : AnyObject', 'protocol ContainerIdLike'
Set-Content $LoroFFISwift $Content

Write-Host "▸ Setting up Windows library"
$WindowsLibFolder = Join-Path $BundleFolder "loroFFI-windows"
New-Item -ItemType Directory -Force -Path $WindowsLibFolder | Out-Null
Copy-Item "$BuildFolder\release\loro_swift.lib" (Join-Path $WindowsLibFolder "libloro_swift.lib")

# Determine architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" }
$Triple = "$Arch-unknown-windows-msvc"

Write-Host "▸ Create info.json"
@"
{
  "schemaVersion": "1.0",
  "artifacts": {
    "LoroFFI": {
      "version": "$Version",
      "type": "staticLibrary",
      "variants": [
        {
          "path": "loroFFI-windows/libloro_swift.lib",
          "supportedTriples": ["$Triple"],
          "staticLibraryMetadata": {
            "headerPaths": ["include"],
            "moduleMapPath": "include/module.modulemap"
          }
        }
      ]
    }
  }
}
"@ | Set-Content "$BundleFolder\info.json"

Write-Host "▸ Artifact bundle created at: $BundleFolder"
Write-Host "▸ Contents:"
Get-ChildItem -Recurse $BundleFolder | Where-Object { !$_.PSIsContainer } | ForEach-Object { $_.FullName }

# Versioning and Synchronization

Learn how to track versions, sync documents, and time travel through document history.

## Overview

Loro uses two key concepts for versioning:

- **Version Vector**: A map of peer IDs to their latest operation counter. Useful for synchronization and version comparison.
- **Frontiers**: A compact representation of version using operation IDs. Efficient for checkpoints and time travel.

## Version Vectors

A ``VersionVector`` tracks the latest known operation from each peer:

```swift
let doc = LoroDoc()

// Get current state version
let stateVersion = doc.version()

// Get oplog (operation log) version
let oplogVersion = doc.oplogVv()
```

### Comparing Versions

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let text1 = doc1.getText(id: "text")
try text1.insert(pos: 0, s: "Hello")

let version1 = doc1.version()

try text1.insert(pos: 5, s: " World")
let version2 = doc1.version()

// Versions can be compared
print(version1 == version2) // false
```

## Frontiers

``Frontiers`` represent the "tips" of the version DAG - a compact way to identify a document state:

```swift
let doc = LoroDoc()

// Get state frontiers
let stateFrontiers = doc.stateFrontiers()

// Get oplog frontiers
let oplogFrontiers = doc.oplogFrontiers()
```

### Converting Between Versions and Frontiers

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)
let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Hello")

// Convert frontiers to version vector
let frontiers = doc.oplogFrontiers()
if let vv = doc.frontiersToVv(frontiers: frontiers) {
    print("Version vector: \(vv)")
}

// Convert version vector to frontiers
let vv = doc.oplogVv()
let convertedFrontiers = doc.vvToFrontiers(vv: vv)
```

## Synchronization

### Exporting and Importing

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let text1 = doc1.getText(id: "text")
try text1.insert(pos: 0, s: "Hello from doc1")

// Export a full snapshot
let snapshot = try doc1.export(mode: .snapshot)

// Import into another document
let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)
let _ = try doc2.import(bytes: snapshot)
```

### Incremental Updates

For efficient sync, export only changes since a known version:

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let text1 = doc1.getText(id: "text")
try text1.insert(pos: 0, s: "Initial")

// Save the version vector
let lastKnownVersion = doc1.oplogVv()

// Make more changes
try text1.insert(pos: 7, s: " content")
try text1.insert(pos: 15, s: " added")

// Export only the new changes
let updates = try doc1.export(mode: .updates(from: lastKnownVersion))

// Apply updates to another document
let doc2 = LoroDoc()
let _ = try doc2.import(bytes: updates)
```

### Batch Import

Import multiple updates efficiently:

```swift
let doc = LoroDoc()

let updates: [Data] = [snapshot1, update1, update2]
let _ = try doc.importBatch(bytes: updates)
```

### Import with Origin

Track where changes came from:

```swift
let doc = LoroDoc()
let subscription = doc.subscribeRoot { event in
    print("Changes from: \(event.origin)")
}

let _ = try doc.importWith(bytes: snapshot, origin: "server-sync")
```

## Time Travel (Checkout)

Loro supports checking out previous versions of a document. When you checkout a historical version, the document enters a **detached state** where it becomes read-only.

### Basic Time Travel

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)
let text = doc.getText(id: "text")

// Make some changes
try text.insert(pos: 0, s: "Version 1")
let v1 = doc.oplogFrontiers()

try text.delete(pos: 0, len: 9)
try text.insert(pos: 0, s: "Version 2")
let v2 = doc.oplogFrontiers()

try text.delete(pos: 0, len: 9)
try text.insert(pos: 0, s: "Version 3")

// Current state
print(text.toString()) // "Version 3"

// Travel back to version 1
try doc.checkout(frontiers: v1)
print(text.toString()) // "Version 1"

// Travel to version 2
try doc.checkout(frontiers: v2)
print(text.toString()) // "Version 2"

// Return to latest
doc.checkoutToLatest()
print(text.toString()) // "Version 3"
```

### Detached State

After calling `checkout()`, the document enters a detached state where edits are not allowed:

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)
let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Hello")
let checkpoint = doc.oplogFrontiers()

try text.insert(pos: 5, s: " World")

// Check if document is in normal (attached) state
print(doc.isDetached()) // false

// Checkout puts the document in detached state
try doc.checkout(frontiers: checkpoint)
print(doc.isDetached()) // true

// To resume editing, reattach to the latest version
doc.attach()  // or doc.checkoutToLatest()
print(doc.isDetached()) // false
```

> Note: `attach()` and `checkoutToLatest()` have the same effect - they both reattach the document to the latest version.

### Timestamp Recording

Loro can record timestamps for each change, enabling time-based navigation:

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)

// Enable automatic timestamp recording
doc.setRecordTimestamp(record: true)

let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "First edit")
doc.commit()

// Wait a moment...
try text.insert(pos: 10, s: " - Second edit")
doc.commit()

// You can also manually set the timestamp for the next commit
doc.setNextCommitTimestamp(timestamp: 1700000000)
try text.insert(pos: 0, s: "Manual timestamp: ")
doc.commit()
```

### Getting Change Metadata

You can retrieve metadata about specific changes:

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)
doc.setRecordTimestamp(record: true)

let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Hello")
doc.commit()

// Get the number of changes
let changeCount = doc.lenChanges()
print("Total changes: \(changeCount)")

// Get metadata for a specific change by ID
let id = Id(peer: 1, counter: 0)
if let changeMeta = doc.getChange(id: id) {
    print("Change ID: \(changeMeta.id)")
    print("Timestamp: \(changeMeta.timestamp)")
    print("Message: \(changeMeta.message ?? "none")")
}
```

### Commit Messages

You can attach messages to commits for better history tracking:

```swift
let doc = LoroDoc()
try doc.setPeerId(peer: 1)

let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Draft")

// Set a commit message before committing
doc.setNextCommitMessage(msg: "Initial draft")
doc.commit()

try text.delete(pos: 0, len: 5)
try text.insert(pos: 0, s: "Final version")
doc.setNextCommitMessage(msg: "Finalized document")
doc.commit()
```

## Export Modes

Loro supports several export modes:

```swift
let doc = LoroDoc()

// Full snapshot - complete document state
let snapshot = try doc.export(mode: .snapshot)

// Updates since a version - incremental changes
let updates = try doc.export(mode: .updates(from: versionVector))

// Snapshot at a specific version
let historicalSnapshot = try doc.export(mode: .snapshotAt(version: frontiers))

// State only (no history) at optional version
let stateOnly = try doc.export(mode: .stateOnly(nil))

// Shallow snapshot at frontiers
let shallow = try doc.export(mode: .shallowSnapshot(frontiers))
```

## Complete Example: Sync Manager

```swift
import Loro

class SyncManager {
    let doc: LoroDoc
    private var lastSyncedVersion: VersionVector?

    init(peerId: UInt64) throws {
        doc = LoroDoc()
        try doc.setPeerId(peer: peerId)
    }

    /// Get changes to send to server
    func getChangesToSync() throws -> Data? {
        if let lastVersion = lastSyncedVersion {
            // Send only new changes
            return try doc.export(mode: .updates(from: lastVersion))
        } else {
            // First sync - send everything
            return try doc.export(mode: .snapshot)
        }
    }

    /// Apply changes from server
    func applyRemoteChanges(_ data: Data) throws {
        let _ = try doc.importWith(bytes: data, origin: "server")
    }

    /// Mark current state as synced
    func markSynced() {
        lastSyncedVersion = doc.oplogVv()
    }

    /// Check if there are unsynced changes
    func hasUnsyncedChanges() -> Bool {
        guard let lastVersion = lastSyncedVersion else {
            return true
        }
        return doc.oplogVv() != lastVersion
    }
}
```

## Complete Example: Version History

```swift
import Loro

class DocumentWithHistory {
    let doc: LoroDoc
    private var snapshots: [(frontiers: Frontiers, label: String)] = []

    init() {
        doc = LoroDoc()
    }

    func saveSnapshot(label: String) {
        let frontiers = doc.oplogFrontiers()
        snapshots.append((frontiers, label))
    }

    func listSnapshots() -> [String] {
        return snapshots.map { $0.label }
    }

    func checkout(snapshotIndex: Int) throws {
        guard snapshotIndex < snapshots.count else { return }
        try doc.checkout(frontiers: snapshots[snapshotIndex].frontiers)
    }

    func checkoutLatest() {
        doc.checkoutToLatest()
    }

    func exportSnapshot(at index: Int) throws -> Data? {
        guard index < snapshots.count else { return nil }
        return try doc.export(mode: .snapshotAt(version: snapshots[index].frontiers))
    }
}

// Usage
let editor = DocumentWithHistory()
let text = editor.doc.getText(id: "content")

try text.insert(pos: 0, s: "Draft 1")
editor.saveSnapshot(label: "First draft")

try text.delete(pos: 0, len: 7)
try text.insert(pos: 0, s: "Draft 2 - revised")
editor.saveSnapshot(label: "Revision")

try text.pushStr(s: " - final")
editor.saveSnapshot(label: "Final")

// View history
print(editor.listSnapshots()) // ["First draft", "Revision", "Final"]

// Go back to first draft
try editor.checkout(snapshotIndex: 0)
print(text.toString()) // "Draft 1"

// Return to latest
editor.checkoutLatest()
print(text.toString()) // "Draft 2 - revised - final"
```

## Topics

### Version Types

- ``VersionVector``
- ``Frontiers``

### Export Modes

- ``ExportMode``

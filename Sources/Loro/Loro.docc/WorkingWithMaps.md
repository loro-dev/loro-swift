# Working with Maps

Learn how to use LoroMap for key-value storage with conflict resolution.

## Overview

``LoroMap`` is a key-value container that uses **Last-Write-Wins (LWW)** semantics for conflict resolution. When concurrent edits conflict, Loro compares Lamport logic timestamps to determine the winner, ensuring all peers converge to the same state.

## Basic Operations

### Creating and Accessing a Map

```swift
import Loro

let doc = LoroDoc()
let map = doc.getMap(id: "settings")
```

### Inserting Values

```swift
// String values
try map.insert(key: "username", v: "alice")

// Numeric values
try map.insert(key: "age", v: 30)
try map.insert(key: "score", v: 95.5)

// Boolean values
try map.insert(key: "isActive", v: true)

// Null values
try map.insert(key: "optionalField", v: nil)

// Arrays
try map.insert(key: "tags", v: ["swift", "crdt", "loro"])

// Nested dictionaries
try map.insert(key: "metadata", v: ["version": 1, "author": "alice"])
```

### Reading Values

```swift
// Get a value
if let value = map.get(key: "username")?.asValue() {
    switch value {
    case .string(let str):
        print("Username: \(str)")
    case .i64(let num):
        print("Number: \(num)")
    case .bool(let flag):
        print("Boolean: \(flag)")
    default:
        break
    }
}

// Get the shallow value (containers shown as IDs)
let shallowValue = map.getValue()

// Get the deep value (containers converted to nested values)
let deepValue = map.getDeepValue()
```

### Deleting Keys

```swift
// Delete a single key
try map.delete(key: "optionalField")

// Clear all keys
try map.clear()
```

## Nested Containers

Maps can contain other Loro containers:

```swift
let doc = LoroDoc()
let root = doc.getMap(id: "root")

// Insert a nested map
let profile = try root.insertContainer(key: "profile", child: LoroMap())
try profile.insert(key: "name", v: "Alice")
try profile.insert(key: "email", v: "alice@example.com")

// Insert a nested list
let friends = try root.insertContainer(key: "friends", child: LoroList())
try friends.push(v: "Bob")
try friends.push(v: "Charlie")

// Insert nested text
let bio = try root.insertContainer(key: "bio", child: LoroText())
try bio.insert(pos: 0, s: "Hello, I'm Alice!")

// Get or create a container (useful for ensuring containers exist)
let settings = try root.getOrCreateContainer(key: "settings", child: LoroMap())
try settings.insert(key: "theme", v: "dark")
```

## Conflict Resolution

LoroMap uses Last-Write-Wins based on Lamport timestamps:

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let map1 = doc1.getMap(id: "shared")

let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)
let map2 = doc2.getMap(id: "shared")

// Both peers edit the same key concurrently
try map1.insert(key: "color", v: "red")
try map2.insert(key: "color", v: "blue")

// Sync documents
let _ = try doc2.import(bytes: doc1.export(mode: .snapshot))
let _ = try doc1.import(bytes: doc2.export(mode: .snapshot))

// Both documents converge to the same value
// The peer with the larger peerId (and thus larger logical timestamp) wins
// In this case, doc2 (peerId: 2) wins, so color = "blue"
```

### Checking Last Editor

You can determine which peer last edited a key:

```swift
if let lastEditor = map.getLastEditor(key: "color") {
    print("Last edited by peer: \(lastEditor)")
}
```

## Subscribing to Changes

```swift
let doc = LoroDoc()
let map = doc.getMap(id: "observed")

let subscription = map.subscribe { event in
    print("Map changed with origin: \(event.origin)")
}

try map.insert(key: "test", v: "value")
doc.commit() // Triggers the callback

subscription?.detach() // Clean up when done
```

## Syncing Maps Between Documents

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let map1 = doc1.getMap(id: "config")
try map1.insert(key: "setting1", v: "value1")

let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)

// Import snapshot
let _ = try doc2.import(bytes: doc1.export(mode: .snapshot))

// Access the synced map
let map2 = doc2.getMap(id: "config")
let value = map2.get(key: "setting1")?.asValue()
// value == .string("value1")
```

## Complete Example: User Settings

```swift
import Loro

class UserSettings {
    let doc: LoroDoc
    let settings: LoroMap

    init() {
        doc = LoroDoc()
        settings = doc.getMap(id: "userSettings")
    }

    func setTheme(_ theme: String) throws {
        try settings.insert(key: "theme", v: theme)
    }

    func getTheme() -> String {
        if let value = settings.get(key: "theme")?.asValue(),
           case .string(let theme) = value {
            return theme
        }
        return "light" // default
    }

    func setNotificationsEnabled(_ enabled: Bool) throws {
        try settings.insert(key: "notifications", v: enabled)
    }

    func isNotificationsEnabled() -> Bool {
        if let value = settings.get(key: "notifications")?.asValue(),
           case .bool(let enabled) = value {
            return enabled
        }
        return true // default
    }

    func setFavoriteColors(_ colors: [String]) throws {
        try settings.insert(key: "favoriteColors", v: colors)
    }

    func export() throws -> Data {
        return try doc.export(mode: .snapshot)
    }

    func importSettings(_ data: Data) throws {
        let _ = try doc.import(bytes: data)
    }
}
```

## Topics

### Map Type

- ``LoroMap``

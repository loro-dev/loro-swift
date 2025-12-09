# Getting Started

Learn how to create and sync Loro documents.

## Overview

Loro provides conflict-free replicated data types (CRDTs) for building collaborative applications. This guide walks you through creating a document, adding data, and syncing between peers.

## Creating a Document

Start by creating a ``LoroDoc`` instance:

```swift
import Loro

let doc = LoroDoc()
```

## Working with Containers

Loro provides several container types for different data structures:

### Text

```swift
let text = doc.getText(id: "myText")
try text.insert(pos: 0, s: "Hello, World!")
print(text.toString()) // "Hello, World!"
```

### List

```swift
let list = doc.getList(id: "myList")
try list.insert(pos: 0, v: "first")
try list.push(v: "second")
```

### Map

```swift
let map = doc.getMap(id: "myMap")
try map.insert(key: "name", v: "Alice")
try map.insert(key: "age", v: 30)
```

### Tree

See <doc:WorkingWithTrees> for detailed information about working with tree structures.

## Syncing Documents

Loro documents can be synced using snapshots or incremental updates:

```swift
let doc1 = LoroDoc()
let doc2 = LoroDoc()

// Make changes to doc1
let text1 = doc1.getText(id: "text")
try text1.insert(pos: 0, s: "Hello")

// Export and import snapshot
let snapshot = try doc1.export(mode: .snapshot)
try doc2.import(bytes: snapshot)

// Now doc2 has the same content
let text2 = doc2.getText(id: "text")
print(text2.toString()) // "Hello"
```

## Subscribing to Changes

You can subscribe to changes in a document:

```swift
let subscription = doc.subscribeRoot { event in
    print("Document changed!")
}

// Don't forget to detach when done
subscription.detach()
```

# Working with Trees

Learn how to create and manipulate hierarchical tree structures using LoroTree.

## Overview

``LoroTree`` provides a movable tree CRDT that allows you to create hierarchical data structures where nodes can be moved between parents while maintaining consistency across distributed peers. This is useful for building features like file explorers, organizational charts, nested task lists, and any hierarchical data structure.

## Creating a Tree

Get a tree container from a ``LoroDoc``:

```swift
import Loro

let doc = LoroDoc()
let tree = doc.getTree(id: "myTree")
```

## Creating Nodes

Create root nodes and child nodes using the ``TreeParentId`` enum:

```swift
// Create a root node
let rootNode = try tree.create(parent: .root)

// Create child nodes under the root
let child1 = try tree.create(parent: .node(id: rootNode))
let child2 = try tree.create(parent: .node(id: rootNode))

// Create a grandchild
let grandchild = try tree.create(parent: .node(id: child1))
```

### Creating Nodes at Specific Positions

Use `createAt` to insert a node at a specific index among siblings:

```swift
// Insert at the beginning (index 0)
let firstChild = try tree.createAt(parent: .root, index: 0)

// Insert at a specific position
let middleChild = try tree.createAt(parent: .root, index: 1)
```

## Moving Nodes

The "movable" in movable tree refers to the ability to move nodes between parents:

```swift
// Move a node to a new parent
try tree.mov(target: grandchild, parent: .root)

// Move to a specific index under the parent
try tree.movTo(target: child1, parent: .root, to: 0)

// Move relative to siblings
try tree.movBefore(target: child2, before: child1)
try tree.movAfter(target: child1, after: child2)
```

## Querying the Tree Structure

### Getting Children

```swift
// Get all children of a node
let children = tree.children(parent: .node(id: rootNode))

// Get all root nodes
let roots = tree.roots()

// Get child count
let count = tree.childrenNum(parent: .root)
```

### Navigation

```swift
// Get the parent of a node
if let parentId = tree.parent(target: child1) {
    switch parentId {
    case .root:
        print("Node is at root level")
    case .node(let id):
        print("Parent node: \(id)")
    case .deleted:
        print("Parent was deleted")
    case .unexist:
        print("Node doesn't exist")
    }
}

// Check if a node exists
let exists = tree.contains(target: child1)

// Check if a node is deleted
let isDeleted = tree.isNodeDeleted(target: child1)
```

## Deleting Nodes

```swift
// Delete a node (and its subtree)
try tree.delete(target: child2)
```

## Node Metadata

Each tree node has an associated ``LoroMap`` for storing metadata:

```swift
// Get the metadata map for a node
let meta = tree.getMeta(target: rootNode)

// Add metadata
try meta.insert(key: "name", v: "Root Folder")
try meta.insert(key: "icon", v: "folder")
try meta.insert(key: "createdAt", v: 1699900000)

// Read metadata
if let name = meta.get(key: "name")?.asValue() {
    print("Node name: \(name)")
}
```

## Fractional Indexing

Enable fractional indexing for precise ordering control during concurrent edits:

```swift
// Enable fractional indexing with jitter for better distribution
tree.enableFractionalIndex(jitter: 8)

// Get the fractional index of a node
if let index = tree.fractionalIndex(target: child1) {
    print("Fractional index: \(index)")
}

// Check if fractional indexing is enabled
let enabled = tree.isFractionalIndexEnabled()

// Disable if needed
tree.disableFractionalIndex()
```

## Subscribing to Tree Changes

Listen for changes to the tree structure:

```swift
let subscription = tree.subscribe { event in
    // Handle tree changes
    print("Tree changed with origin: \(event.origin)")
}

// Remember to detach when done
subscription?.detach()
```

## Complete Example

Here's a complete example building a simple file system structure:

```swift
import Loro

func createFileSystem() throws {
    let doc = LoroDoc()
    let tree = doc.getTree(id: "fileSystem")

    // Create root folders
    let documents = try tree.create(parent: .root)
    let downloads = try tree.create(parent: .root)

    // Set metadata for folders
    let docsMeta = tree.getMeta(target: documents)
    try docsMeta.insert(key: "name", v: "Documents")
    try docsMeta.insert(key: "type", v: "folder")

    let dlMeta = tree.getMeta(target: downloads)
    try dlMeta.insert(key: "name", v: "Downloads")
    try dlMeta.insert(key: "type", v: "folder")

    // Create files in Documents
    let readme = try tree.create(parent: .node(id: documents))
    let readmeMeta = tree.getMeta(target: readme)
    try readmeMeta.insert(key: "name", v: "README.md")
    try readmeMeta.insert(key: "type", v: "file")
    try readmeMeta.insert(key: "size", v: 1024)

    // Move a file from Documents to Downloads
    try tree.mov(target: readme, parent: .node(id: downloads))

    // List all items in Downloads
    let downloadItems = tree.children(parent: .node(id: downloads))
    for itemId in downloadItems {
        let meta = tree.getMeta(target: itemId)
        if let name = meta.get(key: "name")?.asValue() {
            print("Item: \(name)")
        }
    }
}
```

## Topics

### Tree Types

- ``LoroTree``
- ``TreeId``
- ``TreeParentId``

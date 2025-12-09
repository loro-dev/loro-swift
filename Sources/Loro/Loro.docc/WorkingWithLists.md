# Working with Lists

Learn how to use List and MovableList containers for ordered collections.

## Overview

Loro provides two list types for ordered data:

- **``LoroList``**: A standard list supporting insert and delete operations. Best for append-only or simple list scenarios.
- **``LoroMovableList``**: An enhanced list that also supports set and move operations. Uses the Fugue algorithm for "maximal non-interleaving" during concurrent edits.

## Choosing Between List and MovableList

| Feature | LoroList | LoroMovableList |
|---------|----------|-----------------|
| Insert | Yes | Yes |
| Delete | Yes | Yes |
| Push/Pop | Yes | Yes |
| Set (replace) | No | Yes |
| Move | No | Yes |
| Performance | Faster | ~80% slower encode/decode |
| Memory | Lower | ~50% more |

Use ``LoroList`` when you only need to add and remove elements. Use ``LoroMovableList`` when you need to reorder items or replace values in place.

## Using LoroList

### Basic Operations

```swift
import Loro

let doc = LoroDoc()
let list = doc.getList(id: "myList")

// Insert elements
try list.insert(pos: 0, v: "first")
try list.insert(pos: 1, v: "second")

// Push to end
try list.push(v: "third")

// Get element at index
if let value = list.get(index: 0)?.asValue() {
    print("First element: \(value)")
}

// Get length
let count = list.len()
print("List has \(count) elements")

// Delete elements (position, count)
try list.delete(pos: 1, len: 1)

// Pop from end
let last = try list.pop()

// Clear all elements
try list.clear()
```

### Inserting Different Value Types

```swift
let list = doc.getList(id: "mixedList")

// Primitives
try list.push(v: "string")
try list.push(v: 42)
try list.push(v: 3.14)
try list.push(v: true)

// Null values
try list.push(v: nil)

// Arrays and dictionaries
try list.push(v: [1, 2, 3])
try list.push(v: ["key": "value"])
```

### Nested Containers

You can nest containers inside lists:

```swift
let list = doc.getList(id: "nested")

// Insert a nested map
let nestedMap = try list.insertContainer(pos: 0, child: LoroMap())
try nestedMap.insert(key: "name", v: "Alice")

// Insert a nested text
let nestedText = try list.insertContainer(pos: 1, child: LoroText())
try nestedText.insert(pos: 0, s: "Hello")
```

## Using LoroMovableList

``LoroMovableList`` includes all ``LoroList`` operations plus set and move:

### Set (Replace) Operation

```swift
let doc = LoroDoc()
let movableList = doc.getMovableList(id: "tasks")

// Add initial items
try movableList.push(v: "Task A")
try movableList.push(v: "Task B")
try movableList.push(v: "Task C")

// Replace item at index 1
try movableList.set(pos: 1, v: "Updated Task B")
```

### Move Operation

```swift
let movableList = doc.getMovableList(id: "sortable")

try movableList.push(v: "First")
try movableList.push(v: "Second")
try movableList.push(v: "Third")

// Move item from index 2 to index 0
try movableList.mov(from: 2, to: 0)
// Result: ["Third", "First", "Second"]
```

### Converting to Array

```swift
let movableList = doc.getMovableList(id: "items")
try movableList.push(v: "a")
try movableList.push(v: "b")
try movableList.push(v: "c")

// Get all elements as a Swift array
let values = movableList.toVec()
// values: [LoroValue.string("a"), LoroValue.string("b"), LoroValue.string("c")]
```

## Cursors for Stable Positions

Cursors provide stable position references that survive edits:

```swift
let list = doc.getList(id: "withCursors")

try list.push(v: "A")
try list.push(v: "B")
try list.push(v: "C")

// Get a cursor at position 1
if let cursor = list.getCursor(pos: 1, side: .middle) {
    // The cursor maintains its logical position even after insertions
    try list.insert(pos: 0, v: "New First")

    // Query cursor position later using doc.getCursorPos(cursor)
}
```

## Syncing Lists Between Documents

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let list1 = doc1.getList(id: "shared")
try list1.push(v: "from doc1")

let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)
let list2 = doc2.getList(id: "shared")
try list2.push(v: "from doc2")

// Sync doc1 to doc2
let _ = try doc2.import(bytes: doc1.export(mode: .snapshot))

// Both items are now in list2
// Order depends on peer IDs and timestamps
```

## Subscribing to Changes

```swift
let doc = LoroDoc()
let list = doc.getList(id: "observed")

let subscription = list.subscribe { event in
    print("List changed!")
}

try list.push(v: "new item")
doc.commit() // Triggers the callback

subscription?.detach() // Clean up when done
```

## Complete Example: Todo List

```swift
import Loro

struct TodoApp {
    let doc: LoroDoc
    let todos: LoroMovableList

    init() {
        doc = LoroDoc()
        todos = doc.getMovableList(id: "todos")
    }

    func addTodo(_ title: String) throws {
        let todoMap = try todos.pushContainer(child: LoroMap())
        try todoMap.insert(key: "title", v: title)
        try todoMap.insert(key: "completed", v: false)
        try todoMap.insert(key: "createdAt", v: Int64(Date().timeIntervalSince1970))
    }

    func toggleComplete(at index: UInt32) throws {
        if let container = todos.get(index: index)?.asContainer(),
           case .map(let map) = container {
            let current = map.get(key: "completed")?.asValue()
            if case .bool(let isComplete) = current {
                try map.insert(key: "completed", v: !isComplete)
            }
        }
    }

    func reorder(from: UInt32, to: UInt32) throws {
        try todos.mov(from: from, to: to)
    }

    func delete(at index: UInt32) throws {
        try todos.delete(pos: index, len: 1)
    }
}
```

## Topics

### List Types

- ``LoroList``
- ``LoroMovableList``

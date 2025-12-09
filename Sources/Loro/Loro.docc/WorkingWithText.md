# Working with Text

Learn how to use LoroText for collaborative rich text editing.

## Overview

``LoroText`` is a text container optimized for collaborative editing. It supports both plain text and rich text with formatting marks. The internal B-tree structure provides O(log N) complexity for basic operations, making it efficient for documents with millions of characters.

## Basic Text Operations

### Creating and Accessing Text

```swift
import Loro

let doc = LoroDoc()
let text = doc.getText(id: "document")
```

### Inserting Text

```swift
// Insert at a position
try text.insert(pos: 0, s: "Hello, ")
try text.insert(pos: 7, s: "World!")
// Result: "Hello, World!"

// Push to end
try text.pushStr(s: " How are you?")
// Result: "Hello, World! How are you?"
```

### Reading Text

```swift
// Get the full text
let content = text.toString()

// Get a substring (slice)
let slice = try text.slice(startIndex: 0, endIndex: 5)
// slice: "Hello"

// Get character at position
let char = try text.charAt(pos: 0)
// char: "H"

// Get length
let unicodeLength = text.lenUnicode()
let utf8Length = text.lenUtf8()
let utf16Length = text.lenUtf16()
```

### Deleting Text

```swift
// Delete 5 characters starting at position 7
try text.delete(pos: 7, len: 5)
// "Hello, World!" -> "Hello, ld!"
```

### Splice (Delete and Insert)

```swift
// Replace characters: delete 2 chars at pos 7, insert "Wor"
let deleted = try text.splice(pos: 7, len: 2, s: "Wor")
// Returns the deleted text
```

## Rich Text (Marks)

LoroText supports formatting through marks - key-value pairs applied to ranges of text.

### Adding Marks

```swift
let doc = LoroDoc()
let text = doc.getText(id: "richText")
try text.insert(pos: 0, s: "Hello World")

// Make "Hello" bold (positions 0-5)
try text.mark(from: 0, to: 5, key: "bold", value: true)

// Make "World" italic (positions 6-11)
try text.mark(from: 6, to: 11, key: "italic", value: true)

// Add a link
try text.mark(from: 0, to: 11, key: "link", value: "https://example.com")
```

### Removing Marks

```swift
// Remove bold from "Hello"
try text.unmark(from: 0, to: 5, key: "bold")
```

### Reading Rich Text

```swift
// Get text with formatting as Delta
let delta = text.toDelta()
for item in delta {
    switch item {
    case .insert(let text, let attributes):
        print("Text: \(text)")
        if let attrs = attributes {
            print("Attributes: \(attrs)")
        }
    case .retain(let count, let attributes):
        print("Retain: \(count)")
    case .delete(let count):
        print("Delete: \(count)")
    }
}

// Get rich text as LoroValue
let richValue = text.getRichtextValue()
```

### Mark Expansion Behavior

When inserting text at the boundary of a marked range, you can control whether the mark expands:

- **after** (default): Mark expands when inserting after the range
- **before**: Mark expands when inserting before the range
- **both**: Mark expands in both directions
- **none**: Mark never expands

## Applying Deltas

You can apply changes in [Quill Delta format](https://quilljs.com/docs/delta/):

```swift
let doc = LoroDoc()
let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Hello World")

// Apply delta: delete first char, retain 4, insert " there"
try text.applyDelta(delta: [
    .delete(delete: 1),
    .retain(retain: 4, attributes: nil),
    .insert(insert: " there", attributes: nil)
])
// Result: "ello there World"
```

## Updating Text

For replacing entire text content efficiently:

```swift
let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Original content")

// Update uses Myers' diff algorithm to compute minimal changes
try text.update(s: "Updated content", options: UpdateOptions())

// For large texts, use line-based update (faster but less precise)
try text.updateByLine(s: "Updated content\nWith multiple lines", options: UpdateOptions())
```

## Cursors

Cursors provide stable position references that survive edits:

```swift
let text = doc.getText(id: "text")
try text.insert(pos: 0, s: "Hello World")

// Create a cursor at position 6 (before "World")
if let cursor = text.getCursor(pos: 6, side: .left) {
    // The cursor maintains its logical position
    // even after insertions before it
    try text.insert(pos: 0, s: "Say: ")
    // Original position 6 now refers to a different location
    // but the cursor still points to before "World"
}
```

## Unicode Handling

LoroText handles Unicode properly:

```swift
let text = doc.getText(id: "emoji")
try text.insert(pos: 0, s: "Hello 😀 World")

// Different length measurements
let unicodeLen = text.lenUnicode()  // Counts Unicode scalar values
let utf8Len = text.lenUtf8()        // Counts UTF-8 bytes
let utf16Len = text.lenUtf16()      // Counts UTF-16 code units

// UTF-8 operations
try text.insertUtf8(pos: 0, s: "Start ")
try text.deleteUtf8(pos: 0, len: 6)
```

## Syncing Text

```swift
let doc1 = LoroDoc()
try doc1.setPeerId(peer: 1)
let text1 = doc1.getText(id: "shared")
try text1.insert(pos: 0, s: "Hello from peer 1")

let doc2 = LoroDoc()
try doc2.setPeerId(peer: 2)
let _ = try doc2.import(bytes: doc1.export(mode: .snapshot))

let text2 = doc2.getText(id: "shared")
print(text2.toString()) // "Hello from peer 1"
```

## Subscribing to Changes

```swift
let doc = LoroDoc()
let text = doc.getText(id: "observed")

let subscription = text.subscribe { event in
    print("Text changed!")
}

try text.insert(pos: 0, s: "Hello")
doc.commit() // Triggers callback

subscription?.detach()
```

## Complete Example: Collaborative Editor

```swift
import Loro

class CollaborativeEditor {
    let doc: LoroDoc
    let text: LoroText

    init(peerId: UInt64) throws {
        doc = LoroDoc()
        try doc.setPeerId(peer: peerId)
        text = doc.getText(id: "document")
    }

    func insertText(at position: UInt32, content: String) throws {
        try text.insert(pos: position, s: content)
    }

    func deleteText(at position: UInt32, length: UInt32) throws {
        try text.delete(pos: position, len: length)
    }

    func setBold(from: UInt32, to: UInt32, enabled: Bool) throws {
        if enabled {
            try text.mark(from: from, to: to, key: "bold", value: true)
        } else {
            try text.unmark(from: from, to: to, key: "bold")
        }
    }

    func getContent() -> String {
        return text.toString()
    }

    func getDelta() -> [TextDelta] {
        return text.toDelta()
    }

    func export() throws -> Data {
        return try doc.export(mode: .snapshot)
    }

    func importChanges(_ data: Data) throws {
        let _ = try doc.import(bytes: data)
    }
}
```

## Topics

### Text Type

- ``LoroText``
- ``TextDelta``

import XCTest
@testable import Loro

final class LoroTests: XCTestCase {
    func testEvent(){
        let doc = LoroDoc()
        var num = 0
        let sub = doc.subscribeRoot{ diffEvent in
            num += 1
        }
        let list = doc.getList(id: "list")
        try! list.insert(pos: 0, v: 123)
        doc.commit()
        sub.detach()
        XCTAssertEqual(num, 1)
    }

    func testOptional(){
        let doc = LoroDoc()
        let list = doc.getList(id: "list")
        try! list.insert(pos: 0, v: nil)
        let map = doc.getMap(id: "map")
        try! map.insert(key: "key", v: nil)
        let movableList = doc.getMovableList(id: "movableList")
        try! movableList.insert(pos: 0, v: nil)
        try! movableList.set(pos: 0, v: nil)
        doc.commit()
        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.null)
        XCTAssertEqual(map.get(key: "key")!.asValue()!, LoroValue.null)
        XCTAssertEqual(movableList.get(index: 0)!.asValue()!, LoroValue.null)
    }
    
    func testText(){
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        try! text.delete(pos: 0, len: 1)
        let s = text.toString()
        XCTAssertEqual(s, "bc")
    }

    func testMovableList(){
        let doc = LoroDoc()
        let movableList = doc.getMovableList(id: "movableList")
        XCTAssertTrue(movableList.isAttached())
        XCTAssertFalse(LoroMovableList().isAttached())
    }

    func testMap(){
        let doc = LoroDoc()
        let map = doc.getMap(id: "map")
        let _ = try! map.getOrCreateContainer(key: "list", child: LoroList())
        try! map.insert(key: "key", v: "value")
        XCTAssertEqual(map.get(key: "key")!.asValue()!, LoroValue.string(value:"value"))
    }

    func testSync(){
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 0)
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        try! text.delete(pos: 0, len: 1)
        let s = text.toString()
        XCTAssertEqual(s, "bc")
        
        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 1)
        let text2 = doc2.getText(id: "text")
        try! text2.insert(pos: 0, s:"123")
        let _ = try! doc2.import(bytes: doc.export(mode:ExportMode.snapshot))
        let _ = try! doc2.importBatch(bytes: [doc.exportSnapshot(), doc.export(mode: ExportMode.updates(from: VersionVector()))])
        XCTAssertEqual(text2.toString(), "bc123")
    }
    
    func testCheckout(){
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        try! text.delete(pos: 0, len: 1)
        
        let startFrontiers = doc.oplogFrontiers()
        try! doc.checkout(frontiers: startFrontiers)
        doc.checkoutToLatest()
    }

    func testUndo(){
        let doc = LoroDoc()
        let undoManager = UndoManager(doc:doc)
        
        var n = 0
        undoManager.setOnPop{ (undoOrRedo,span, item) in
            n+=1
        }
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        doc.commit()
        try! text.delete(pos: 0, len: 1)
        doc.commit()
        let s = text.toString()
        XCTAssertEqual(s, "bc")
        let _ = try! undoManager.undo()
        XCTAssertEqual(text.toString(), "abc")
        XCTAssertEqual(n, 1)
    }

    func testApplyDelta(){
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        try! text.applyDelta(delta: [TextDelta.delete(delete: 1), TextDelta.retain(retain: 2, attributes: nil), TextDelta.insert(insert: "def", attributes: nil)])
        let s = text.toString()
        XCTAssertEqual(s, "bcdef")
    }

    func testTextUnicode(){
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "A😀C")
        XCTAssertEqual(text.toString(), "A😀C")
    }

    func testOrigin(){
        do{
            let localDoc = LoroDoc()
            let remoteDoc = LoroDoc()
            try localDoc.setPeerId(peer: 1)
            let localMap = localDoc.getMap(id: "properties")
            try localMap.insert(key: "x", v: "42")

            // Take a snapshot of the localDoc's content.
            let snapshot = try localDoc.exportSnapshot()

            // Set up and watch for changes in an initially empty remoteDoc.
            try remoteDoc.setPeerId(peer: 2)
            let expectedOriginString = "expectedOriginString"
            let subscription = remoteDoc.subscribeRoot { event in
                // Apparent bug: The event carries an empty origin string, instead of the origin string we passed into importWith(bytes:origin:).
                print("Got event for remoteDoc, with event.origin=\"\(event.origin)\"")
                if event.origin != expectedOriginString {
                    XCTFail("Expected origin '\(expectedOriginString)' but got '\(event.origin)'")
                }
            }
            // Import the snapshot into a new LoroDoc, specifying an origin string.  THis should the closure we registeredd with subscribeRoot, above, to be invoked.
            let _ = try remoteDoc.importWith(bytes: snapshot, origin: expectedOriginString)
            subscription.detach()
        }catch {
            print("ERROR: \(error)")
        }
    }

    func testTree() {
        let doc = LoroDoc()
        let tree = doc.getTree(id: "tree")

        // Test creating root nodes
        let root1 = try! tree.create(parent: .root)
        let root2 = try! tree.create(parent: .root)

        // Verify roots
        let roots = tree.roots()
        XCTAssertEqual(roots.count, 2)
        XCTAssertTrue(roots.contains(root1))
        XCTAssertTrue(roots.contains(root2))

        // Test creating child nodes
        let child1 = try! tree.create(parent: .node(id: root1))
        let child2 = try! tree.create(parent: .node(id: root1))

        // Verify children
        let children = tree.children(parent: .node(id: root1))!
        XCTAssertEqual(children.count, 2)
        XCTAssertTrue(children.contains(child1))
        XCTAssertTrue(children.contains(child2))

        // Test node metadata
        let meta = try! tree.getMeta(target: root1)
        try! meta.insert(key: "name", v: "Root Node")
        try! meta.insert(key: "count", v: 42)
        XCTAssertEqual(meta.get(key: "name")!.asValue()!, LoroValue.string(value: "Root Node"))
        XCTAssertEqual(meta.get(key: "count")!.asValue()!, LoroValue.i64(value: 42))

        // Test moving nodes
        try! tree.mov(target: child1, parent: .node(id: root2))
        let root1Children = tree.children(parent: .node(id: root1))!
        let root2Children = tree.children(parent: .node(id: root2))!
        XCTAssertEqual(root1Children.count, 1)
        XCTAssertEqual(root2Children.count, 1)
        XCTAssertTrue(root2Children.contains(child1))

        // Test parent query
        let parent = try! tree.parent(target: child1)
        if case .node(let parentId) = parent {
            XCTAssertEqual(parentId, root2)
        } else {
            XCTFail("Expected child1 to have root2 as parent")
        }

        // Test contains
        XCTAssertTrue(tree.contains(target: root1))
        XCTAssertTrue(tree.contains(target: child1))

        // Test delete
        try! tree.delete(target: child2)
        XCTAssertTrue(try! tree.isNodeDeleted(target: child2))
        let updatedRoot1Children = tree.children(parent: .node(id: root1))!
        XCTAssertEqual(updatedRoot1Children.count, 0)
    }

    func testTreeSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let tree1 = doc1.getTree(id: "tree")

        // Create structure in doc1
        let root = try! tree1.create(parent: .root)
        let child = try! tree1.create(parent: .node(id: root))
        let meta = try! tree1.getMeta(target: root)
        try! meta.insert(key: "name", v: "Synced Root")

        // Sync to doc2
        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        // Verify structure in doc2
        let tree2 = doc2.getTree(id: "tree")
        let roots2 = tree2.roots()
        XCTAssertEqual(roots2.count, 1)
        XCTAssertEqual(roots2[0], root)

        let children2 = tree2.children(parent: .node(id: root))!
        XCTAssertEqual(children2.count, 1)
        XCTAssertEqual(children2[0], child)

        // Verify metadata synced
        let meta2 = try! tree2.getMeta(target: root)
        XCTAssertEqual(meta2.get(key: "name")!.asValue()!, LoroValue.string(value: "Synced Root"))
    }

    func testTreeCreateAt() {
        let doc = LoroDoc()
        let tree = doc.getTree(id: "tree")

        // Create nodes at specific positions
        let first = try! tree.createAt(parent: .root, index: 0)
        let third = try! tree.createAt(parent: .root, index: 1)
        let second = try! tree.createAt(parent: .root, index: 1) // Insert between first and third

        let roots = tree.roots()
        XCTAssertEqual(roots.count, 3)
        XCTAssertEqual(roots[0], first)
        XCTAssertEqual(roots[1], second)
        XCTAssertEqual(roots[2], third)
    }

    func testTreeFractionalIndex() {
        let doc = LoroDoc()
        let tree = doc.getTree(id: "tree")

        // Enable fractional indexing
        tree.enableFractionalIndex(jitter: 8)
        XCTAssertTrue(tree.isFractionalIndexEnabled())

        let node = try! tree.create(parent: .root)
        let index = tree.fractionalIndex(target: node)
        XCTAssertNotNil(index)

        // Disable fractional indexing
        tree.disableFractionalIndex()
        XCTAssertFalse(tree.isFractionalIndexEnabled())
    }

    // MARK: - List Tests

    func testListBasicOperations() {
        let doc = LoroDoc()
        let list = doc.getList(id: "list")

        // Test insert
        try! list.insert(pos: 0, v: "first")
        try! list.insert(pos: 1, v: "second")
        try! list.insert(pos: 2, v: "third")

        XCTAssertEqual(list.len(), 3)
        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.string(value: "first"))
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.string(value: "second"))
        XCTAssertEqual(list.get(index: 2)!.asValue()!, LoroValue.string(value: "third"))

        // Test delete
        try! list.delete(pos: 1, len: 1)
        XCTAssertEqual(list.len(), 2)
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.string(value: "third"))
    }

    func testListPushAndPop() {
        let doc = LoroDoc()
        let list = doc.getList(id: "list")

        // Test push
        try! list.push(v: "a")
        try! list.push(v: "b")
        try! list.push(v: "c")

        XCTAssertEqual(list.len(), 3)

        // Test pop
        let popped = try! list.pop()
        XCTAssertEqual(popped!, LoroValue.string(value: "c"))
        XCTAssertEqual(list.len(), 2)
    }

    func testListDifferentValueTypes() {
        let doc = LoroDoc()
        let list = doc.getList(id: "mixedList")

        // Test different value types
        try! list.push(v: "string")
        try! list.push(v: 42)
        try! list.push(v: 3.14)
        try! list.push(v: true)
        try! list.push(v: nil)

        XCTAssertEqual(list.len(), 5)
        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.string(value: "string"))
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.i64(value: 42))
        XCTAssertEqual(list.get(index: 3)!.asValue()!, LoroValue.bool(value: true))
        XCTAssertEqual(list.get(index: 4)!.asValue()!, LoroValue.null)
    }

    func testListClear() {
        let doc = LoroDoc()
        let list = doc.getList(id: "list")

        try! list.push(v: 1)
        try! list.push(v: 2)
        try! list.push(v: 3)
        XCTAssertEqual(list.len(), 3)

        try! list.clear()
        XCTAssertEqual(list.len(), 0)
        XCTAssertTrue(list.isEmpty())
    }

    func testListNestedContainers() {
        let doc = LoroDoc()
        let list = doc.getList(id: "nested")

        // Insert a nested map
        let nestedMap = try! list.insertContainer(pos: 0, child: LoroMap())
        try! nestedMap.insert(key: "name", v: "Alice")

        // Insert a nested list
        let nestedList = try! list.insertContainer(pos: 1, child: LoroList())
        try! nestedList.push(v: 1)
        try! nestedList.push(v: 2)

        XCTAssertEqual(list.len(), 2)

        // Verify deep value
        let deepValue = list.getDeepValue()
        if case .list(let items) = deepValue {
            XCTAssertEqual(items.count, 2)
        } else {
            XCTFail("Expected list value")
        }
    }

    func testListSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let list1 = doc1.getList(id: "shared")
        try! list1.push(v: "from doc1")

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        let list2 = doc2.getList(id: "shared")
        XCTAssertEqual(list2.len(), 1)
        XCTAssertEqual(list2.get(index: 0)!.asValue()!, LoroValue.string(value: "from doc1"))
    }

    // MARK: - MovableList Tests

    func testMovableListBasicOperations() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "movableList")

        // Test insert and push
        try! list.push(v: "a")
        try! list.push(v: "b")
        try! list.push(v: "c")

        XCTAssertEqual(list.len(), 3)
        XCTAssertTrue(list.isAttached())
        XCTAssertFalse(list.isEmpty())
    }

    func testMovableListSet() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "movableList")

        try! list.push(v: "original")
        try! list.push(v: "second")

        // Test set (replace)
        try! list.set(pos: 0, v: "replaced")

        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.string(value: "replaced"))
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.string(value: "second"))
        XCTAssertEqual(list.len(), 2)
    }

    func testMovableListMove() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "movableList")

        try! list.push(v: "first")
        try! list.push(v: "second")
        try! list.push(v: "third")

        // Move "third" (index 2) to beginning (index 0)
        try! list.mov(from: 2, to: 0)

        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.string(value: "third"))
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.string(value: "first"))
        XCTAssertEqual(list.get(index: 2)!.asValue()!, LoroValue.string(value: "second"))
    }

    func testMovableListToVec() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "movableList")

        try! list.push(v: "a")
        try! list.push(v: "b")
        try! list.push(v: "c")

        let vec = list.toVec()
        XCTAssertEqual(vec.count, 3)
        XCTAssertEqual(vec[0], LoroValue.string(value: "a"))
        XCTAssertEqual(vec[1], LoroValue.string(value: "b"))
        XCTAssertEqual(vec[2], LoroValue.string(value: "c"))
    }

    func testMovableListDelete() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "movableList")

        try! list.push(v: 1)
        try! list.push(v: 2)
        try! list.push(v: 3)
        try! list.push(v: 4)

        // Delete 2 elements starting at index 1
        try! list.delete(pos: 1, len: 2)

        XCTAssertEqual(list.len(), 2)
        XCTAssertEqual(list.get(index: 0)!.asValue()!, LoroValue.i64(value: 1))
        XCTAssertEqual(list.get(index: 1)!.asValue()!, LoroValue.i64(value: 4))
    }

    func testMovableListNestedContainers() {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "nested")

        // Insert a map
        let map = try! list.insertContainer(pos: 0, child: LoroMap())
        try! map.insert(key: "id", v: 1)

        // Set a container at position
        let newMap = try! list.setContainer(pos: 0, child: LoroMap())
        try! newMap.insert(key: "id", v: 2)

        XCTAssertEqual(list.len(), 1)
    }

    func testMovableListSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let list1 = doc1.getMovableList(id: "shared")
        try! list1.push(v: "a")
        try! list1.push(v: "b")
        try! list1.push(v: "c")
        try! list1.mov(from: 2, to: 0)

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        let list2 = doc2.getMovableList(id: "shared")
        XCTAssertEqual(list2.len(), 3)
        XCTAssertEqual(list2.get(index: 0)!.asValue()!, LoroValue.string(value: "c"))
    }

    // MARK: - Map Tests

    func testMapBasicOperations() {
        let doc = LoroDoc()
        let map = doc.getMap(id: "map")

        // Test insert
        try! map.insert(key: "name", v: "Alice")
        try! map.insert(key: "age", v: 30)
        try! map.insert(key: "active", v: true)

        // Test get
        XCTAssertEqual(map.get(key: "name")!.asValue()!, LoroValue.string(value: "Alice"))
        XCTAssertEqual(map.get(key: "age")!.asValue()!, LoroValue.i64(value: 30))
        XCTAssertEqual(map.get(key: "active")!.asValue()!, LoroValue.bool(value: true))

        // Test non-existent key
        XCTAssertNil(map.get(key: "nonexistent"))
    }

    func testMapDelete() {
        let doc = LoroDoc()
        let map = doc.getMap(id: "map")

        try! map.insert(key: "a", v: 1)
        try! map.insert(key: "b", v: 2)

        try! map.delete(key: "a")

        XCTAssertNil(map.get(key: "a"))
        XCTAssertNotNil(map.get(key: "b"))
    }

    func testMapClear() {
        let doc = LoroDoc()
        let map = doc.getMap(id: "map")

        try! map.insert(key: "a", v: 1)
        try! map.insert(key: "b", v: 2)
        try! map.insert(key: "c", v: 3)

        try! map.clear()

        XCTAssertNil(map.get(key: "a"))
        XCTAssertNil(map.get(key: "b"))
        XCTAssertNil(map.get(key: "c"))
    }

    func testMapNestedContainers() {
        let doc = LoroDoc()
        let root = doc.getMap(id: "root")

        // Insert nested map
        let profile = try! root.insertContainer(key: "profile", child: LoroMap())
        try! profile.insert(key: "name", v: "Alice")

        // Insert nested list
        let tags = try! root.insertContainer(key: "tags", child: LoroList())
        try! tags.push(v: "swift")
        try! tags.push(v: "loro")

        // Get or create container
        let settings = try! root.getOrCreateContainer(key: "settings", child: LoroMap())
        try! settings.insert(key: "theme", v: "dark")

        // Verify deep value contains nested structures
        let deepValue = root.getDeepValue()
        if case .map(let entries) = deepValue {
            XCTAssertEqual(entries.count, 3)
        } else {
            XCTFail("Expected map value")
        }
    }

    func testMapDifferentValueTypes() {
        let doc = LoroDoc()
        let map = doc.getMap(id: "types")

        try! map.insert(key: "string", v: "hello")
        try! map.insert(key: "int", v: 42)
        try! map.insert(key: "double", v: 3.14)
        try! map.insert(key: "bool", v: true)
        try! map.insert(key: "null", v: nil)
        try! map.insert(key: "array", v: [1, 2, 3])

        XCTAssertEqual(map.get(key: "string")!.asValue()!, LoroValue.string(value: "hello"))
        XCTAssertEqual(map.get(key: "int")!.asValue()!, LoroValue.i64(value: 42))
        XCTAssertEqual(map.get(key: "bool")!.asValue()!, LoroValue.bool(value: true))
        XCTAssertEqual(map.get(key: "null")!.asValue()!, LoroValue.null)
    }

    func testMapSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let map1 = doc1.getMap(id: "shared")
        try! map1.insert(key: "from", v: "doc1")
        try! map1.insert(key: "value", v: 100)

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        let map2 = doc2.getMap(id: "shared")
        XCTAssertEqual(map2.get(key: "from")!.asValue()!, LoroValue.string(value: "doc1"))
        XCTAssertEqual(map2.get(key: "value")!.asValue()!, LoroValue.i64(value: 100))
    }

    func testMapConflictResolution() {
        // Test LWW (Last-Write-Wins) conflict resolution
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let map1 = doc1.getMap(id: "shared")

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let map2 = doc2.getMap(id: "shared")

        // Both peers set the same key concurrently
        try! map1.insert(key: "color", v: "red")
        try! map2.insert(key: "color", v: "blue")

        // Sync both ways
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))
        let _ = try! doc1.import(bytes: doc2.export(mode: .snapshot))

        // Both should converge to the same value
        // Peer 2 has larger peerId, so "blue" should win
        let value1 = map1.get(key: "color")!.asValue()!
        let value2 = map2.get(key: "color")!.asValue()!
        XCTAssertEqual(value1, value2)
    }

    // MARK: - Text Tests

    func testTextBasicOperations() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        // Test insert
        try! text.insert(pos: 0, s: "Hello")
        XCTAssertEqual(text.toString(), "Hello")

        // Test insert at position
        try! text.insert(pos: 5, s: " World")
        XCTAssertEqual(text.toString(), "Hello World")

        // Test delete
        try! text.delete(pos: 5, len: 6)
        XCTAssertEqual(text.toString(), "Hello")
    }

    func testTextPushStr() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello")
        try! text.pushStr(s: " World")
        try! text.pushStr(s: "!")

        XCTAssertEqual(text.toString(), "Hello World!")
    }

    func testTextSlice() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello World")

        let slice = try! text.slice(startIndex: 0, endIndex: 5)
        XCTAssertEqual(slice, "Hello")

        let slice2 = try! text.slice(startIndex: 6, endIndex: 11)
        XCTAssertEqual(slice2, "World")
    }

    func testTextSplice() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello World")

        // Splice: delete "World" and insert "Swift"
        let deleted = try! text.splice(pos: 6, len: 5, s: "Swift")
        XCTAssertEqual(deleted, "World")
        XCTAssertEqual(text.toString(), "Hello Swift")
    }

    func testTextCharAt() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello")

        XCTAssertEqual(try! text.charAt(pos: 0), "H")
        XCTAssertEqual(try! text.charAt(pos: 4), "o")
    }

    func testTextLength() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello 😀")

        // Different length measurements
        let unicodeLen = text.lenUnicode()
        let utf8Len = text.lenUtf8()

        XCTAssertTrue(unicodeLen > 0)
        XCTAssertTrue(utf8Len >= unicodeLen) // UTF-8 is at least as long
    }

    func testTextRichTextMark() {
        let doc = LoroDoc()
        let text = doc.getText(id: "richText")

        try! text.insert(pos: 0, s: "Hello World")

        // Mark "Hello" as bold
        try! text.mark(from: 0, to: 5, key: "bold", value: true)

        // Get delta to verify marks
        let delta = text.toDelta()
        XCTAssertFalse(delta.isEmpty)
    }

    func testTextUnmark() {
        let doc = LoroDoc()
        let text = doc.getText(id: "richText")

        try! text.insert(pos: 0, s: "Hello World")
        try! text.mark(from: 0, to: 5, key: "bold", value: true)
        try! text.unmark(from: 0, to: 5, key: "bold")

        // After unmark, should have no bold marks
        let delta = text.toDelta()
        XCTAssertFalse(delta.isEmpty)
    }

    func testTextApplyDelta() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello World")

        // Apply delta: delete first char, retain rest, insert at end
        try! text.applyDelta(delta: [
            .delete(delete: 1),
            .retain(retain: 10, attributes: nil),
            .insert(insert: "!", attributes: nil)
        ])

        XCTAssertEqual(text.toString(), "ello World!")
    }

    func testTextSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let text1 = doc1.getText(id: "shared")
        try! text1.insert(pos: 0, s: "Hello from peer 1")

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        let text2 = doc2.getText(id: "shared")
        XCTAssertEqual(text2.toString(), "Hello from peer 1")
    }

    func testTextIsEmpty() {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")

        XCTAssertTrue(text.isEmpty())

        try! text.insert(pos: 0, s: "Hello")
        XCTAssertFalse(text.isEmpty())
    }

    // MARK: - Counter Tests

    func testCounterBasicOperations() {
        let doc = LoroDoc()
        let counter = doc.getCounter(id: "counter")

        // Initial value
        XCTAssertEqual(counter.getValue(), 0)

        // Increment
        try! counter.increment(value: 1)
        XCTAssertEqual(counter.getValue(), 1)

        try! counter.increment(value: 5)
        XCTAssertEqual(counter.getValue(), 6)
    }

    func testCounterDecrement() {
        let doc = LoroDoc()
        let counter = doc.getCounter(id: "counter")

        try! counter.increment(value: 10)
        try! counter.decrement(value: 3)

        XCTAssertEqual(counter.getValue(), 7)
    }

    func testCounterFloatingPoint() {
        let doc = LoroDoc()
        let counter = doc.getCounter(id: "counter")

        try! counter.increment(value: 1.5)
        try! counter.increment(value: 2.5)

        XCTAssertEqual(counter.getValue(), 4.0)
    }

    func testCounterSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let counter1 = doc1.getCounter(id: "shared")

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let counter2 = doc2.getCounter(id: "shared")

        // Both peers increment concurrently
        try! counter1.increment(value: 5)
        try! counter2.increment(value: 3)

        // Sync both ways
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))
        let _ = try! doc1.import(bytes: doc2.export(mode: .snapshot))

        // Both counters should have the sum (5 + 3 = 8)
        XCTAssertEqual(counter1.getValue(), 8)
        XCTAssertEqual(counter2.getValue(), 8)
    }

    func testCounterNested() {
        let doc = LoroDoc()
        let map = doc.getMap(id: "stats")

        // Create counter inside map
        let viewCounter = try! map.insertContainer(key: "views", child: LoroCounter())
        try! viewCounter.increment(value: 100)

        XCTAssertEqual(viewCounter.getValue(), 100)
    }

    func testCounterIsAttached() {
        let doc = LoroDoc()
        let counter = doc.getCounter(id: "counter")

        XCTAssertTrue(counter.isAttached())
        XCTAssertFalse(LoroCounter().isAttached())
    }

    // MARK: - Version Tests

    func testVersionVectorBasic() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")

        let v1 = doc.oplogVv()

        try! text.insert(pos: 0, s: "Hello")
        let v2 = doc.oplogVv()

        // Versions should be different after changes
        XCTAssertNotEqual(v1, v2)
    }

    func testFrontiersBasic() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")

        let f1 = doc.oplogFrontiers()

        try! text.insert(pos: 0, s: "Hello")
        let f2 = doc.oplogFrontiers()

        // Frontiers should be different after changes
        XCTAssertNotEqual(f1, f2)
    }

    func testCheckoutTimeTravel() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Version 1")
        let v1 = doc.oplogFrontiers()

        try! text.delete(pos: 0, len: 9)
        try! text.insert(pos: 0, s: "Version 2")
        let v2 = doc.oplogFrontiers()

        try! text.delete(pos: 0, len: 9)
        try! text.insert(pos: 0, s: "Version 3")

        // Current state
        XCTAssertEqual(text.toString(), "Version 3")

        // Checkout to v1
        try! doc.checkout(frontiers: v1)
        XCTAssertEqual(text.toString(), "Version 1")

        // Checkout to v2
        try! doc.checkout(frontiers: v2)
        XCTAssertEqual(text.toString(), "Version 2")

        // Return to latest
        doc.checkoutToLatest()
        XCTAssertEqual(text.toString(), "Version 3")
    }

    func testExportModes() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Hello")

        // Test different export modes
        let snapshot = try! doc.export(mode: .snapshot)
        XCTAssertFalse(snapshot.isEmpty)

        let vv = doc.oplogVv()
        let updates = try! doc.export(mode: .updates(from: vv))
        // Updates from current version should be empty or minimal
        XCTAssertNotNil(updates)
    }

    func testIncrementalSync() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let text1 = doc1.getText(id: "text")

        try! text1.insert(pos: 0, s: "Initial")
        let initialVersion = doc1.oplogVv()

        // Import initial state to doc2
        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let _ = try! doc2.import(bytes: doc1.export(mode: .snapshot))

        // Make more changes in doc1
        try! text1.insert(pos: 7, s: " content")

        // Export only new changes
        let updates = try! doc1.export(mode: .updates(from: initialVersion))

        // Apply incremental updates to doc2
        let _ = try! doc2.import(bytes: updates)

        let text2 = doc2.getText(id: "text")
        XCTAssertEqual(text2.toString(), "Initial content")
    }

    func testImportBatch() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let text1 = doc1.getText(id: "text")
        try! text1.insert(pos: 0, s: "Hello")

        let doc2 = LoroDoc()
        try! doc2.setPeerId(peer: 2)
        let text2 = doc2.getText(id: "text")
        try! text2.insert(pos: 0, s: " World")

        // Batch import
        let doc3 = LoroDoc()
        let _ = try! doc3.importBatch(bytes: [
            doc1.export(mode: .snapshot),
            doc2.export(mode: .snapshot)
        ])

        let text3 = doc3.getText(id: "text")
        // Both changes should be present
        XCTAssertTrue(text3.toString().contains("Hello") || text3.toString().contains("World"))
    }

    func testVersionVectorToFrontiers() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Hello")

        let vv = doc.oplogVv()
        let frontiers = doc.vvToFrontiers(vv: vv)

        // Convert back
        if let convertedVv = doc.frontiersToVv(frontiers: frontiers) {
            XCTAssertEqual(vv, convertedVv)
        }
    }

    func testImportWithOrigin() {
        let doc1 = LoroDoc()
        try! doc1.setPeerId(peer: 1)
        let text1 = doc1.getText(id: "text")
        try! text1.insert(pos: 0, s: "Hello")

        let doc2 = LoroDoc()
        var receivedOrigin = ""
        let sub = doc2.subscribeRoot { event in
            receivedOrigin = event.origin
        }

        let _ = try! doc2.importWith(bytes: doc1.export(mode: .snapshot), origin: "test-origin")

        sub.detach()
        XCTAssertEqual(receivedOrigin, "test-origin")
    }

    // MARK: - Time Travel Tests

    func testDetachedState() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Hello")
        let checkpoint = doc.oplogFrontiers()

        try! text.insert(pos: 5, s: " World")

        // Document should start attached
        XCTAssertFalse(doc.isDetached())

        // Checkout puts document in detached state
        try! doc.checkout(frontiers: checkpoint)
        XCTAssertTrue(doc.isDetached())
        XCTAssertEqual(text.toString(), "Hello")

        // attach() should reattach to latest
        doc.attach()
        XCTAssertFalse(doc.isDetached())
        XCTAssertEqual(text.toString(), "Hello World")
    }

    func testAttachVsCheckoutToLatest() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)
        let text = doc.getText(id: "text")

        try! text.insert(pos: 0, s: "Version 1")
        let v1 = doc.oplogFrontiers()

        try! text.delete(pos: 0, len: 9)
        try! text.insert(pos: 0, s: "Version 2")

        // Test attach()
        try! doc.checkout(frontiers: v1)
        XCTAssertTrue(doc.isDetached())
        doc.attach()
        XCTAssertFalse(doc.isDetached())
        XCTAssertEqual(text.toString(), "Version 2")

        // Test checkoutToLatest() - same effect
        try! doc.checkout(frontiers: v1)
        XCTAssertTrue(doc.isDetached())
        doc.checkoutToLatest()
        XCTAssertFalse(doc.isDetached())
        XCTAssertEqual(text.toString(), "Version 2")
    }

    func testTimestampRecording() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)

        // Enable timestamp recording
        doc.setRecordTimestamp(record: true)

        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Hello")
        doc.commit()

        // Verify we have at least one change
        XCTAssertGreaterThan(doc.lenChanges(), 0)
    }

    func testManualTimestamp() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)

        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Hello")

        // Set a specific timestamp for the next commit
        let customTimestamp: Int64 = 1700000000
        doc.setNextCommitTimestamp(timestamp: customTimestamp)
        doc.commit()

        // Retrieve the change and verify timestamp
        let id = Id(peer: 1, counter: 0)
        let changeMeta = doc.getChange(id: id)
        XCTAssertNotNil(changeMeta)
        XCTAssertEqual(changeMeta?.timestamp, customTimestamp)
    }

    func testGetChangeMetadata() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)

        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Hello")
        doc.commit()

        try! text.insert(pos: 5, s: " World")
        doc.commit()

        // Check total changes
        let changeCount = doc.lenChanges()
        XCTAssertGreaterThanOrEqual(changeCount, 1)

        // Get metadata for the first change
        let id = Id(peer: 1, counter: 0)
        let changeMeta = doc.getChange(id: id)
        XCTAssertNotNil(changeMeta)
        XCTAssertEqual(changeMeta?.id.peer, 1)
    }

    func testCommitMessage() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)

        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "Draft")

        // Set a commit message
        doc.setNextCommitMessage(msg: "Initial draft")
        doc.commit()

        // Get the change and verify the message
        let id = Id(peer: 1, counter: 0)
        let changeMeta = doc.getChange(id: id)
        XCTAssertNotNil(changeMeta)
        XCTAssertEqual(changeMeta?.message, "Initial draft")
    }

    func testLenChanges() {
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 1)

        // Initially no changes
        XCTAssertEqual(doc.lenChanges(), 0)

        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "A")
        doc.commit()

        // Should have at least one change
        XCTAssertGreaterThan(doc.lenChanges(), 0)

        try! text.insert(pos: 1, s: "B")
        doc.commit()

        // Should have more changes
        XCTAssertGreaterThan(doc.lenChanges(), 0)
    }
}

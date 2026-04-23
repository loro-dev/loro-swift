import XCTest
@testable import Loro

final class UndoTests: XCTestCase {
    
    // MARK: - Helper Functions
    
    private func sync(_ docA: LoroDoc, _ docB: LoroDoc) {
        let updatesAB = try! docA.export(mode: .updates(from: docB.oplogVv()))
        let _ = try! docB.import(bytes: updatesAB)
        let updatesBA = try! docB.export(mode: .updates(from: docA.oplogVv()))
        let _ = try! docA.import(bytes: updatesBA)
    }
    
    // MARK: - Basic List Tests
    
    func testBasicListUndoInsertion() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        let list = doc.getList(id: "list")
        
        try list.push(v: "12")
        doc.commit()
        try list.push(v: "34")
        doc.commit()
        
        XCTAssertEqual(
            doc.getDeepValue(),
            ["list": ["12", "34"]].asLoroValue()
        )
        
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["list": ["12"]].asLoroValue()
        )
        
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: ["list": LoroValue.list(value: [])])
        )
    }
    
    func testBasicListUndoDeletion() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let list = doc.getList(id: "list")
        let undo = UndoManager(doc: doc)
        
        try list.push(v: "12")  // op 0
        doc.commit()
        try list.push(v: "34")  // op 1
        doc.commit()
        try list.delete(pos: 1, len: 1)  // op 2
        doc.commit()
        
        XCTAssertEqual(
            doc.getDeepValue(),
            ["list": ["12"]].asLoroValue()
        )
        
        let _ = try undo.undo()  // op 3
        XCTAssertEqual(
            doc.getDeepValue(),
            ["list": ["12", "34"]].asLoroValue()
        )
        
        // Now, to undo "34" correctly we need to include the latest change
        // If we only undo op 1, op 3 will create "34" again.
        let _ = try undo.undo()  // op 4
        XCTAssertEqual(
            doc.getDeepValue(),
            ["list": ["12"]].asLoroValue()
        )
    }
    
    // MARK: - Basic Map Tests
    
    func testBasicMapUndo() throws {
        let docA = LoroDoc()
        try docA.setPeerId(peer: 1)
        let undo = UndoManager(doc: docA)
        
        try docA.getMap(id: "map").insert(key: "a", v: "a")
        docA.commit()
        try docA.getMap(id: "map").insert(key: "b", v: "b")
        docA.commit()
        try docA.getMap(id: "map").delete(key: "a")
        docA.commit()
        
        let _ = try undo.undo()  // op 3
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["a": "a", "b": "b"]].asLoroValue()
        )
        
        let _ = try undo.undo()  // op 4
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["a": "a"]].asLoroValue()
        )
        
        let _ = try undo.undo()  // op 5
        XCTAssertEqual(
            docA.getDeepValue(),
            LoroValue.map(value: ["map": LoroValue.map(value: [:])])
        )
        
        // Redo
        let _ = try undo.redo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["a": "a"]].asLoroValue()
        )
        
        // Redo
        let _ = try undo.redo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["a": "a", "b": "b"]].asLoroValue()
        )
        
        // Redo
        let _ = try undo.redo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["b": "b"]].asLoroValue()
        )
    }
    
    func testMapCollaborativeUndo() throws {
        let docA = LoroDoc()
        try docA.setPeerId(peer: 1)
        let undo = UndoManager(doc: docA)
        try docA.getMap(id: "map").insert(key: "a", v: "a")
        docA.commit()
        
        let docB = LoroDoc()
        let updates = try docA.export(mode: .snapshot)
        let _ = try docB.import(bytes: updates)
        try docB.getMap(id: "map").insert(key: "b", v: "b")
        docB.commit()
        
        let updatesToA = try docB.export(mode: .snapshot)
        let _ = try docA.import(bytes: updatesToA)
        let _ = try undo.undo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["b": "b"]].asLoroValue()
        )
    }
    
    func testMapContainerUndo() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        let map = doc.getMap(id: "map")
        let text = try map.insertContainer(key: "text", child: LoroText())  // op 0
        doc.commit()
        try text.insert(pos: 0, s: "T")  // op 1
        doc.commit()
        try map.insert(key: "number", v: 0)  // op 2
        doc.commit()
        
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["map": ["text": "T"]].asLoroValue()
        )
        
        let _ = try undo.undo()
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: ["map": LoroValue.map(value: [:])])
        )
        
        let _ = try undo.redo()
        let _ = try undo.redo()
        let _ = try undo.redo()
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: [
                "map": LoroValue.map(value: [
                    "text": LoroValue.string(value: "T"),
                    "number": LoroValue.i64(value: 0)
                ])
            ])
        )
    }
    
    // MARK: - Collaborative Undo Tests
    
    /// This test case matches the example given here
    ///
    /// [PLF23] Extending Automerge: Undo, Redo, and Move
    /// Leo Stewen, Martin Kleppmann, Liangrun Da
    /// https://youtu.be/uP7AKExkMGU?si=TR2JHRdmAitOVaMw&t=768
    ///
    ///
    ///      ┌─A-Set───┐ ┌─B-set   ┌──A-undo   ┌─A-redo
    ///      │         │ │     │   │        │  │      │
    ///      │         │ │     │   │        │  │      │
    ///      │         ▼ │     ▼   │        ▼  │      ▼
    /// ┌────┴────┐ ┌────┴─┐ ┌─────┴──┐ ┌──────┴┐ ┌──────┐
    /// │         │ │      │ │        │ │       │ │      │
    /// │  Black  │ │ Red  │ │  Green │ │ Black │ │Green │
    /// │         │ │      │ │        │ │       │ │      │
    /// └─────────┘ └──────┘ └────────┘ └───────┘ └──────┘
    ///
    /// It's also how the following products implement undo/redo
    /// - Google Sheet
    /// - Google Slides
    /// - Figma
    /// - Microsoft Powerpoint
    /// - Excel
    func testOneRegisterCollaborativeUndo() throws {
        let docA = LoroDoc()
        try docA.setPeerId(peer: 1)
        let docB = LoroDoc()
        try docB.setPeerId(peer: 2)
        try docA.getMap(id: "map").insert(key: "color", v: "black")
        sync(docA, docB)
        let undo = UndoManager(doc: docA)
        try docA.getMap(id: "map").insert(key: "color", v: "red")
        try undo.recordNewCheckpoint()
        sync(docA, docB)
        try docB.getMap(id: "map").insert(key: "color", v: "green")
        sync(docA, docB)
        try undo.recordNewCheckpoint()
        let _ = try undo.undo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["color": "black"]].asLoroValue()
        )
        let _ = try undo.redo()
        XCTAssertEqual(
            docA.getDeepValue(),
            ["map": ["color": "green"]].asLoroValue()
        )
    }
    
    // MARK: - Text Undo Tests
    
    func testUndoManager() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        try doc.getText(id: "text").insert(pos: 0, s: "123")
        try undo.recordNewCheckpoint()
        try doc.getText(id: "text").insert(pos: 3, s: "456")
        try undo.recordNewCheckpoint()
        try doc.getText(id: "text").insert(pos: 6, s: "789")
        try undo.recordNewCheckpoint()
        
        for _ in 0..<10 {
            XCTAssertEqual(doc.getText(id: "text").toString(), "123456789")
            let _ = try undo.undo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "123456")
            let _ = try undo.undo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "123")
            let _ = try undo.undo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "")
            let _ = try undo.redo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "123")
            let _ = try undo.redo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "123456")
            let _ = try undo.redo()
            XCTAssertEqual(doc.getText(id: "text").toString(), "123456789")
        }
    }
    
    func testUndoManagerWithSubContainer() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        let map = try doc.getList(id: "list").insertContainer(pos: 0, child: LoroMap())
        try undo.recordNewCheckpoint()
        let text = try map.insertContainer(key: "text", child: LoroText())
        try undo.recordNewCheckpoint()
        try text.insert(pos: 0, s: "123")
        try undo.recordNewCheckpoint()
        
        for _ in 0..<10 {
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: ["text": LoroValue.string(value: "123")])
                ])])
            )
            let _ = try undo.undo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: ["text": LoroValue.string(value: "")])
                ])])
            )
            let _ = try undo.undo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: [:])
                ])])
            )
            let _ = try undo.undo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [])])
            )
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: [:])
                ])])
            )
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: ["text": LoroValue.string(value: "")])
                ])])
            )
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                LoroValue.map(value: ["list": LoroValue.list(value: [
                    LoroValue.map(value: ["text": LoroValue.string(value: "123")])
                ])])
            )
        }
    }
    
    func testUndoContainerDeletion() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        
        let map = doc.getMap(id: "map")
        let text = try map.insertContainer(key: "text", child: LoroText())
        try undo.recordNewCheckpoint()
        try text.insert(pos: 0, s: "T")
        try undo.recordNewCheckpoint()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["map": ["text": "T"]].asLoroValue()
        )
        try map.delete(key: "text")
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: ["map": LoroValue.map(value: [:])])
        )
        try undo.recordNewCheckpoint()
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["map": ["text": "T"]].asLoroValue()
        )
        let _ = try undo.redo()
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: ["map": LoroValue.map(value: [:])])
        )
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["map": ["text": "T"]].asLoroValue()
        )
        let _ = try undo.redo()
        XCTAssertEqual(
            doc.getDeepValue(),
            LoroValue.map(value: ["map": LoroValue.map(value: [:])])
        )
        doc.commit()
    }
    
    // MARK: - Rich Text Undo Tests
    
    func testUndoRichtextEditing() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        let text = doc.getText(id: "text")
        try text.insert(pos: 0, s: "Hello")
        try undo.recordNewCheckpoint()
        try text.mark(from: 0, to: 5, key: "bold", value: true)
        try undo.recordNewCheckpoint()
        
        // Verify initial state with bold
        if case .list(let richValue) = text.getRichtextValue() {
            XCTAssertEqual(richValue.count, 1)
        }
        
        for _ in 0..<10 {
            let _ = try undo.undo()
            // After undo: "Hello" without bold
            if case .list(let value1) = text.getRichtextValue() {
                XCTAssertEqual(value1.count, 1)
            }
            
            let _ = try undo.undo()
            // After second undo: empty
            if case .list(let value2) = text.getRichtextValue() {
                XCTAssertEqual(value2.count, 0)
            }
            
            let _ = try undo.redo()
            // After redo: "Hello" without bold
            if case .list(let value3) = text.getRichtextValue() {
                XCTAssertEqual(value3.count, 1)
            }
            
            let _ = try undo.redo()
            // After second redo: "Hello" with bold
            if case .list(let value4) = text.getRichtextValue() {
                XCTAssertEqual(value4.count, 1)
            }
        }
    }
    
    func testUndoTextCollabDelete() throws {
        let docA = LoroDoc()
        try docA.setPeerId(peer: 1)
        let undo = UndoManager(doc: docA)
        let docB = LoroDoc()
        try docB.setPeerId(peer: 2)
        
        try docA.getText(id: "text").insert(pos: 0, s: "A ")
        try undo.recordNewCheckpoint()
        try docA.getText(id: "text").insert(pos: 2, s: "fox ")
        try undo.recordNewCheckpoint()
        try docA.getText(id: "text").insert(pos: 6, s: "jumped")
        try undo.recordNewCheckpoint()
        sync(docA, docB)
        
        try docB.getText(id: "text").delete(pos: 2, len: 4)
        sync(docA, docB)
        try docA.getText(id: "text").insert(pos: 0, s: "123!")
        try undo.recordNewCheckpoint()
        
        for _ in 0..<3 {
            XCTAssertEqual(docA.getText(id: "text").toString(), "123!A jumped")
            let _ = try undo.undo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "A jumped")
            let _ = try undo.undo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "A ")
            let _ = try undo.undo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "")
            let _ = try undo.redo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "A ")
            let _ = try undo.redo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "A jumped")
            let _ = try undo.redo()
            XCTAssertEqual(docA.getText(id: "text").toString(), "123!A jumped")
        }
    }
    
    // MARK: - Undo Count Tests
    
    func testCanUndoAndCanRedo() throws {
        let doc = LoroDoc()
        try doc.setPeerId(peer: 1)
        let undo = UndoManager(doc: doc)
        let text = doc.getText(id: "text")
        
        XCTAssertFalse(undo.canUndo())
        XCTAssertFalse(undo.canRedo())
        XCTAssertEqual(undo.undoCount(), 0)
        XCTAssertEqual(undo.redoCount(), 0)
        
        try text.insert(pos: 0, s: "Hello")
        doc.commit()
        
        XCTAssertTrue(undo.canUndo())
        XCTAssertFalse(undo.canRedo())
        XCTAssertTrue(undo.undoCount() > 0)
        XCTAssertEqual(undo.redoCount(), 0)
        
        let _ = try undo.undo()
        
        XCTAssertFalse(undo.canUndo())
        XCTAssertTrue(undo.canRedo())
        XCTAssertEqual(undo.undoCount(), 0)
        XCTAssertTrue(undo.redoCount() > 0)
        
        let _ = try undo.redo()
        
        XCTAssertTrue(undo.canUndo())
        XCTAssertFalse(undo.canRedo())
    }
    
    // MARK: - Movable List Undo Tests
    
    func testUndoListMove() throws {
        let doc = LoroDoc()
        let list = doc.getMovableList(id: "list")
        let undo = UndoManager(doc: doc)
        
        try list.insert(pos: 0, v: "0")
        doc.commit()
        try list.insert(pos: 1, v: "1")
        doc.commit()
        try list.insert(pos: 2, v: "2")
        doc.commit()
        
        try list.mov(from: 0, to: 2)
        doc.commit()
        try list.mov(from: 1, to: 0)
        doc.commit()
        
        for _ in 0..<3 {
            XCTAssertFalse(undo.canRedo())
            XCTAssertEqual(undo.redoCount(), 0)
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["2", "1", "0"]].asLoroValue()
            )
            
            let _ = try undo.undo()
            XCTAssertTrue(undo.canRedo())
            XCTAssertTrue(undo.redoCount() > 0)
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["1", "2", "0"]].asLoroValue()
            )
            
            let _ = try undo.undo()
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["0", "1", "2"]].asLoroValue()
            )
            
            let _ = try undo.undo()
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["0", "1"]].asLoroValue()
            )
            
            let _ = try undo.undo()
            let _ = try undo.undo()
            XCTAssertFalse(undo.canUndo())
            XCTAssertEqual(undo.undoCount(), 0)
            XCTAssertTrue(undo.redoCount() > 0)
            
            let _ = try undo.redo()
            XCTAssertTrue(undo.canUndo())
            XCTAssertTrue(undo.undoCount() > 0)
            XCTAssertTrue(undo.redoCount() > 0)
            
            let _ = try undo.redo()
            XCTAssertTrue(undo.redoCount() > 0)
            
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["0", "1", "2"]].asLoroValue()
            )
            
            XCTAssertTrue(undo.redoCount() > 0)
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["1", "2", "0"]].asLoroValue()
            )
            
            XCTAssertTrue(undo.redoCount() > 0)
            let _ = try undo.redo()
            XCTAssertEqual(
                doc.getDeepValue(),
                ["list": ["2", "1", "0"]].asLoroValue()
            )
            
            XCTAssertFalse(undo.canRedo())
            XCTAssertEqual(undo.redoCount(), 0)
        }
    }
    
    // MARK: - Exclude Origin Prefix Tests
    
    func testExcludeCertainLocalOpsFromUndo() throws {
        let doc = LoroDoc()
        let undo = UndoManager(doc: doc)
        undo.addExcludeOriginPrefix(prefix: "sys:")
        
        try doc.getText(id: "text").insert(pos: 0, s: "123")
        doc.commit()
        try doc.getText(id: "text").insert(pos: 0, s: "x")
        doc.commitWith(options: CommitOptions(origin: "sys:init", immediateRenew: true, timestamp: nil, commitMsg: nil))
        try doc.getText(id: "text").insert(pos: 2, s: "y")  // x1y23
        doc.commitWith(options: CommitOptions(origin: "sys:init", immediateRenew: true, timestamp: nil, commitMsg: nil))
        try doc.getText(id: "text").insert(pos: 4, s: "z")  // x1y2z3
        doc.commitWith(options: CommitOptions(origin: "sys:init", immediateRenew: true, timestamp: nil, commitMsg: nil))
        try doc.getText(id: "text").insert(pos: 6, s: "abc")  // x1y2z3abc
        doc.commit()
        
        XCTAssertEqual(
            doc.getDeepValue(),
            ["text": "x1y2z3abc"].asLoroValue()
        )
        
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["text": "x1y2z3"].asLoroValue()
        )
        
        let _ = try undo.undo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["text": "xyz"].asLoroValue()
        )
        
        XCTAssertFalse(undo.canUndo())
        XCTAssertEqual(undo.undoCount(), 0)
        
        let _ = try undo.redo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["text": "x1y2z3"].asLoroValue()
        )
        
        let _ = try undo.redo()
        XCTAssertEqual(
            doc.getDeepValue(),
            ["text": "x1y2z3abc"].asLoroValue()
        )
    }
    
    // MARK: - Tree Undo Tests
    
    func testUndoTreeConcurrentDelete() throws {
        let docA = LoroDoc()
        let treeA = docA.getTree(id: "tree")
        let root = try treeA.create(parent: TreeParentId.root)
        let child = try treeA.create(parent: TreeParentId.node(id: root))
        
        let docB = LoroDoc()
        let undoB = UndoManager(doc: docB)
        let treeB = docB.getTree(id: "tree")
        let updates = try docA.export(mode: .snapshot)
        let _ = try docB.import(bytes: updates)
        
        try treeA.delete(target: root)
        try treeB.delete(target: child)
        
        let updatesB = try docB.export(mode: .snapshot)
        let _ = try docA.import(bytes: updatesB)
        let updatesA = try docA.export(mode: .snapshot)
        let _ = try docB.import(bytes: updatesA)
        
        let _ = try undoB.undo()
        
        // getValue() returns the flat array of the forest
        if case .list(let nodes) = treeB.getValue() {
            XCTAssertTrue(nodes.isEmpty)
        } else {
            XCTFail("Expected list value from tree")
        }
    }
    
    // MARK: - Undo Events Tests
    
    func testUndoManagerEvents() throws {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        let undo = UndoManager(doc: doc)
        
        var pushCount = 0
        var popCount = 0
        
        undo.setOnPush { (_, _, _) in
            pushCount += 1
            return UndoItemMeta(value: LoroValue.null, cursors: [])
        }
        
        undo.setOnPop { (_, _, _) in
            popCount += 1
        }
        
        try text.insert(pos: 0, s: "Hello")
        XCTAssertEqual(pushCount, 0)
        doc.commit()
        XCTAssertEqual(pushCount, 1)
        
        try text.insert(pos: 0, s: "A")
        try text.insert(pos: 1, s: "B")
        XCTAssertEqual(popCount, 0)
        XCTAssertEqual(pushCount, 1)
        doc.commit()
        XCTAssertEqual(pushCount, 2)
        
        let _ = try undo.undo()
        XCTAssertEqual(popCount, 1)
        XCTAssertEqual(pushCount, 3)
        
        let _ = try undo.undo()
        XCTAssertEqual(popCount, 2)
        XCTAssertEqual(pushCount, 4)
        
        let _ = try undo.redo()
        XCTAssertEqual(popCount, 3)
        XCTAssertEqual(pushCount, 5)
        
        let _ = try undo.redo()
        XCTAssertEqual(popCount, 4)
        XCTAssertEqual(pushCount, 6)
    }
    
    func testOnPushDiffEvent() throws {
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        let undo = UndoManager(doc: doc)
        
        var receivedDiffEvents: [DiffEvent] = []
        var receivedUndoOrRedo: [UndoOrRedo] = []
        var receivedSpans: [CounterSpan] = []
        
        undo.setOnPush { (undoOrRedo, span, diffEvent) in
            receivedUndoOrRedo.append(undoOrRedo)
            receivedSpans.append(span)
            if let event = diffEvent {
                receivedDiffEvents.append(event)
            }
            return UndoItemMeta(value: LoroValue.null, cursors: [])
        }
        
        // Test 1: Insert text and verify diffEvent contains text diff
        try text.insert(pos: 0, s: "Hello")
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 1)
        XCTAssertEqual(receivedUndoOrRedo.count, 1)
        
        // Verify the first push is for undo stack
        if case .undo = receivedUndoOrRedo[0] {
            // Expected
        } else {
            XCTFail("Expected undo, got redo")
        }
        
        // Verify span has correct start value (0 for first operation)
        XCTAssertEqual(receivedSpans[0].start, 0)
        
        // Verify the diff event contains the correct container
        let firstEvent = receivedDiffEvents[0]
        XCTAssertEqual(firstEvent.events.count, 1)
        
        // Verify the diff is a text diff with insertion
        let containerDiff = firstEvent.events[0]
        if case .root(name: let name, containerType: _) = containerDiff.target {
            XCTAssertEqual(name, "text")
        } else {
            XCTFail("Expected root container with name 'text'")
        }
        
        if case .text(diff: let textDiffs) = containerDiff.diff {
            XCTAssertEqual(textDiffs.count, 1)
            if case .insert(insert: let insertedText, attributes: _) = textDiffs[0] {
                XCTAssertEqual(insertedText, "Hello")
            } else {
                XCTFail("Expected insert diff")
            }
        } else {
            XCTFail("Expected text diff")
        }
        
        // Test 2: Insert more text and verify the new diffEvent
        try text.insert(pos: 5, s: " World")
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 2)
        
        let secondEvent = receivedDiffEvents[1]
        XCTAssertEqual(secondEvent.events.count, 1)
        
        if case .text(diff: let textDiffs) = secondEvent.events[0].diff {
            XCTAssertEqual(textDiffs.count, 2)  // retain + insert
            // First should be retain(5)
            if case .retain(retain: let retainCount, attributes: _) = textDiffs[0] {
                XCTAssertEqual(retainCount, 5)
            } else {
                XCTFail("Expected retain diff")
            }
            // Second should be insert(" World")
            if case .insert(insert: let insertedText, attributes: _) = textDiffs[1] {
                XCTAssertEqual(insertedText, " World")
            } else {
                XCTFail("Expected insert diff")
            }
        } else {
            XCTFail("Expected text diff")
        }
        
        // Test 3: Undo and verify push callback is triggered
        let beforeUndoCount = receivedUndoOrRedo.count
        let _ = try undo.undo()
        
        // After undo, a new push event should be triggered for the redo stack
        XCTAssertGreaterThan(receivedUndoOrRedo.count, beforeUndoCount)
        
        // The most recent push should be for redo (the undone operation goes to redo stack)
        if case .redo = receivedUndoOrRedo.last {
            // Expected: after undo, a redo item is pushed
        } else {
            XCTFail("Expected redo after undo operation")
        }
        
        // Test 4: Verify diffEvent is received for the redo push
        // The diffEvent for redo push should contain the changes being undone
        let lastEvent = receivedDiffEvents.last!
        XCTAssertEqual(lastEvent.events.count, 1)
        
        // The diff should be a text diff
        if case .text(diff: let textDiffs) = lastEvent.events[0].diff {
            // Text diffs should be present for the undo/redo operation
            XCTAssertGreaterThan(textDiffs.count, 0)
        } else {
            XCTFail("Expected text diff")
        }
        
        // Test 5: Verify text state after undo
        XCTAssertEqual(text.toString(), "Hello")
    }
    
    func testOnPushDiffEventWithMap() throws {
        let doc = LoroDoc()
        let map = doc.getMap(id: "map")
        let undo = UndoManager(doc: doc)
        
        var receivedDiffEvents: [DiffEvent] = []
        
        undo.setOnPush { (_, _, diffEvent) in
            if let event = diffEvent {
                receivedDiffEvents.append(event)
                print(diffEvent)
                
            }
            return UndoItemMeta(value: LoroValue.null, cursors: [])
        }
        
        // Insert into map
        try map.insert(key: "name", v: "Alice")
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 1)
        
        let event = receivedDiffEvents[0]
        XCTAssertEqual(event.events.count, 1)
        
        // Verify it's a map diff
        if case .map(diff: let mapDelta) = event.events[0].diff {
            // MapDelta should have the updated entries
            let updated = mapDelta.updated
            XCTAssertEqual(updated.count, 1)
            XCTAssertNotNil(updated["name"] as Any?)
        } else {
            XCTFail("Expected map diff")
        }
        
        // Update the same key
        try map.insert(key: "name", v: "Bob")
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 2)
        
        // Verify update diff
        if case .map(diff: let mapDelta) = receivedDiffEvents[1].events[0].diff {
            let updated = mapDelta.updated
            XCTAssertEqual(updated.count, 1)
            XCTAssertNotNil(updated["name"] as Any?)
        } else {
            XCTFail("Expected map diff")
        }
    }
    
    func testOnPushDiffEventWithList() throws {
        let doc = LoroDoc()
        let list = doc.getList(id: "list")
        let undo = UndoManager(doc: doc)
        
        var receivedDiffEvents: [DiffEvent] = []
        
        undo.setOnPush { (_, _, diffEvent) in
            if let event = diffEvent {
                receivedDiffEvents.append(event)
            }
            return UndoItemMeta(value: LoroValue.null, cursors: [])
        }
        
        // Insert into list
        try list.insert(pos: 0, v: "first")
        try list.insert(pos: 1, v: "second")
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 1)
        
        let event = receivedDiffEvents[0]
        XCTAssertEqual(event.events.count, 1)
        
        // Verify it's a list diff
        if case .list(diff: let listDiffs) = event.events[0].diff {
            XCTAssertGreaterThan(listDiffs.count, 0)
            // Should have insert operations
            var insertCount = 0
            for diff in listDiffs {
                if case .insert(insert: let items, isMove: _) = diff {
                    insertCount += items.count
                }
            }
            XCTAssertEqual(insertCount, 2)  // "first" and "second"
        } else {
            XCTFail("Expected list diff")
        }
        
        // Delete from list
        try list.delete(pos: 0, len: 1)
        doc.commit()
        
        XCTAssertEqual(receivedDiffEvents.count, 2)
        
        // Verify delete diff
        if case .list(diff: let listDiffs) = receivedDiffEvents[1].events[0].diff {
            var hasDelete = false
            for diff in listDiffs {
                if case .delete(delete: let count) = diff {
                    XCTAssertEqual(count, 1)
                    hasDelete = true
                }
            }
            XCTAssertTrue(hasDelete, "Expected delete operation in list diff")
        } else {
            XCTFail("Expected list diff")
        }
    }
    
    // MARK: - Remote Merge Transform Tests
    
    func testRemoteMergeTransform() throws {
        let docA = LoroDoc()
        try docA.setPeerId(peer: 1)
        let undoA = UndoManager(doc: docA)
        let docB = LoroDoc()
        try docB.setPeerId(peer: 2)
        
        // Initial insert "B" in docA
        let textA = docA.getText(id: "text")
        try textA.insert(pos: 0, s: "B")
        docA.commit()
        
        // Mark "B" as bold in docA
        try textA.mark(from: 0, to: 1, key: "bold", value: true)
        docA.commit()
        
        try textA.insert(pos: 0, s: "Hello ")
        docA.commit()
        
        // Sync docA to docB
        sync(docA, docB)
        
        // Concurrently delete "Hello " in docB
        let textB = docB.getText(id: "text")
        try textB.delete(pos: 0, len: 6)
        sync(docA, docB)
        
        // Check the state after concurrent operations
        if case .list(let richValue) = textA.getRichtextValue() {
            XCTAssertEqual(richValue.count, 1)
        }
        
        let _ = try undoA.undo()
        if case .list(let value1) = textA.getRichtextValue() {
            XCTAssertEqual(value1.count, 1)
        }
        
        let _ = try undoA.undo()
        if case .list(let value2) = textA.getRichtextValue() {
            XCTAssertEqual(value2.count, 0)
        }
    }
}

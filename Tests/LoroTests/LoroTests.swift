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
}

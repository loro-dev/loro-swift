import XCTest
@testable import Loro

final class LoroTests: XCTestCase {
    func testEvent(){
        let doc = LoroDoc()
        var num = 0
        let id = doc.subscribeRoot{ diffEvent in
            num += 1
        }
        let list = doc.getList(id: "list")
        try! list.insert(pos: 0, v: 123)
        doc.commit()
        XCTAssertEqual(num, 1)
        doc.unsubscribe(subId: id)
    }
    
    func testText(){
        let doc = LoroDoc()
        let text = doc.getText(id: "text")
        try! text.insert(pos: 0, s: "abc")
        try! text.delete(pos: 0, len: 1)
        let s = text.toString()
        XCTAssertEqual(s, "bc")
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
        try! doc2.import(bytes: doc.exportSnapshot())
        try! doc2.importBatch(bytes: [doc.exportSnapshot(), doc.exportFrom(vv: VersionVector())])
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
        let _ = try! undoManager.undo(doc:doc)
        XCTAssertEqual(text.toString(), "abc")
        XCTAssertEqual(n, 1)
    }
}

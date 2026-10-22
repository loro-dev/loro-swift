import Foundation
import XCTest
@testable import Loro

final class PendingUpdatesTests: XCTestCase {
    func testPendingUpdatesSurviveSnapshotCheckpoint() throws {
        let source = LoroDoc()
        try source.getText(id: "text").pushStr(s: "base")
        let base = try source.exportSnapshot()
        let beforeA = source.oplogVv()
        try source.getText(id: "text").pushStr(s: "A")
        let updateA = try source.exportUpdates(vv: beforeA)
        let afterA = source.oplogVv()
        try source.getText(id: "text").pushStr(s: "B")
        let updateB = try source.exportUpdates(vv: afterA)

        let receiver = LoroDoc()
        _ = try receiver.`import`(bytes: base)
        _ = try receiver.`import`(bytes: updateB)
        XCTAssertEqual(receiver.getText(id: "text").description, "base")
        let snapshot = try receiver.exportSnapshot()
        let optionalPending: Data? = try receiver.exportPendingUpdates()
        let pending = try XCTUnwrap(optionalPending)
        XCTAssertEqual(try receiver.exportPendingUpdates(), pending)

        let restored = LoroDoc()
        _ = try restored.`import`(bytes: snapshot)
        _ = try restored.`import`(bytes: pending)
        XCTAssertEqual(restored.getText(id: "text").description, "base")
        _ = try restored.`import`(bytes: updateA)
        XCTAssertEqual(restored.getText(id: "text").description, "baseAB")
        XCTAssertNil(try restored.exportPendingUpdates())
    }
}

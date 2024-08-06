import XCTest
@testable import Loro

final class LoroTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        let doc = LoroDoc()
        try! doc.setPeerId(peer: 12)
        assert(doc.peerId()==12)
    }
}

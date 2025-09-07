import XCTest
@testable import Loro

final class EphemeralStoreTests: XCTestCase {
    
    func testBasicSetAndGet() {
        let store = EphemeralStore(timeout: 60000)
        
        // Test basic set and get
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: 42)
        store.set(key: "key3", value: true)
        
        XCTAssertEqual(store.get(key: "key1"), LoroValue.string(value: "value1"))
        XCTAssertEqual(store.get(key: "key2"), LoroValue.i64(value: Int64(42)))
        XCTAssertEqual(store.get(key: "key3"), LoroValue.bool(value: true))
        XCTAssertNil(store.get(key: "nonexistent"))
    }
    
    func testKeys() {
        let store = EphemeralStore(timeout: 60000)
        
        // Initial state should have no keys
        XCTAssertEqual(store.keys().count, 0)
        
        // Add some keys
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: "value2")
        store.set(key: "key3", value: "value3")
        
        let keys = store.keys()
        XCTAssertEqual(keys.count, 3)
        XCTAssertTrue(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
        XCTAssertTrue(keys.contains("key3"))
    }
    
    func testGetAllStates() {
        let store = EphemeralStore(timeout: 60000)
        
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: 42)
        
        let allStates = store.getAllStates()
        XCTAssertEqual(allStates.count, 2)
        XCTAssertEqual(allStates["key1"], LoroValue.string(value: "value1"))
        XCTAssertEqual(allStates["key2"], LoroValue.i64(value: Int64(42)))
    }
    
    func testDelete() {
        let store = EphemeralStore(timeout: 60000)
        
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: "value2")
        
        XCTAssertNotNil(store.get(key: "key1"))
        
        store.delete(key: "key1")
        
        XCTAssertNil(store.get(key: "key1"))
        XCTAssertNotNil(store.get(key: "key2"))
        
        let keys = store.keys()
        XCTAssertEqual(keys.count, 1)
        XCTAssertFalse(keys.contains("key1"))
        XCTAssertTrue(keys.contains("key2"))
    }
    
    func testEphemeralEventSubscription() {
        let store = EphemeralStore(timeout: 60000)
        
        var receivedEvents: [EphemeralStoreEvent] = []
        
        // Subscribe to events
        let subscription = store.subscribe { event in
            receivedEvents.append(event)
        }
        
        // Adding a key should trigger an event
        store.set(key: "key1", value: "value1")
        
        // Wait a short time for event processing to complete
        let expectation = XCTestExpectation(description: "Event received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertGreaterThan(receivedEvents.count, 0)
        
        let lastEvent = receivedEvents.last!
        XCTAssertEqual(lastEvent.by, .local)
        XCTAssertTrue(lastEvent.added.contains("key1"))
        
        // Clear received events
        receivedEvents.removeAll()
        
        // Updating a key should trigger an event
        store.set(key: "key1", value: "updated_value")
        
        // Wait for event
        let updateExpectation = XCTestExpectation(description: "Update event received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 1.0)
        
        XCTAssertGreaterThan(receivedEvents.count, 0)
        let updateEvent = receivedEvents.last!
        XCTAssertEqual(updateEvent.by, .local)
        XCTAssertTrue(updateEvent.updated.contains("key1"))
        
        // Clear received events
        receivedEvents.removeAll()
        
        // Deleting a key should trigger an event
        store.delete(key: "key1")
        
        // Wait for event
        let deleteExpectation = XCTestExpectation(description: "Delete event received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
        
        XCTAssertGreaterThan(receivedEvents.count, 0)
        let deleteEvent = receivedEvents.last!
        XCTAssertEqual(deleteEvent.by, .local)
        XCTAssertTrue(deleteEvent.removed.contains("key1"))
        
        // Unsubscribe
        subscription.detach()
    }
    
    func testLocalUpdateSubscription() {
        let store = EphemeralStore(timeout: 60000)
        
        var receivedUpdates: [Data] = []
        
        // Subscribe to local updates
        let subscription = store.subscribeLocalUpdate { updateData in
            receivedUpdates.append(updateData)
        }
        
        // Set some data
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: 42)
        
        // Wait for update events
        let expectation = XCTestExpectation(description: "Local update received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Should receive update data
        XCTAssertGreaterThan(receivedUpdates.count, 0)
        
        // Verify data is not empty
        for updateData in receivedUpdates {
            XCTAssertGreaterThan(updateData.count, 0)
        }
        
        // Unsubscribe
        subscription.detach()
    }
    
    func testEncodeAndApply() {
        let store1 = EphemeralStore(timeout: 60000)
        let store2 = EphemeralStore(timeout: 60000)
        
        // Set data in store1
        store1.set(key: "key1", value: "value1")
        store1.set(key: "key2", value: 42)
        
        // Encode all data
        let encodedData = store1.encodeAll()
        
        // Apply data to store2
        try! store2.apply(data: encodedData)
        
        // Verify store2 has the same data
        XCTAssertEqual(store2.get(key: "key1"), LoroValue.string(value: "value1"))
        XCTAssertEqual(store2.get(key: "key2"), LoroValue.i64(value: Int64(42)))
        
        let store2Keys = store2.keys()
        XCTAssertEqual(store2Keys.count, 2)
        XCTAssertTrue(store2Keys.contains("key1"))
        XCTAssertTrue(store2Keys.contains("key2"))
    }
    
    func testEncodeSpecificKey() {
        let store = EphemeralStore(timeout: 60000)
        
        store.set(key: "key1", value: "value1")
        store.set(key: "key2", value: "value2")
        
        // Encode specific key
        let encodedKey1 = store.encode(key: "key1")
        XCTAssertGreaterThan(encodedKey1.count, 0)
        
        // Create new store and apply specific key data
        let newStore = EphemeralStore(timeout: 60000)
        try! newStore.apply(data: encodedKey1)
        
        // Should only have key1, not key2
        XCTAssertNotNil(newStore.get(key: "key1"))
        XCTAssertNil(newStore.get(key: "key2"))
    }
    
    func testMultipleSubscriptions() {
        let store = EphemeralStore(timeout: 60000)
        
        var events1: [EphemeralStoreEvent] = []
        var events2: [EphemeralStoreEvent] = []
        
        // Create two subscriptions
        let subscription1 = store.subscribe { event in
            events1.append(event)
        }
        
        let subscription2 = store.subscribe { event in
            events2.append(event)
        }
        
        // Set data
        store.set(key: "test", value: "value")
        
        // Wait for events
        let expectation = XCTestExpectation(description: "Multiple subscriptions received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Both subscriptions should receive events
        XCTAssertGreaterThan(events1.count, 0)
        XCTAssertGreaterThan(events2.count, 0)
        
        // Unsubscribe
        subscription1.detach()
        subscription2.detach()
    }
}
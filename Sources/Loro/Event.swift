import Foundation

class ClosureSubscriber: Subscriber {
    private let closure: (DiffEvent) -> Void

    public init(closure: @escaping (DiffEvent) -> Void) {
        self.closure = closure
    }

    public func onDiff(diff: DiffEvent) {
        closure(diff)
    }
}

class ClosureLocalUpdate: LocalUpdateCallback{
    private let closure: (Data) -> Void

    public init(closure: @escaping (Data) -> Void) {
        self.closure = closure
    }

    public func onLocalUpdate(update: Data) {
        closure(update)
    }
}

extension LoroDoc{
    /** Subscribe all the events.
     *
     * The callback will be invoked when any part of the [DocState] is changed. 
     * Returns a subscription id that can be used to unsubscribe.
     */
    public func subscribeRoot(callback: @escaping (DiffEvent)->Void) -> Subscription {
        let closureSubscriber = ClosureSubscriber(closure: callback)
        return self.subscribeRoot(subscriber: closureSubscriber)
    }

    /** Subscribe the events of a container.
     *
     * The callback will be invoked when the container is changed.
     * Returns a subscription id that can be used to unsubscribe.
     *
     * The events will be emitted after a transaction is committed. A transaction is committed when:
     * - `doc.commit()` is called.
     * - `doc.exportFrom(version)` is called.
     * - `doc.import(data)` is called.
     * - `doc.checkout(version)` is called.
     */
     public func subscribe(containerId: ContainerId, callback: @escaping (DiffEvent)->Void) -> Subscription {
        let closureSubscriber = ClosureSubscriber(closure: callback)
        return self.subscribe(containerId: containerId, subscriber: closureSubscriber)
    }

    /**
    * Subscribe the local update of the document.
    */
    public func subscribeLocalUpdate(callback: @escaping (Data)->Void)->Subscription{
        let closureLocalUpdate = ClosureLocalUpdate(closure: callback)
        return self.subscribeLocalUpdate(callback: closureLocalUpdate)
    }
}

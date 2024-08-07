

class ClosureSubscriber: Subscriber {
    private let closure: (DiffEvent) -> Void

    public init(closure: @escaping (DiffEvent) -> Void) {
        self.closure = closure
    }

    public func onDiff(diff: DiffEvent) {
        closure(diff)
    }
}

extension LoroDoc{
    /** Subscribe all the events.
     *
     * The callback will be invoked when any part of the [loro_internal::DocState] is changed. 
     * Returns a subscription id that can be used to unsubscribe.
     */
    public func subscribeRoot(callback: @escaping (DiffEvent)->Void) -> SubId {
        let closureSubscriber = ClosureSubscriber(closure: callback)
        return self.subscribeRoot(subscriber: closureSubscriber)
    }

    /** Subscribe the events of a container.
     *
     * The callback will be invoked when the container is changed.
     * Returns a subscription id that can be used to unsubscribe.
     */
     public func subscribe(containerId: ContainerId, callback: @escaping (DiffEvent)->Void) -> SubId {
        let closureSubscriber = ClosureSubscriber(closure: callback)
        return self.subscribe(containerId: containerId, subscriber: closureSubscriber)
    }
}

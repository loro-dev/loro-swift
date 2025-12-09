//
//  Ephemeral.swift
//
//
//  Created by Leon Zhao on 2025/6/4.
//

#if !hasFeature(Embedded)
#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
#endif

class ClosureEphemeralSubscriber: EphemeralSubscriber {
    private let closure: (EphemeralStoreEvent) -> Void

    public init(closure: @escaping (EphemeralStoreEvent) -> Void) {
        self.closure = closure
    }

    public func onEphemeralEvent(event: EphemeralStoreEvent) {
        closure(event)
    }
}

class ClosureLocalEphemeralListener:LocalEphemeralListener{

    private let closure: (Data) -> Void

    public init(closure: @escaping (Data) -> Void) {
        self.closure = closure
    }

    public func onEphemeralUpdate(update: Data) {
        closure(update)
    }
}

extension EphemeralStore{
    public func subscribe(cb: @escaping (EphemeralStoreEvent) -> Void) -> Subscription{
        let closureSubscriber = ClosureEphemeralSubscriber(closure: cb)
        return self.subscribe(listener: closureSubscriber)
    }

    public func subscribeLocalUpdate(cb: @escaping (Data) -> Void) -> Subscription{
        let closureListener = ClosureLocalEphemeralListener(closure: cb)
        return self.subscribeLocalUpdate(listener: closureListener)
    }
}

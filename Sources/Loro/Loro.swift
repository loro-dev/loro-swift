//
//  Loro.swift
//
//
//  Created by Leon Zhao on 2024/8/6.
//



import Foundation


class ClosureOnPush: OnPush {
    private let closure: (UndoOrRedo, CounterSpan) ->UndoItemMeta

    public init(closure: @escaping (UndoOrRedo, CounterSpan) ->UndoItemMeta) {
        self.closure = closure
    }

    public func onPush(undoOrRedo: UndoOrRedo, span: CounterSpan) -> UndoItemMeta{
        closure(undoOrRedo, span)
    }
}

class ClosureOnPop: OnPop {
    private let closure: (UndoOrRedo, CounterSpan,UndoItemMeta)->Void

    public init(closure: @escaping (UndoOrRedo, CounterSpan,UndoItemMeta)->Void) {
        self.closure = closure
    }

    public func onPop(undoOrRedo: UndoOrRedo, span: CounterSpan, undoMeta: UndoItemMeta) {
        closure(undoOrRedo, span, undoMeta)
    }
}

extension UndoManager{
    public func setOnPush(callback: ((UndoOrRedo, CounterSpan) ->UndoItemMeta)?){
        if let onPush = callback{
            let closureOnPush = ClosureOnPush(closure: onPush)
            self.setOnPush(onPush: closureOnPush)
        }else{
            self.setOnPush(onPush: nil)
        }
    }
    
    public func setOnPop(callback: ( (UndoOrRedo, CounterSpan,UndoItemMeta)->Void)?){
        if let onPop = callback{
            let closureOnPop = ClosureOnPop(closure: onPop)
            self.setOnPop(onPop: closureOnPop)
        }else{
            self.setOnPop(onPop: nil)
        }
    }
}


class ChangeAncestorsTravel: ChangeAncestorsTraveler{ 
    private let closure: (ChangeMeta)->Bool

    public init(closure: @escaping (ChangeMeta)->Bool) {
        self.closure = closure
    }

    func travel(change: ChangeMeta) -> Bool {
        closure(change)
    }
}

extension LoroDoc{
    public func travelChangeAncestors(ids: [Id], f:  @escaping (ChangeMeta)->Bool) throws  {
        let closureSubscriber = ChangeAncestorsTravel(closure: f)
        try self.travelChangeAncestors(ids: ids, f: closureSubscriber)
    }
}
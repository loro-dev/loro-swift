//
//  Container.swift
//  
//
//  Created by Leon Zhao on 2024/8/6.
//


extension String: ContainerIdLike{
    public func asContainerId(ty: ContainerType)  -> ContainerId{
        return ContainerId.root(name: self, containerType: ty)
    }
}

extension ContainerId: ContainerIdLike{
    public func asContainerId(ty: ContainerType)  -> ContainerId{
        return self
    }
}

public protocol ContainerLike: LoroValueLike{
    func id()->ContainerId;
}

extension ContainerLike{
    public func asLoroValue()->LoroValue{
        return LoroValue.container(value: self.id())
    }
}

extension LoroText: ContainerLike{}
extension LoroMap: ContainerLike{
    public func insertContainer<T: ContainerLike>(key: String, child: T) throws -> T {
        let result: ContainerLike
        if let list = child as? LoroList{
           result = try self.insertListContainer(key: key, child: list)
        }else if let map = child as? LoroMap{
            result = try self.insertMapContainer(key: key, child: map)
        }else if let text = child as? LoroText{
            result = try self.insertTextContainer(key: key, child: text)
            }else if let tree = child as? LoroTree{
            result = try self.insertTreeContainer(key: key, child: tree)
        }else if let list = child as? LoroMovableList{
            result = try self.insertMovableListContainer(key: key, child: list)
        }else if let counter = child as? LoroCounter{
            result = try self.insertCounterContainer(key: key, child: counter)
        }else{
            fatalError()
        }
        guard let typedResult = result as? T else {
            fatalError("Type mismatch: expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }

    public func getOrCreateContainer<T: ContainerLike>(key: String, child: T) throws -> T {
        let result: ContainerLike
        if let list = child as? LoroList{
           result = try self.getOrCreateListContainer(key: key, child: list)
        }else if let map = child as? LoroMap{
            result = try self.getOrCreateMapContainer(key: key, child: map)
        }else if let text = child as? LoroText{
            result = try self.getOrCreateTextContainer(key: key, child: text)
        }else if let tree = child as? LoroTree{
            result = try self.getOrCreateTreeContainer(key: key, child: tree)
        }else if let list = child as? LoroMovableList{
            result = try self.getOrCreateMovableListContainer(key: key, child: list)
        }else if let counter = child as? LoroCounter{
            result = try self.getOrCreateCounterContainer(key: key, child: counter)
        }else{
            fatalError()
        }
        guard let typedResult = result as? T else {
            fatalError("Type mismatch: expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }
}
extension LoroTree: ContainerLike{}
extension LoroMovableList: ContainerLike{
    public func pushContainer<T: ContainerLike>(child: T) throws -> T{
        let idx = self.len()
        return try self.insertContainer(pos: idx, child: child)
    }
    
    public func insertContainer<T: ContainerLike>(pos: UInt32, child: T) throws -> T {
        let result: ContainerLike
        if let list = child as? LoroList{
           result = try self.insertListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            result = try self.insertMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            result = try self.insertTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            result = try self.insertTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            result = try self.insertMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            result = try self.insertCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
        guard let typedResult = result as? T else {
            fatalError("Type mismatch: expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }

    public func setContainer<T: ContainerLike>(pos: UInt32, child: T) throws -> T{
        let result: ContainerLike
        if let list = child as? LoroList{
           result = try self.setListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            result = try self.setMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            result = try self.setTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            result = try self.setTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            result = try self.setMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            result = try self.setCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
        guard let typedResult = result as? T else {
            fatalError("Type mismatch: expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }
}


extension LoroList: ContainerLike{
    public func pushContainer<T: ContainerLike>(child: T) throws -> T{
        let idx = self.len()
        return try self.insertContainer(pos: idx, child: child)
    }
    
    public func insertContainer<T: ContainerLike>(pos: UInt32, child: T) throws -> T {
        let result: ContainerLike
        if let list = child as? LoroList{
           result = try self.insertListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            result = try self.insertMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            result = try self.insertTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            result = try self.insertTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            result = try self.insertMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            result = try self.insertCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
        guard let typedResult = result as? T else {
            fatalError("Type mismatch: expected \(T.self), got \(type(of: result))")
        }
        return typedResult
    }
}

extension LoroCounter: ContainerLike{}
extension LoroUnknown: ContainerLike{}

// Extension for handling nil input
// Although we extend Optional, we still need to specify the type explicitly
// e.g. `nil as String?`. This is not convenient in some scenarios.
extension LoroList{
    public func insert(pos: UInt32, v: LoroValueLike?) throws {
        try self.insert(pos: pos, v: v?.asLoroValue() ?? .null)
    }

    public func push(v: LoroValueLike?) throws {
        try self.push(v: v?.asLoroValue() ?? .null)
    }
}

extension LoroMap{
    public func insert(key: String, v: LoroValueLike?) throws {
        try self.insert(key: key, v: v?.asLoroValue() ?? .null)
    }
}

extension LoroMovableList{
    public func insert(pos: UInt32, v: LoroValueLike?) throws {
        try self.insert(pos: pos, v: v?.asLoroValue() ?? .null)
    }

    public func push(v: LoroValueLike?) throws {
        try self.push(v: v?.asLoroValue() ?? .null)
    }

    public func set(pos: UInt32, v: LoroValueLike?) throws {
        try self.set(pos: pos, value: v?.asLoroValue() ?? .null)
    }
}

extension LoroText{
    public func mark(from: UInt32, to: UInt32, key: String, value: LoroValueLike?) throws {
        try self.mark(from: from, to: to, key: key, value: value?.asLoroValue() ?? .null)
    }
}

extension Awareness{
    public func setLocalState(value: LoroValueLike?){
        self.setLocalState(value: value?.asLoroValue() ?? .null)
    }
}

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
    public func insertContainer(key: String, child: ContainerLike) throws -> ContainerLike {
        if let list = child as? LoroList{
           return try self.insertListContainer(key: key, child: list)
        }else if let map = child as? LoroMap{
            return try self.insertMapContainer(key: key, child: map)
        }else if let text = child as? LoroText{
            return try self.insertTextContainer(key: key, child: text)
            }else if let tree = child as? LoroTree{
            return try self.insertTreeContainer(key: key, child: tree)
        }else if let list = child as? LoroMovableList{
            return try self.insertMovableListContainer(key: key, child: list)
        }else if let counter = child as? LoroCounter{
            return try self.insertCounterContainer(key: key, child: counter)
        }else{
            fatalError()
        }
    }
}
extension LoroTree: ContainerLike{}
extension LoroMovableList: ContainerLike{
    public func pushContainer(child: ContainerLike) throws -> ContainerLike{
        let idx = self.len()
        return try self.insertContainer(pos: idx, child: child)
    }
    
    public func insertContainer(pos: UInt32, child: ContainerLike) throws -> ContainerLike {
        if let list = child as? LoroList{
           return try self.insertListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            return try self.insertMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            return try self.insertTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            return try self.insertTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            return try self.insertMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            return try self.insertCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
    }

    public func setContainer(pos: UInt32, child: ContainerLike) throws -> ContainerLike{
        if let list = child as? LoroList{
           return try self.setListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            return try self.setMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            return try self.setTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            return try self.setTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            return try self.setMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            return try self.setCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
    }
}
extension LoroCounter: ContainerLike{}
extension LoroUnknown: ContainerLike{}




extension LoroList: ContainerLike{
    public func pushContainer(child: ContainerLike) throws -> ContainerLike{
        let idx = self.len()
        return try self.insertContainer(pos: idx, child: child)
    }
    
    public func insertContainer(pos: UInt32, child: ContainerLike) throws -> ContainerLike {
        if let list = child as? LoroList{
           return try self.insertListContainer(pos: pos, child: list)
        }else if let map = child as? LoroMap{
            return try self.insertMapContainer(pos: pos, child: map)
        }else if let text = child as? LoroText{
            return try self.insertTextContainer(pos: pos, child: text)
            }else if let tree = child as? LoroTree{
            return try self.insertTreeContainer(pos: pos, child: tree)
        }else if let list = child as? LoroMovableList{
            return try self.insertMovableListContainer(pos: pos, child: list)
        }else if let counter = child as? LoroCounter{
            return try self.insertCounterContainer(pos: pos, child: counter)
        }else{
            fatalError()
        }
    }
}




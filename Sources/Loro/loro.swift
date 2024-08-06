import Foundation

public protocol ContainerLike{}



extension LoroList: ContainerLike{
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

extension LoroMap: ContainerLike{}
extension LoroText: ContainerLike{}
extension LoroTree: ContainerLike{}
extension LoroMovableList: ContainerLike{}
extension LoroCounter: ContainerLike{}

extension VersionVector: Equatable{
   static public func == (lhs: VersionVector, rhs: VersionVector) -> Bool {
        return lhs.eq(other: rhs)
    }
}

extension Frontiers: Equatable{
   static public func == (lhs: Frontiers, rhs: Frontiers) -> Bool {
        return lhs.eq(other: rhs)
    }
}
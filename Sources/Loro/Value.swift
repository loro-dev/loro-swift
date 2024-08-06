
extension LoroValue: LoroValueLike {
    public func asLoroValue() -> LoroValue {
        return self
    }
}

extension String:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.string(value: self)
    }
}


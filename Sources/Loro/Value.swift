//
//  Value.swift
//
//
//  Created by Leon Zhao on 2024/8/6.
//

extension LoroValue: LoroValueLike {
    public func asLoroValue() -> LoroValue {
        return self
    }
}

extension Bool: LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.bool(value: self)
    }
}

extension Float:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.double(value: Float64(self))
    }
}

extension Double:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.double(value: self)
    }
}

extension UInt8:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}


extension UInt16:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension UInt32:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension UInt64:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension UInt:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension Int:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension Int8:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension Int16:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension Int32:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension Int64:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.i64(value: Int64(self))
    }
}

extension String:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.string(value: self)
    }
}

extension Array: LoroValueLike where Element:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        if let uint8Array = self as? [UInt8] {
            return LoroValue.binary(value: uint8Array)
        } else {
            let loroValues = self.map { $0.asLoroValue() }
            return LoroValue.list(value: loroValues)
        }
    }
}

extension Dictionary: LoroValueLike where Key == String, Value:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        let mapValues = self.mapValues{ $0.asLoroValue() }
        return LoroValue.map(value: mapValues)
    }
}

extension ContainerId:LoroValueLike{
    public func asLoroValue() -> LoroValue {
        return LoroValue.container(value: self)
    }
}

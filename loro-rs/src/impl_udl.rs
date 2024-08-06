use loro_ffi::SubID;
// use loro_ffi::{Counter, Lamport, PeerID};

use crate::UniffiCustomTypeConverter;

// impl UniffiCustomTypeConverter for PeerID {
//     type Builtin = u64;

//     fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
//     where
//         Self: Sized,
//     {
//         Ok(PeerID(val))
//     }

//     fn from_custom(obj: Self) -> Self::Builtin {
//         obj.0
//     }
// }

// impl UniffiCustomTypeConverter for Lamport {
//     type Builtin = u32;

//     fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
//     where
//         Self: Sized,
//     {
//         Ok(Lamport(val))
//     }

//     fn from_custom(obj: Self) -> Self::Builtin {
//         obj.0
//     }
// }

// impl UniffiCustomTypeConverter for Counter {
//     type Builtin = i32;

//     fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
//     where
//         Self: Sized,
//     {
//         Ok(Counter(val))
//     }

//     fn from_custom(obj: Self) -> Self::Builtin {
//         obj.0
//     }
// }

impl UniffiCustomTypeConverter for SubID {
    type Builtin = u32;

    fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
    where
        Self: Sized,
    {
        Ok(SubID::from_u32(val))
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        SubID::into_u32(obj)
    }
}

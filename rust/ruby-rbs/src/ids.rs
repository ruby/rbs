//! Content-addressed, type-tagged 64-bit IDs.
//!
//! Different ID domains (interned strings, type names, ...) share the same
//! underlying `NonZeroU64` representation but are distinguished at the
//! type level via a phantom tag, so a `SymbolId` cannot be silently used
//! where a `TypeName` is expected.
//!
//! The value of an ID is the 64-bit xxh3 hash of its content (with `0`
//! folded to `1` to keep the niche optimization on `Option<Id<T>>`).
//! Because IDs are derived from content, two independently-built
//! interners that see the same value assign the same ID — merging is
//! just a `HashMap` union, no remap walk needed.
//!
//! ```
//! use ruby_rbs::ids::{Id, SymbolId};
//! enum OtherTag {}
//! type OtherId = Id<OtherTag>;
//!
//! fn takes_symbol(_: SymbolId) {}
//! // takes_symbol(OtherId::from_hash(0)); // compile error
//! ```

use std::cmp::Ordering;
use std::hash::{Hash, Hasher};
use std::marker::PhantomData;
use std::num::NonZeroU64;

/// A 64-bit content-addressed ID tagged with a domain marker `T`.
///
/// The tag is a zero-sized type parameter — typically an uninhabited enum —
/// used only to distinguish ID domains at the type level.
pub struct Id<T> {
    raw: NonZeroU64,
    _tag: PhantomData<fn() -> T>,
}

impl<T> Id<T> {
    /// Wrap a 64-bit hash as an `Id`. A hash of `0` is folded to `1`
    /// so the representation stays non-zero (enabling niche optimization
    /// in `Option<Id<T>>`). Collisions on the folded value are vanishingly
    /// rare in 2^64 space.
    #[must_use]
    pub fn from_hash(h: u64) -> Self {
        let raw = NonZeroU64::new(h).unwrap_or(NonZeroU64::new(1).unwrap());
        Self {
            raw,
            _tag: PhantomData,
        }
    }

    /// Wrap a pre-validated non-zero value.
    #[must_use]
    pub fn from_raw(raw: NonZeroU64) -> Self {
        Self {
            raw,
            _tag: PhantomData,
        }
    }

    /// The underlying non-zero 64-bit value.
    #[must_use]
    pub fn raw(self) -> NonZeroU64 {
        self.raw
    }

    /// The underlying 64-bit value as a plain integer.
    #[must_use]
    pub fn get(self) -> u64 {
        self.raw.get()
    }
}

// Manual trait impls — `#[derive(...)]` on a struct with `PhantomData<T>`
// would add unnecessary bounds on `T`, but `Id<T>` is always copyable,
// hashable, etc. regardless of the tag.

impl<T> Copy for Id<T> {}

impl<T> Clone for Id<T> {
    fn clone(&self) -> Self {
        *self
    }
}

impl<T> PartialEq for Id<T> {
    fn eq(&self, other: &Self) -> bool {
        self.raw == other.raw
    }
}

impl<T> Eq for Id<T> {}

impl<T> PartialOrd for Id<T> {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl<T> Ord for Id<T> {
    fn cmp(&self, other: &Self) -> Ordering {
        self.raw.cmp(&other.raw)
    }
}

impl<T> Hash for Id<T> {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.raw.hash(state);
    }
}

impl<T> std::fmt::Debug for Id<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let tag = std::any::type_name::<T>()
            .rsplit("::")
            .next()
            .unwrap_or("Id");
        write!(f, "{}({:#018x})", tag, self.raw.get())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    enum FooTag {}
    enum BarTag {}
    type FooId = Id<FooTag>;
    type BarId = Id<BarTag>;

    #[test]
    fn from_hash_preserves_nonzero_value() {
        let id = FooId::from_hash(42);
        assert_eq!(id.get(), 42);
    }

    #[test]
    fn from_hash_folds_zero_to_one() {
        let id = FooId::from_hash(0);
        assert_eq!(id.get(), 1);
    }

    #[test]
    fn option_is_niche_optimized() {
        assert_eq!(
            std::mem::size_of::<Option<FooId>>(),
            std::mem::size_of::<FooId>(),
        );
        assert_eq!(std::mem::size_of::<FooId>(), 8);
    }

    #[test]
    fn equality_and_ordering() {
        let a = FooId::from_hash(10);
        let b = FooId::from_hash(10);
        let c = FooId::from_hash(20);
        assert_eq!(a, b);
        assert_ne!(a, c);
        assert!(a < c);
    }

    #[test]
    fn different_tags_are_distinct_types() {
        let _foo = FooId::from_hash(1);
        let _bar = BarId::from_hash(1);
        // The following would not compile:
        //     let _: FooId = _bar;
    }

    #[test]
    fn debug_shows_tag_name_and_hex() {
        let foo = FooId::from_hash(0xDEAD_BEEF);
        assert_eq!(format!("{foo:?}"), "FooTag(0x00000000deadbeef)");
    }
}

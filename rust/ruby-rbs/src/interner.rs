//! Content-addressed string interner producing [`SymbolId`]s.
//!
//! Each [`SymbolId`] is the `xxh3_64` hash of the interned bytes, so the
//! same string always produces the same `SymbolId` — regardless of which
//! [`StringInterner`] (and therefore which thread) it was interned in. To merge
//! per-thread interners into one, just take the union of their backing
//! maps; no `Remap` walk is needed.
//!
//! ```
//! use ruby_rbs::interner::StringInterner;
//!
//! let mut a = StringInterner::new();
//! let mut b = StringInterner::new();
//! let a_string = a.intern("String");
//! let a_int = a.intern("Integer");
//! let b_string = b.intern("String");
//! let b_array = b.intern("Array");
//!
//! // Same content ⇒ same id across independent interners.
//! assert_eq!(a_string, b_string);
//!
//! let mut global = StringInterner::new();
//! global.merge(a);
//! global.merge(b);
//!
//! assert_eq!(global.resolve(a_int), "Integer");
//! assert_eq!(global.resolve(b_array), "Array");
//! ```

use crate::ids::SymbolId;
use std::collections::HashMap;
use xxhash_rust::xxh3::xxh3_64;

/// Interns strings and assigns each the content-addressed [`SymbolId`]
/// `xxh3_64(s.as_bytes())`.
///
/// One `StringInterner` per thread during parallel work, then [`merge`] them all
/// into a single destination `StringInterner` for the final shared view.
///
/// [`merge`]: Self::merge
#[derive(Default)]
pub struct StringInterner {
    map: HashMap<SymbolId, Box<str>>,
}

impl StringInterner {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Returns the content-addressed [`SymbolId`] for `s`, allocating
    /// storage only when `s` is new to this interner.
    pub fn intern(&mut self, s: &str) -> SymbolId {
        let id = SymbolId::from_hash(xxh3_64(s.as_bytes()));
        self.map.entry(id).or_insert_with(|| Box::<str>::from(s));
        id
    }

    /// Returns the string previously interned for `id`.
    ///
    /// # Panics
    /// If `id` was not issued by this interner (or one merged into it).
    #[must_use]
    pub fn resolve(&self, id: SymbolId) -> &str {
        &self.map[&id]
    }

    /// Returns the string for `id`, or `None` if it was never interned here.
    #[must_use]
    pub fn try_resolve(&self, id: SymbolId) -> Option<&str> {
        self.map.get(&id).map(|s| &**s)
    }

    /// Returns the number of interned strings.
    #[must_use]
    pub fn len(&self) -> usize {
        self.map.len()
    }

    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.map.is_empty()
    }

    /// Move every entry from `other` into `self`. Because IDs are
    /// content-addressed, entries already present in `self` are kept; new
    /// ones are absorbed without reallocating their `Box<str>` storage.
    pub fn merge(&mut self, other: StringInterner) {
        for (id, boxed) in other.map {
            self.map.entry(id).or_insert(boxed);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn intern_is_stable_within_one_interner() {
        let mut i = StringInterner::new();
        let a1 = i.intern("String");
        let a2 = i.intern("String");
        let b = i.intern("Integer");
        assert_eq!(a1, a2);
        assert_ne!(a1, b);
        assert_eq!(i.resolve(a1), "String");
        assert_eq!(i.resolve(b), "Integer");
        assert_eq!(i.len(), 2);
    }

    #[test]
    fn same_string_yields_same_id_across_interners() {
        let mut a = StringInterner::new();
        let mut b = StringInterner::new();
        assert_eq!(a.intern("String"), b.intern("String"));
        assert_eq!(a.intern(""), b.intern(""));
    }

    #[test]
    fn merge_unions_entries() {
        let mut local = StringInterner::new();
        let l_string = local.intern("String");
        let l_array = local.intern("Array");

        let mut global = StringInterner::new();
        let g_string = global.intern("String");
        let g_int = global.intern("Integer");

        // Same content ⇒ same id, even before merge.
        assert_eq!(l_string, g_string);

        global.merge(local);

        assert_eq!(global.resolve(l_string), "String");
        assert_eq!(global.resolve(l_array), "Array");
        assert_eq!(global.resolve(g_int), "Integer");
        assert_eq!(global.len(), 3);
    }

    #[test]
    fn merge_into_empty_global() {
        let mut local = StringInterner::new();
        let a = local.intern("Foo");
        let b = local.intern("Bar");

        let mut global = StringInterner::new();
        global.merge(local);

        assert_eq!(global.resolve(a), "Foo");
        assert_eq!(global.resolve(b), "Bar");
        assert_eq!(global.len(), 2);
    }

    #[test]
    fn interner_is_send() {
        fn assert_send<T: Send>() {}
        assert_send::<StringInterner>();
    }

    #[test]
    fn parallel_intern_then_merge() {
        // Each thread interns some strings with overlap. Because IDs are
        // content-addressed, no remap step is needed.
        let inputs: Vec<Vec<&'static str>> = vec![
            vec!["String", "Integer", "Foo"],
            vec!["String", "Array", "Bar"],
            vec!["Integer", "Array", "Baz"],
        ];

        let handles: Vec<_> = inputs
            .into_iter()
            .map(|words| {
                std::thread::spawn(move || {
                    let mut interner = StringInterner::new();
                    let ids: Vec<SymbolId> = words.iter().map(|w| interner.intern(w)).collect();
                    (interner, ids, words)
                })
            })
            .collect();

        let per_thread: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

        let mut global = StringInterner::new();
        let mut translated: Vec<(Vec<SymbolId>, Vec<&'static str>)> = Vec::new();
        for (local, ids, words) in per_thread {
            global.merge(local);
            translated.push((ids, words));
        }

        // Every id resolves to its original string in the global interner.
        for (ids, words) in &translated {
            for (id, word) in ids.iter().zip(words.iter()) {
                assert_eq!(global.resolve(*id), *word);
            }
        }

        // The same string always yields the same SymbolId across threads.
        let mut expected = std::collections::HashMap::<&str, SymbolId>::new();
        for (ids, words) in &translated {
            for (id, word) in ids.iter().zip(words.iter()) {
                if let Some(&prev) = expected.get(*word) {
                    assert_eq!(prev, *id, "{word} got different ids");
                } else {
                    expected.insert(*word, *id);
                }
            }
        }

        // Unique strings across all threads: String, Integer, Foo, Array, Bar, Baz = 6.
        assert_eq!(global.len(), 6);
    }
}

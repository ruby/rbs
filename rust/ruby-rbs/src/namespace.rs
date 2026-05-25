//! A namespace -- a path of segments with an absoluteness flag,
//! corresponding to Ruby `RBS::Namespace`. Internally shares the
//! [`TypeName`] id space but is exposed as a distinct newtype so
//! namespace-flavored APIs stay separated at the type level.
//!
//! ```
//! use ruby_rbs::interner::StringInterner;
//! use ruby_rbs::namespace::Namespace;
//! use ruby_rbs::type_name::TypeNameInterner;
//!
//! let mut strings = StringInterner::new();
//! let mut names = TypeNameInterner::new();
//!
//! let ns = Namespace::parse(&mut names, &mut strings, "::RBS::");
//! assert!(ns.is_absolute(&names));
//! assert_eq!(ns.display(&names, &strings), "::RBS::");
//! ```

use crate::ids::{SymbolId, TypeName};
use crate::interner::StringInterner;
use crate::type_name::TypeNameInterner;

/// A namespace identified by a [`TypeName`] in the shared interner.
///
/// Construct via [`Namespace::empty`], [`Namespace::root`], or
/// [`Namespace::parse`].
#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct Namespace(TypeName);

impl Namespace {
    /// Ruby `RBS::Namespace.empty` -- the empty relative namespace (`""`).
    #[must_use]
    pub fn empty(names: &TypeNameInterner) -> Self {
        Self(names.relative_root())
    }

    /// Ruby `RBS::Namespace.root` -- the empty absolute namespace (`::`).
    #[must_use]
    pub fn root(names: &TypeNameInterner) -> Self {
        Self(names.absolute_root())
    }

    /// Wrap a [`TypeName`] as a `Namespace`. The caller is responsible
    /// for `t` having been interned in the same [`TypeNameInterner`]
    /// this namespace will later be queried against; foreign ids trigger
    /// the interner's "not interned" panic on the first interner-
    /// consulting call.
    #[must_use]
    pub fn from_type_name_unchecked(t: TypeName) -> Self {
        Self(t)
    }

    /// Ruby `RBS::Namespace.parse`. Mirrors
    /// `source.split("::").drop(absolute ? 1 : 0)` after stripping
    /// trailing empty fields. Interior empty fields are preserved.
    /// Boundary inputs (`""`, `"::"`, `":::"`, `"::::"`, etc.) are
    /// pinned by the tests below.
    #[must_use]
    pub fn parse(names: &mut TypeNameInterner, strings: &mut StringInterner, source: &str) -> Self {
        let absolute = source.starts_with("::");
        let mut parts: Vec<&str> = source.split("::").collect();
        while parts.last().is_some_and(|p| p.is_empty()) {
            parts.pop();
        }
        let skip = if absolute && !parts.is_empty() { 1 } else { 0 };
        let mut current = names.root(absolute);
        for part in parts.into_iter().skip(skip) {
            let seg = strings.intern(part);
            current = names.append(current, seg);
        }
        Self(current)
    }

    /// The underlying [`TypeName`] id (also reachable via `Into<TypeName>`).
    #[must_use]
    pub fn as_type_name(self) -> TypeName {
        self.0
    }

    /// Ruby `Namespace#absolute?`.
    #[must_use]
    pub fn is_absolute(self, names: &TypeNameInterner) -> bool {
        names.is_absolute(self.0)
    }

    /// Ruby `Namespace#relative?`.
    #[must_use]
    pub fn is_relative(self, names: &TypeNameInterner) -> bool {
        !self.is_absolute(names)
    }

    /// Ruby `Namespace#empty?` -- true when the namespace has no segments
    /// (one of the two roots).
    #[must_use]
    pub fn is_empty(self, names: &TypeNameInterner) -> bool {
        names.is_root(self.0)
    }

    /// Number of segments in the namespace path.
    #[must_use]
    pub fn depth(self, names: &TypeNameInterner) -> usize {
        names.depth(self.0)
    }

    /// Ruby `Namespace#path` -- the namespace's segments from root to leaf.
    #[must_use]
    pub fn path(self, names: &TypeNameInterner) -> Vec<SymbolId> {
        names.segments(self.0)
    }

    /// Ruby `Namespace#append` -- returns the namespace extended by one
    /// more segment.
    #[must_use]
    pub fn append(self, names: &mut TypeNameInterner, segment: SymbolId) -> Self {
        Self(names.append(self.0, segment))
    }

    /// Ruby `Namespace#parent` raises for either root; this returns
    /// `None` instead.
    #[must_use]
    pub fn parent(self, names: &TypeNameInterner) -> Option<Self> {
        names.parent(self.0).map(Self)
    }

    /// Ruby `Namespace#+`. If `tail` is absolute, `self` is discarded
    /// and the result is `tail`; otherwise `self`'s segments are
    /// extended by `tail`'s under `self`'s absolute flag.
    #[must_use]
    pub fn concat(self, names: &mut TypeNameInterner, tail: Self) -> Self {
        Self(names.concat(self.0, tail.0))
    }

    /// Ruby `Namespace#absolute!` -- returns the same path with the
    /// absolute flag set.
    #[must_use]
    pub fn to_absolute(self, names: &mut TypeNameInterner) -> Self {
        Self(names.to_absolute(self.0))
    }

    /// Ruby `Namespace#relative!` -- returns the same path with the
    /// absolute flag cleared.
    #[must_use]
    pub fn to_relative(self, names: &mut TypeNameInterner) -> Self {
        Self(names.to_relative(self.0))
    }

    /// Ruby `Namespace#split` -- `(parent, last_segment)`. Returns
    /// `None` for either root.
    #[must_use]
    pub fn split(self, names: &TypeNameInterner) -> Option<(Self, SymbolId)> {
        let parent = names.parent(self.0)?;
        let segment = names
            .last_segment(self.0)
            .expect("non-root entry has a segment");
        Some((Self(parent), segment))
    }

    /// Ruby `Namespace#ascend` -- yields `self`, then each ancestor, up
    /// to one of the two roots. If `self` is already a root, the result
    /// is a single-element vec.
    #[must_use]
    pub fn ascend(self, names: &TypeNameInterner) -> Vec<Self> {
        std::iter::successors(Some(self.0), |&cur| names.parent(cur))
            .map(Self)
            .collect()
    }

    /// Ruby `Namespace#to_s` -- non-empty namespaces render with a
    /// trailing `"::"`; the two roots render as `"::"` and `""`.
    #[must_use]
    pub fn display(self, names: &TypeNameInterner, strings: &StringInterner) -> String {
        let mut s = names.display(self.0, strings);
        if !names.is_root(self.0) {
            s.push_str("::");
        }
        s
    }

    /// Ruby `Namespace#to_type_name` -- returns `None` for either root
    /// (where Ruby raises). The returned [`TypeName`] is the same id as
    /// [`Namespace::as_type_name`]; this method exists to surface the
    /// empty-check in the type system.
    #[must_use]
    pub fn to_type_name(self, names: &TypeNameInterner) -> Option<TypeName> {
        if names.is_root(self.0) {
            None
        } else {
            Some(self.0)
        }
    }
}

impl From<Namespace> for TypeName {
    fn from(n: Namespace) -> Self {
        n.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> (StringInterner, TypeNameInterner) {
        (StringInterner::new(), TypeNameInterner::new())
    }

    #[test]
    fn empty_and_root_are_distinct() {
        let (_, t) = setup();
        let empty = Namespace::empty(&t);
        let root = Namespace::root(&t);
        assert_ne!(empty, root);
        assert!(empty.is_empty(&t));
        assert!(root.is_empty(&t));
        assert!(!empty.is_absolute(&t));
        assert!(root.is_absolute(&t));
        assert_eq!(empty.depth(&t), 0);
        assert_eq!(root.depth(&t), 0);
    }

    #[test]
    fn parse_with_and_without_trailing_separator_round_trip() {
        let (mut s, mut t) = setup();
        let abs_with = Namespace::parse(&mut t, &mut s, "::RBS::Foo::");
        let abs_without = Namespace::parse(&mut t, &mut s, "::RBS::Foo");
        assert_eq!(abs_with, abs_without);
        assert!(abs_with.is_absolute(&t));
        assert_eq!(abs_with.display(&t, &s), "::RBS::Foo::");

        let rel_with = Namespace::parse(&mut t, &mut s, "RBS::Foo::");
        let rel_without = Namespace::parse(&mut t, &mut s, "RBS::Foo");
        assert_eq!(rel_with, rel_without);
        assert!(!rel_with.is_absolute(&t));
        assert_eq!(rel_with.display(&t, &s), "RBS::Foo::");
    }

    #[test]
    fn parse_handles_root_and_empty() {
        let (mut s, mut t) = setup();
        let root = Namespace::parse(&mut t, &mut s, "::");
        let empty = Namespace::parse(&mut t, &mut s, "");
        assert_eq!(root, Namespace::root(&t));
        assert_eq!(empty, Namespace::empty(&t));
        assert_eq!(root.display(&t, &s), "::");
        assert_eq!(empty.display(&t, &s), "");
    }

    #[test]
    fn parse_preserves_internal_empty_segments() {
        // Interior empties are preserved; only trailing empties drop.
        let (mut s, mut t) = setup();

        // Relative: "A::::B::" → ["A", "", "B"].
        let rel = Namespace::parse(&mut t, &mut s, "A::::B::");
        assert_eq!(rel.depth(&t), 3);
        let segs = rel.path(&t);
        assert_eq!(s.resolve(segs[0]), "A");
        assert_eq!(s.resolve(segs[1]), "");
        assert_eq!(s.resolve(segs[2]), "B");
        assert_eq!(rel.display(&t, &s), "A::::B::");

        // Absolute: "::A::::B" → after drop(1), ["A", "", "B"].
        let abs = Namespace::parse(&mut t, &mut s, "::A::::B");
        assert_eq!(abs.depth(&t), 3);
        let abs_segs = abs.path(&t);
        assert_eq!(s.resolve(abs_segs[0]), "A");
        assert_eq!(s.resolve(abs_segs[1]), "");
        assert_eq!(s.resolve(abs_segs[2]), "B");

        // Multiple trailing "::" all collapse.
        let trailing = Namespace::parse(&mut t, &mut s, "A::B::::");
        assert_eq!(trailing.depth(&t), 2);
        assert_eq!(trailing.display(&t, &s), "A::B::");
    }

    #[test]
    fn append_and_parent_round_trip() {
        let (mut s, mut t) = setup();
        let rbs = s.intern("RBS");
        let ns = Namespace::root(&t).append(&mut t, rbs);
        assert_eq!(ns.display(&t, &s), "::RBS::");
        assert_eq!(ns.parent(&t), Some(Namespace::root(&t)));
        assert!(Namespace::root(&t).parent(&t).is_none());
    }

    #[test]
    fn append_from_non_root_matches_parse() {
        let (mut s, mut t) = setup();
        let foo = s.intern("Foo");
        let rbs_ns = Namespace::parse(&mut t, &mut s, "::RBS::");
        let built = rbs_ns.append(&mut t, foo);
        assert_eq!(built, Namespace::parse(&mut t, &mut s, "::RBS::Foo::"));

        let bar = s.intern("Bar");
        let rel_a = Namespace::parse(&mut t, &mut s, "A::");
        assert_eq!(rel_a.append(&mut t, bar).display(&t, &s), "A::Bar::");
    }

    #[test]
    fn split_returns_parent_and_last() {
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, "::RBS::Foo::");
        let (parent, last) = ns.split(&t).unwrap();
        assert_eq!(parent.display(&t, &s), "::RBS::");
        assert_eq!(s.resolve(last), "Foo");

        assert!(Namespace::root(&t).split(&t).is_none());
        assert!(Namespace::empty(&t).split(&t).is_none());
    }

    #[test]
    fn ascend_walks_to_root() {
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, "::A::B::C::");
        let path: Vec<String> = ns.ascend(&t).iter().map(|n| n.display(&t, &s)).collect();
        assert_eq!(path, vec!["::A::B::C::", "::A::B::", "::A::", "::"]);

        let rel = Namespace::parse(&mut t, &mut s, "A::B::");
        let rel_path: Vec<String> = rel.ascend(&t).iter().map(|n| n.display(&t, &s)).collect();
        assert_eq!(rel_path, vec!["A::B::", "A::", ""]);
    }

    #[test]
    fn ascend_on_root_yields_self_only() {
        let (_, t) = setup();
        assert_eq!(Namespace::root(&t).ascend(&t), vec![Namespace::root(&t)]);
        assert_eq!(Namespace::empty(&t).ascend(&t), vec![Namespace::empty(&t)]);
    }

    #[test]
    fn concat_follows_ruby_plus_semantics() {
        let (mut s, mut t) = setup();
        let empty = Namespace::empty(&t);
        let root = Namespace::root(&t);
        let head_rel = Namespace::parse(&mut t, &mut s, "A::");
        let head_abs = Namespace::parse(&mut t, &mut s, "::RBS::");
        let tail_rel = Namespace::parse(&mut t, &mut s, "Foo::Bar::");
        let tail_abs = Namespace::parse(&mut t, &mut s, "::Other::");

        // Relative tail concatenates under head's absolute flag.
        assert_eq!(
            head_abs.concat(&mut t, tail_rel).display(&t, &s),
            "::RBS::Foo::Bar::"
        );
        assert_eq!(
            head_rel.concat(&mut t, tail_rel).display(&t, &s),
            "A::Foo::Bar::"
        );

        // Absolute tail short-circuits to tail (head is discarded).
        assert_eq!(head_abs.concat(&mut t, tail_abs), tail_abs);
        assert_eq!(head_rel.concat(&mut t, root), root);

        // Root and empty edge cases.
        assert_eq!(
            root.concat(&mut t, tail_rel).display(&t, &s),
            "::Foo::Bar::"
        );
        assert_eq!(empty.concat(&mut t, tail_rel), tail_rel);
        assert_eq!(tail_rel.concat(&mut t, empty), tail_rel);
        assert_eq!(root.concat(&mut t, root), root);
        assert_eq!(empty.concat(&mut t, empty), empty);
        assert_eq!(empty.concat(&mut t, root), root);
    }

    #[test]
    fn to_absolute_to_relative() {
        let (mut s, mut t) = setup();
        let rel = Namespace::parse(&mut t, &mut s, "A::B::");
        let abs = rel.to_absolute(&mut t);
        assert!(abs.is_absolute(&t));
        assert_eq!(abs.display(&t, &s), "::A::B::");
        let back = abs.to_relative(&mut t);
        assert_eq!(back, rel);

        // Idempotence.
        assert_eq!(abs.to_absolute(&mut t), abs);
        assert_eq!(rel.to_relative(&mut t), rel);
    }

    #[test]
    fn path_returns_segments() {
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, "::A::B::C::");
        let names: Vec<&str> = ns.path(&t).iter().map(|sym| s.resolve(*sym)).collect();
        assert_eq!(names, vec!["A", "B", "C"]);

        assert!(Namespace::root(&t).path(&t).is_empty());
        assert!(Namespace::empty(&t).path(&t).is_empty());
    }

    #[test]
    fn to_type_name_is_none_for_roots() {
        let (mut s, mut t) = setup();
        assert!(Namespace::root(&t).to_type_name(&t).is_none());
        assert!(Namespace::empty(&t).to_type_name(&t).is_none());

        let ns = Namespace::parse(&mut t, &mut s, "::RBS::Foo::");
        let tn = ns.to_type_name(&t).unwrap();
        assert_eq!(tn, ns.as_type_name());
        assert_eq!(t.display(tn, &s), "::RBS::Foo");
    }

    #[test]
    fn conversions_to_and_from_type_name() {
        let (mut s, mut t) = setup();
        let tn = t.parse(&mut s, "::RBS::Foo");
        let ns = Namespace::from_type_name_unchecked(tn);
        let back: TypeName = ns.into();
        assert_eq!(back, tn);
        assert_eq!(ns.as_type_name(), tn);
    }

    #[test]
    fn namespace_size_matches_type_name() {
        assert_eq!(std::mem::size_of::<Namespace>(), 8);
        assert_eq!(std::mem::size_of::<Option<Namespace>>(), 8);
    }

    #[test]
    #[should_panic(expected = "not interned in this TypeNameInterner")]
    fn from_type_name_unchecked_panics_on_foreign_id() {
        // All interner-consulting methods route through a single guard;
        // one representative call covers the panic path.
        let (mut s1, mut t1) = setup();
        let (_, t2) = setup();
        let tn = t1.parse(&mut s1, "::RBS::Foo");
        let ns = Namespace::from_type_name_unchecked(tn);
        let _ = ns.depth(&t2);
    }

    #[test]
    fn parse_triple_colon_keeps_absolute_flag() {
        // ":::" → absolute=true, path=[":"].
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, ":::");
        assert!(ns.is_absolute(&t));
        assert_eq!(ns.depth(&t), 1);
        assert_eq!(s.resolve(ns.path(&t)[0]), ":");
    }

    #[test]
    fn parse_even_colon_runs_collapse_to_absolute_root() {
        // "::::" splits to ["", "", ""]; trailing empties strip to [];
        // skip=0 on empty parts → root(true). Same for "::::::".
        let (mut s, mut t) = setup();
        assert_eq!(
            Namespace::parse(&mut t, &mut s, "::::"),
            Namespace::root(&t)
        );
        assert_eq!(
            Namespace::parse(&mut t, &mut s, "::::::"),
            Namespace::root(&t)
        );
    }

    #[test]
    fn parse_single_colon_is_relative_segment() {
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, ":");
        assert!(!ns.is_absolute(&t));
        let segs = ns.path(&t);
        assert_eq!(segs.len(), 1);
        assert_eq!(s.resolve(segs[0]), ":");
    }

    #[test]
    fn parse_yields_same_id_across_independent_interners() {
        let mut sa = StringInterner::new();
        let mut sb = StringInterner::new();
        let mut ta = TypeNameInterner::new();
        let mut tb = TypeNameInterner::new();

        let a = Namespace::parse(&mut ta, &mut sa, "::RBS::Foo::");
        let b = Namespace::parse(&mut tb, &mut sb, "::RBS::Foo::");
        assert_eq!(a, b);
        assert_eq!(a.as_type_name(), b.as_type_name());
    }

    #[test]
    fn to_type_name_equals_split_then_recompose() {
        let (mut s, mut t) = setup();
        let ns = Namespace::parse(&mut t, &mut s, "::RBS::Foo::Bar::");
        let tn = ns.to_type_name(&t).unwrap();
        let (parent, last) = ns.split(&t).unwrap();
        let recomposed = parent.append(&mut t, last).as_type_name();
        assert_eq!(tn, recomposed);
    }

    #[test]
    fn equal_paths_built_differently_are_eq_and_hash_eq() {
        use std::collections::hash_map::DefaultHasher;
        use std::hash::{Hash, Hasher};
        let (mut s, mut t) = setup();
        let foo = s.intern("Foo");
        let bar = s.intern("Bar");
        let built = Namespace::root(&t).append(&mut t, foo).append(&mut t, bar);
        let parsed = Namespace::parse(&mut t, &mut s, "::Foo::Bar::");
        assert_eq!(built, parsed);

        let mut h1 = DefaultHasher::new();
        built.hash(&mut h1);
        let mut h2 = DefaultHasher::new();
        parsed.hash(&mut h2);
        assert_eq!(h1.finish(), h2.finish());
    }

    #[test]
    fn from_type_name_unchecked_does_not_validate_segment_kind() {
        // Wrapping an alias-kind (lowercase) or interface-kind (`_`-prefix)
        // TypeName does NOT panic, though the resulting Namespace is
        // semantically malformed.
        let (mut s, mut t) = setup();
        let alias = t.parse(&mut s, "::RBS::foo");
        assert_eq!(
            Namespace::from_type_name_unchecked(alias).display(&t, &s),
            "::RBS::foo::"
        );
        let iface = t.parse(&mut s, "::RBS::_Foo");
        assert_eq!(
            Namespace::from_type_name_unchecked(iface).display(&t, &s),
            "::RBS::_Foo::"
        );
    }
}

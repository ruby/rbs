//! Content-addressed flyweight type names.
//!
//! Unlike the Ruby implementation, which distinguishes `RBS::Namespace`
//! (a path of class names plus an `absolute` flag) from `RBS::TypeName`
//! (a Namespace plus a trailing name), this module folds both into a
//! single [`TypeName`]:
//!
//! - An empty path is a namespace root (either `::` or `""`).
//! - A non-empty path's last segment is what Ruby calls the trailing
//!   "name", and its [`Kind`] is derived from that segment's first
//!   character.
//!
//! Each [`TypeName`] is a 64-bit content-addressed id derived from its
//! parent's id and its last segment's [`SymbolId`]. Because the recipe is
//! deterministic, two independently-built [`TypeNameInterner`]s assign the
//! same id to the same logical name — merging is just a `HashMap` union.
//! Two pre-interned roots cover the absolute / relative split via fixed
//! sentinel hashes.
//!
//! ```
//! use ruby_rbs::interner::StringInterner;
//! use ruby_rbs::type_name::{Kind, TypeNameInterner};
//!
//! let mut strings = StringInterner::new();
//! let mut names = TypeNameInterner::new();
//!
//! let foo = names.parse(&mut strings, "::RBS::Foo");
//! let foo_again = names.parse(&mut strings, "::RBS::Foo");
//! assert_eq!(foo, foo_again);                         // flyweighted
//! assert_eq!(names.kind(foo, &strings), Some(Kind::Class));
//! assert_eq!(names.display(foo, &strings), "::RBS::Foo");
//! ```

use crate::ids::{SymbolId, TypeName};
use crate::interner::StringInterner;
use std::collections::HashMap;
use xxhash_rust::xxh3::xxh3_64;

/// Fixed sentinel hash for the absolute (`::`) namespace root. Chosen so
/// no realistic `xxh3_64` content collision is expected; any value would
/// do as long as it differs from `RELATIVE_ROOT_HASH`.
const ABSOLUTE_ROOT_HASH: u64 = 0xA850_1075_0001_0001;

/// Fixed sentinel hash for the relative (`""`) namespace root.
const RELATIVE_ROOT_HASH: u64 = 0x8E1A_71FE_0001_0001;

fn child_hash(parent: TypeName, segment: SymbolId) -> u64 {
    let mut buf = [0u8; 16];
    buf[..8].copy_from_slice(&parent.get().to_le_bytes());
    buf[8..].copy_from_slice(&segment.get().to_le_bytes());
    xxh3_64(&buf)
}

/// Kind of a [`TypeName`], derived from the first character of its last
/// segment. `None` is returned for an empty type name (a namespace root).
#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum Kind {
    Class,
    Alias,
    Interface,
}

/// An entry rooted in the absolute namespace (`::`).
#[derive(Copy, Clone, Debug)]
struct AbsoluteTypeNameEntry {
    /// `None` for the absolute root.
    parent: Option<TypeName>,
    /// `None` for the absolute root.
    segment: Option<SymbolId>,
}

/// An entry rooted in the relative namespace (`""`).
#[derive(Copy, Clone, Debug)]
struct RelativeTypeNameEntry {
    /// `None` for the relative root.
    parent: Option<TypeName>,
    /// `None` for the relative root.
    segment: Option<SymbolId>,
}

#[derive(Copy, Clone, Debug)]
enum Entry {
    Absolute(AbsoluteTypeNameEntry),
    Relative(RelativeTypeNameEntry),
}

impl Entry {
    fn parent(self) -> Option<TypeName> {
        match self {
            Self::Absolute(e) => e.parent,
            Self::Relative(e) => e.parent,
        }
    }

    fn segment(self) -> Option<SymbolId> {
        match self {
            Self::Absolute(e) => e.segment,
            Self::Relative(e) => e.segment,
        }
    }

    fn is_absolute(self) -> bool {
        matches!(self, Self::Absolute(_))
    }
}

/// Interner that flyweights [`TypeName`]s with content-addressed ids.
///
/// Build new names by walking down from a root:
///
/// ```
/// use ruby_rbs::interner::StringInterner;
/// use ruby_rbs::type_name::TypeNameInterner;
///
/// let mut strings = StringInterner::new();
/// let mut names = TypeNameInterner::new();
/// let rbs = strings.intern("RBS");
/// let foo = strings.intern("Foo");
///
/// let abs = names.absolute_root();
/// let n1 = names.append(abs, rbs);
/// let n2 = names.append(n1, foo);
/// assert_eq!(names.display(n2, &strings), "::RBS::Foo");
/// ```
pub struct TypeNameInterner {
    entries: HashMap<TypeName, Entry>,
    relative_root: TypeName,
    absolute_root: TypeName,
}

impl Default for TypeNameInterner {
    fn default() -> Self {
        let relative_root = TypeName::from_hash(RELATIVE_ROOT_HASH);
        let absolute_root = TypeName::from_hash(ABSOLUTE_ROOT_HASH);
        let mut entries = HashMap::new();
        entries.insert(
            relative_root,
            Entry::Relative(RelativeTypeNameEntry {
                parent: None,
                segment: None,
            }),
        );
        entries.insert(
            absolute_root,
            Entry::Absolute(AbsoluteTypeNameEntry {
                parent: None,
                segment: None,
            }),
        );
        Self {
            entries,
            relative_root,
            absolute_root,
        }
    }
}

impl TypeNameInterner {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// The empty relative type name (`""` — `Namespace.empty` in Ruby).
    #[must_use]
    pub fn relative_root(&self) -> TypeName {
        self.relative_root
    }

    /// The empty absolute type name (`"::"` — `Namespace.root` in Ruby).
    #[must_use]
    pub fn absolute_root(&self) -> TypeName {
        self.absolute_root
    }

    /// Returns [`absolute_root`] when `absolute` is true, else
    /// [`relative_root`].
    ///
    /// [`absolute_root`]: Self::absolute_root
    /// [`relative_root`]: Self::relative_root
    #[must_use]
    pub fn root(&self, absolute: bool) -> TypeName {
        if absolute {
            self.absolute_root
        } else {
            self.relative_root
        }
    }

    /// Returns the type name `parent::segment`. Content-addressed:
    /// identical inputs return the same [`TypeName`] across any
    /// [`TypeNameInterner`].
    pub fn append(&mut self, parent: TypeName, segment: SymbolId) -> TypeName {
        let id = TypeName::from_hash(child_hash(parent, segment));
        if self.entries.contains_key(&id) {
            return id;
        }
        let parent_entry = self
            .entries
            .get(&parent)
            .copied()
            .expect("parent TypeName must be interned");
        let entry = if parent_entry.is_absolute() {
            Entry::Absolute(AbsoluteTypeNameEntry {
                parent: Some(parent),
                segment: Some(segment),
            })
        } else {
            Entry::Relative(RelativeTypeNameEntry {
                parent: Some(parent),
                segment: Some(segment),
            })
        };
        self.entries.insert(id, entry);
        id
    }

    /// Builds a type name by appending each `segment` in order to `base`.
    pub fn extend<I>(&mut self, base: TypeName, segments: I) -> TypeName
    where
        I: IntoIterator<Item = SymbolId>,
    {
        segments.into_iter().fold(base, |p, s| self.append(p, s))
    }

    /// Returns the parent of `name`, or `None` if `name` is one of the
    /// two roots.
    #[must_use]
    pub fn parent(&self, name: TypeName) -> Option<TypeName> {
        self.entries[&name].parent()
    }

    /// Returns the last segment of `name`, or `None` if `name` is one of
    /// the two roots.
    #[must_use]
    pub fn last_segment(&self, name: TypeName) -> Option<SymbolId> {
        self.entries[&name].segment()
    }

    #[must_use]
    pub fn is_absolute(&self, name: TypeName) -> bool {
        self.entries[&name].is_absolute()
    }

    /// True for an empty path (the relative or absolute root).
    #[must_use]
    pub fn is_root(&self, name: TypeName) -> bool {
        self.entries[&name].parent().is_none()
    }

    /// Number of segments in `name`.
    #[must_use]
    pub fn depth(&self, name: TypeName) -> usize {
        let mut depth = 0;
        let mut cur = name;
        while let Some(parent) = self.parent(cur) {
            depth += 1;
            cur = parent;
        }
        depth
    }

    /// Returns the segments of `name` from root to leaf.
    #[must_use]
    pub fn segments(&self, name: TypeName) -> Vec<SymbolId> {
        let mut buf = Vec::with_capacity(self.depth(name));
        let mut cur = name;
        while let (Some(parent), Some(seg)) = (self.parent(cur), self.last_segment(cur)) {
            buf.push(seg);
            cur = parent;
        }
        buf.reverse();
        buf
    }

    /// Returns the same type name with `absolute = true`, sharing the path.
    pub fn to_absolute(&mut self, name: TypeName) -> TypeName {
        if self.is_absolute(name) {
            return name;
        }
        let segs = self.segments(name);
        self.extend(self.absolute_root, segs)
    }

    /// Returns the same type name with `absolute = false`, sharing the path.
    pub fn to_relative(&mut self, name: TypeName) -> TypeName {
        if !self.is_absolute(name) {
            return name;
        }
        let segs = self.segments(name);
        self.extend(self.relative_root, segs)
    }

    /// Ruby `TypeName#+` semantics: if `tail` is absolute, return `tail`;
    /// otherwise concatenate `head`'s segments + `tail`'s segments under
    /// `head`'s absolute flag.
    pub fn concat(&mut self, head: TypeName, tail: TypeName) -> TypeName {
        if self.is_absolute(tail) {
            return tail;
        }
        let tail_segs = self.segments(tail);
        self.extend(head, tail_segs)
    }

    /// Kind of the trailing segment. `None` for roots.
    ///
    /// Follows the same semantics as Ruby's constant detection (Onigmo's
    /// `ONIGENC_CTYPE_UPPER`, i.e. the Unicode `Uppercase` property): a
    /// leading `_` is an interface, a leading Unicode uppercase code point
    /// is a class, everything else is an alias.
    ///
    /// The ASCII path — hit by virtually every identifier — is a single
    /// byte comparison. Non-ASCII names pay one UTF-8 code point decode
    /// plus a `char::is_uppercase` table lookup.
    #[must_use]
    pub fn kind(&self, name: TypeName, strings: &StringInterner) -> Option<Kind> {
        let seg = self.last_segment(name)?;
        let s = strings.resolve(seg);
        let first_byte = *s.as_bytes().first()?;
        Some(if first_byte == b'_' {
            Kind::Interface
        } else if first_byte < 0x80 {
            if first_byte.is_ascii_uppercase() {
                Kind::Class
            } else {
                Kind::Alias
            }
        } else if s.chars().next().is_some_and(char::is_uppercase) {
            Kind::Class
        } else {
            Kind::Alias
        })
    }

    /// Render `name` in the canonical RBS string form
    /// (e.g. `::RBS::Foo`, `Foo::bar`).
    #[must_use]
    pub fn display(&self, name: TypeName, strings: &StringInterner) -> String {
        let segs = self.segments(name);
        let absolute = self.is_absolute(name);
        let mut s = String::new();
        if absolute {
            s.push_str("::");
        }
        for (i, seg) in segs.iter().enumerate() {
            if i > 0 {
                s.push_str("::");
            }
            s.push_str(strings.resolve(*seg));
        }
        s
    }

    /// Parse an RBS type-name string into a [`TypeName`], interning any
    /// new segments into `strings`.
    ///
    /// Empty `source` returns the relative root; `"::"` returns the
    /// absolute root.
    pub fn parse(&mut self, strings: &mut StringInterner, source: &str) -> TypeName {
        let absolute = source.starts_with("::");
        let trimmed = source.strip_prefix("::").unwrap_or(source);
        let mut current = self.root(absolute);
        for part in trimmed.split("::") {
            if part.is_empty() {
                continue;
            }
            let seg = strings.intern(part);
            current = self.append(current, seg);
        }
        current
    }

    /// Move every entry from `other` into `self`. Because IDs are
    /// content-addressed, the two interners' roots and any shared paths
    /// already have the same ids; this is a plain `HashMap` union.
    pub fn merge(&mut self, other: TypeNameInterner) {
        for (id, entry) in other.entries {
            self.entries.entry(id).or_insert(entry);
        }
    }

    /// Refine `name` to an [`AbsoluteTypeName`] if it is absolute.
    #[must_use]
    pub fn try_as_absolute(&self, name: TypeName) -> Option<AbsoluteTypeName> {
        self.is_absolute(name).then_some(AbsoluteTypeName(name))
    }

    /// Refine `name` to an [`AbsoluteClassTypeName`] if it is absolute and
    /// its last segment denotes a class.
    #[must_use]
    pub fn try_as_absolute_class(
        &self,
        name: TypeName,
        strings: &StringInterner,
    ) -> Option<AbsoluteClassTypeName> {
        (self.is_absolute(name) && self.kind(name, strings) == Some(Kind::Class))
            .then_some(AbsoluteClassTypeName(name))
    }

    /// Refine `name` to an [`AbsoluteAliasTypeName`] if it is absolute and
    /// its last segment denotes an alias.
    #[must_use]
    pub fn try_as_absolute_alias(
        &self,
        name: TypeName,
        strings: &StringInterner,
    ) -> Option<AbsoluteAliasTypeName> {
        (self.is_absolute(name) && self.kind(name, strings) == Some(Kind::Alias))
            .then_some(AbsoluteAliasTypeName(name))
    }

    /// Refine `name` to an [`AbsoluteInterfaceTypeName`] if it is absolute
    /// and its last segment denotes an interface.
    #[must_use]
    pub fn try_as_absolute_interface(
        &self,
        name: TypeName,
        strings: &StringInterner,
    ) -> Option<AbsoluteInterfaceTypeName> {
        (self.is_absolute(name) && self.kind(name, strings) == Some(Kind::Interface))
            .then_some(AbsoluteInterfaceTypeName(name))
    }
}

/// A [`TypeName`] guaranteed to be absolute.
///
/// Construct via [`TypeNameInterner::try_as_absolute`]; widen back to a
/// plain [`TypeName`] via [`From`].
#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct AbsoluteTypeName(TypeName);

impl AbsoluteTypeName {
    #[must_use]
    pub fn as_type_name(self) -> TypeName {
        self.0
    }
}

impl From<AbsoluteTypeName> for TypeName {
    fn from(value: AbsoluteTypeName) -> Self {
        value.0
    }
}

/// A [`TypeName`] guaranteed to be absolute and of [`Kind::Class`].
#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct AbsoluteClassTypeName(TypeName);

impl AbsoluteClassTypeName {
    #[must_use]
    pub fn as_type_name(self) -> TypeName {
        self.0
    }
}

impl From<AbsoluteClassTypeName> for TypeName {
    fn from(value: AbsoluteClassTypeName) -> Self {
        value.0
    }
}

impl From<AbsoluteClassTypeName> for AbsoluteTypeName {
    fn from(value: AbsoluteClassTypeName) -> Self {
        AbsoluteTypeName(value.0)
    }
}

/// A [`TypeName`] guaranteed to be absolute and of [`Kind::Alias`].
#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct AbsoluteAliasTypeName(TypeName);

impl AbsoluteAliasTypeName {
    #[must_use]
    pub fn as_type_name(self) -> TypeName {
        self.0
    }
}

impl From<AbsoluteAliasTypeName> for TypeName {
    fn from(value: AbsoluteAliasTypeName) -> Self {
        value.0
    }
}

impl From<AbsoluteAliasTypeName> for AbsoluteTypeName {
    fn from(value: AbsoluteAliasTypeName) -> Self {
        AbsoluteTypeName(value.0)
    }
}

/// A [`TypeName`] guaranteed to be absolute and of [`Kind::Interface`].
#[derive(Copy, Clone, Eq, PartialEq, Hash, Debug)]
pub struct AbsoluteInterfaceTypeName(TypeName);

impl AbsoluteInterfaceTypeName {
    #[must_use]
    pub fn as_type_name(self) -> TypeName {
        self.0
    }
}

impl From<AbsoluteInterfaceTypeName> for TypeName {
    fn from(value: AbsoluteInterfaceTypeName) -> Self {
        value.0
    }
}

impl From<AbsoluteInterfaceTypeName> for AbsoluteTypeName {
    fn from(value: AbsoluteInterfaceTypeName) -> Self {
        AbsoluteTypeName(value.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> (StringInterner, TypeNameInterner) {
        (StringInterner::new(), TypeNameInterner::new())
    }

    #[test]
    fn roots_are_distinct_and_stable() {
        let (_, names) = setup();
        let rel = names.relative_root();
        let abs = names.absolute_root();
        assert_ne!(rel, abs);
        assert!(names.is_root(rel));
        assert!(names.is_root(abs));
        assert!(!names.is_absolute(rel));
        assert!(names.is_absolute(abs));
        assert_eq!(names.depth(rel), 0);
        assert_eq!(names.depth(abs), 0);
    }

    #[test]
    fn roots_are_identical_across_interners() {
        let a = TypeNameInterner::new();
        let b = TypeNameInterner::new();
        assert_eq!(a.absolute_root(), b.absolute_root());
        assert_eq!(a.relative_root(), b.relative_root());
    }

    #[test]
    fn append_flyweights_identical_paths() {
        let (mut s, mut t) = setup();
        let rbs = s.intern("RBS");
        let foo = s.intern("Foo");
        let abs = t.absolute_root();
        let a = t.append(abs, rbs);
        let a2 = t.append(abs, rbs);
        assert_eq!(a, a2);
        let ab = t.append(a, foo);
        let ab2 = t.append(a, foo);
        assert_eq!(ab, ab2);
        // Different absoluteness ⇒ different ids
        let rel = t.relative_root();
        let r = t.append(rel, rbs);
        assert_ne!(a, r);
    }

    #[test]
    fn same_path_yields_same_id_across_interners() {
        let mut sa = StringInterner::new();
        let mut sb = StringInterner::new();
        let mut ta = TypeNameInterner::new();
        let mut tb = TypeNameInterner::new();

        let a = ta.parse(&mut sa, "::RBS::Foo");
        let b = tb.parse(&mut sb, "::RBS::Foo");
        assert_eq!(a, b);
    }

    #[test]
    fn parse_and_display_round_trip() {
        let (mut s, mut t) = setup();
        for src in ["::RBS::Foo", "Foo::Bar", "::Foo", "Foo", "::", ""] {
            let id = t.parse(&mut s, src);
            assert_eq!(t.display(id, &s), src);
        }
    }

    #[test]
    fn parse_dedups_against_append_path() {
        let (mut s, mut t) = setup();
        let parsed = t.parse(&mut s, "::RBS::Foo");
        let rbs = s.intern("RBS");
        let foo = s.intern("Foo");
        let abs = t.absolute_root();
        let built_rbs = t.append(abs, rbs);
        let built = t.append(built_rbs, foo);
        assert_eq!(parsed, built);
    }

    #[test]
    fn segments_and_parent() {
        let (mut s, mut t) = setup();
        let id = t.parse(&mut s, "::A::B::C");
        let segs = t.segments(id);
        assert_eq!(segs.len(), 3);
        assert_eq!(s.resolve(segs[0]), "A");
        assert_eq!(s.resolve(segs[1]), "B");
        assert_eq!(s.resolve(segs[2]), "C");
        assert_eq!(t.depth(id), 3);

        let parent = t.parent(id).unwrap();
        assert_eq!(t.display(parent, &s), "::A::B");
        let grand = t.parent(parent).unwrap();
        assert_eq!(t.display(grand, &s), "::A");
        let root = t.parent(grand).unwrap();
        assert_eq!(root, t.absolute_root());
        assert!(t.parent(root).is_none());
    }

    #[test]
    fn kind_is_derived_from_last_segment() {
        let (mut s, mut t) = setup();
        let cls = t.parse(&mut s, "::RBS::Foo");
        let als = t.parse(&mut s, "::RBS::foo");
        let iface = t.parse(&mut s, "::RBS::_Foo");
        let root = t.absolute_root();
        assert_eq!(t.kind(cls, &s), Some(Kind::Class));
        assert_eq!(t.kind(als, &s), Some(Kind::Alias));
        assert_eq!(t.kind(iface, &s), Some(Kind::Interface));
        assert_eq!(t.kind(root, &s), None);
    }

    #[test]
    fn kind_uses_unicode_uppercase_property() {
        let (mut s, mut t) = setup();

        // Non-ASCII uppercase code points (Lu / Lt / Other_Uppercase) count
        // as constants, matching Ruby's `rb_sym_constant_char_p`.
        let ultima = t.parse(&mut s, "Última");
        let omega = t.parse(&mut s, "Ωmega");
        let n_tilde = t.parse(&mut s, "Ñoño");
        assert_eq!(t.kind(ultima, &s), Some(Kind::Class));
        assert_eq!(t.kind(omega, &s), Some(Kind::Class));
        assert_eq!(t.kind(n_tilde, &s), Some(Kind::Class));

        // Non-ASCII lowercase (Ll) and Other_Letter (kanji etc.) are local
        // identifiers in Ruby, so they belong to `Alias` here.
        let alpha = t.parse(&mut s, "αlpha");
        let kanji = t.parse(&mut s, "日本語");
        assert_eq!(t.kind(alpha, &s), Some(Kind::Alias));
        assert_eq!(t.kind(kanji, &s), Some(Kind::Alias));

        // A leading underscore keeps interface semantics regardless of the
        // rest of the name.
        let iface = t.parse(&mut s, "_Únicos");
        assert_eq!(t.kind(iface, &s), Some(Kind::Interface));
    }

    #[test]
    fn to_absolute_to_relative() {
        let (mut s, mut t) = setup();
        let rel = t.parse(&mut s, "A::B");
        let abs = t.to_absolute(rel);
        assert!(t.is_absolute(abs));
        assert_eq!(t.display(abs, &s), "::A::B");
        let back = t.to_relative(abs);
        assert_eq!(back, rel);
        // Idempotent
        assert_eq!(t.to_absolute(abs), abs);
        assert_eq!(t.to_relative(rel), rel);
    }

    #[test]
    fn concat_follows_ruby_plus_semantics() {
        let (mut s, mut t) = setup();
        let head = t.parse(&mut s, "::RBS");
        let tail_rel = t.parse(&mut s, "Foo::Bar");
        let tail_abs = t.parse(&mut s, "::Other");

        // Relative tail concatenates under head's absoluteness
        let joined = t.concat(head, tail_rel);
        assert_eq!(t.display(joined, &s), "::RBS::Foo::Bar");

        // Absolute tail short-circuits
        let joined2 = t.concat(head, tail_abs);
        assert_eq!(joined2, tail_abs);
        assert_eq!(t.display(joined2, &s), "::Other");
    }

    #[test]
    fn merge_unions_entries() {
        let mut sa = StringInterner::new();
        let mut sb = StringInterner::new();
        let mut ta = TypeNameInterner::new();
        let mut tb = TypeNameInterner::new();

        let a1 = ta.parse(&mut sa, "::RBS::Foo");
        let a2 = ta.parse(&mut sa, "::Only::In::A");
        let b1 = tb.parse(&mut sb, "::RBS::Foo");
        let b2 = tb.parse(&mut sb, "::Only::In::B");

        // Same content ⇒ same id, even before merge.
        assert_eq!(a1, b1);

        // Merge strings + names from b into a.
        sa.merge(sb);
        ta.merge(tb);

        // All ids resolve in the merged interners.
        assert_eq!(ta.display(a2, &sa), "::Only::In::A");
        assert_eq!(ta.display(b2, &sa), "::Only::In::B");
    }

    #[test]
    fn typename_id_size() {
        assert_eq!(std::mem::size_of::<TypeName>(), 8);
        assert_eq!(std::mem::size_of::<Option<TypeName>>(), 8);
    }

    #[test]
    fn refined_typename_constructors() {
        let (mut s, mut t) = setup();
        let abs_class = t.parse(&mut s, "::RBS::Foo");
        let rel_class = t.parse(&mut s, "RBS::Foo");
        let abs_alias = t.parse(&mut s, "::RBS::foo");
        let abs_iface = t.parse(&mut s, "::RBS::_Foo");
        let abs_root = t.absolute_root();

        assert!(t.try_as_absolute(abs_class).is_some());
        assert!(t.try_as_absolute(rel_class).is_none());

        assert!(t.try_as_absolute_class(abs_class, &s).is_some());
        assert!(t.try_as_absolute_class(rel_class, &s).is_none());
        assert!(t.try_as_absolute_class(abs_alias, &s).is_none());
        assert!(t.try_as_absolute_class(abs_iface, &s).is_none());
        assert!(t.try_as_absolute_class(abs_root, &s).is_none());

        assert!(t.try_as_absolute_alias(abs_alias, &s).is_some());
        assert!(t.try_as_absolute_alias(abs_class, &s).is_none());

        assert!(t.try_as_absolute_interface(abs_iface, &s).is_some());
        assert!(t.try_as_absolute_interface(abs_class, &s).is_none());
    }

    #[test]
    fn refined_typename_widening() {
        let (mut s, mut t) = setup();
        let abs_class = t.parse(&mut s, "::RBS::Foo");

        let class: AbsoluteClassTypeName = t.try_as_absolute_class(abs_class, &s).unwrap();
        // Widening to AbsoluteTypeName
        let absolute: AbsoluteTypeName = class.into();
        assert_eq!(absolute.as_type_name(), abs_class);
        // Widening to TypeName
        let tn: TypeName = class.into();
        assert_eq!(tn, abs_class);
        // From AbsoluteTypeName to TypeName
        let tn2: TypeName = absolute.into();
        assert_eq!(tn2, abs_class);
    }

    #[test]
    fn refined_typename_sizes_match_typename() {
        // All refinements are zero-cost wrappers
        assert_eq!(std::mem::size_of::<AbsoluteTypeName>(), 8);
        assert_eq!(std::mem::size_of::<AbsoluteClassTypeName>(), 8);
        assert_eq!(std::mem::size_of::<AbsoluteAliasTypeName>(), 8);
        assert_eq!(std::mem::size_of::<AbsoluteInterfaceTypeName>(), 8);
        assert_eq!(std::mem::size_of::<Option<AbsoluteClassTypeName>>(), 8);
    }
}

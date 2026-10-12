use std::marker::PhantomData;

use crate::ast::Declaration;
use crate::ids::{SymbolId, TypeName};

use super::{DeclId, Environment};

/// `name` repeats the table key, as in Ruby, so iterating entries alone
/// yields their names.
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
#[non_exhaustive]
pub struct SingleEntry<N = TypeName> {
    pub name: N,
    pub decl: DeclId,
}

/// Whether a `class_decls` name is a class or a module.
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub enum ClassDeclKind {
    Class,
    Module,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ClassTag;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ModuleTag;

/// Ruby's `ClassEntry` and `ModuleEntry` differ only in `primary_decl`, so
/// they share one layout and the tag selects which `primary_decl` exists.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Entry<K> {
    name: TypeName,
    decls: Vec<DeclId>,
    kind: PhantomData<K>,
}

pub type ClassEntry = Entry<ClassTag>;
pub type ModuleEntry = Entry<ModuleTag>;

impl<K> Entry<K> {
    pub(super) fn new(name: TypeName) -> Self {
        Self {
            name,
            decls: Vec::new(),
            kind: PhantomData,
        }
    }

    pub(super) fn push(&mut self, decl: DeclId) {
        self.decls.push(decl);
    }

    #[must_use]
    pub fn name(&self) -> TypeName {
        self.name
    }

    pub fn each_decl(&self) -> impl Iterator<Item = DeclId> + '_ {
        self.decls().iter().copied()
    }

    fn decls(&self) -> &[DeclId] {
        &self.decls
    }
}

impl Entry<ClassTag> {
    /// The first declaration with a superclass, else the first one. Not
    /// memoized as in Ruby: the result is the same either way.
    ///
    /// # Panics
    ///
    /// Panics if the entry is empty, which registration never leaves behind.
    /// May also panic if `env` is not the one that issued the entry's ids.
    #[must_use]
    pub fn primary_decl(&self, env: &Environment) -> DeclId {
        self.decls
            .iter()
            .copied()
            .find(|&id| matches!(env.decl(id), Declaration::Class(c) if c.super_class.is_some()))
            .or_else(|| self.decls.first().copied())
            .expect("an entry always has at least one declaration")
    }
}

impl Entry<ModuleTag> {
    /// # Panics
    ///
    /// Panics if the entry is empty, which registration never leaves behind.
    #[must_use]
    // No `&Environment`: only a class needs to read the declarations to pick
    // the one with a superclass, and that lives on `ClassEntry`, as in Ruby.
    pub fn primary_decl(&self) -> DeclId {
        *self
            .decls
            .first()
            .expect("an entry always has at least one declaration")
    }
}

/// Ruby's `class_decls` holds both kinds under one name space, so a name is
/// either a class or a module, never both. The name follows `class_decls`,
/// so it covers modules too.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ClassDeclEntry {
    Class(ClassEntry),
    Module(ModuleEntry),
}

impl ClassDeclEntry {
    pub(super) fn new(name: TypeName, kind: ClassDeclKind) -> Self {
        match kind {
            ClassDeclKind::Class => Self::Class(Entry::new(name)),
            ClassDeclKind::Module => Self::Module(Entry::new(name)),
        }
    }

    pub(super) fn push(&mut self, decl: DeclId) {
        match self {
            Self::Class(e) => e.push(decl),
            Self::Module(e) => e.push(decl),
        }
    }

    #[must_use]
    pub fn kind(&self) -> ClassDeclKind {
        match self {
            Self::Class(_) => ClassDeclKind::Class,
            Self::Module(_) => ClassDeclKind::Module,
        }
    }

    #[must_use]
    pub fn name(&self) -> TypeName {
        match self {
            Self::Class(e) => e.name(),
            Self::Module(e) => e.name(),
        }
    }

    pub fn each_decl(&self) -> impl Iterator<Item = DeclId> + '_ {
        self.decls().iter().copied()
    }

    fn decls(&self) -> &[DeclId] {
        match self {
            Self::Class(e) => e.decls(),
            Self::Module(e) => e.decls(),
        }
    }

    /// # Panics
    ///
    /// Panics if the entry is empty, which registration never leaves behind.
    /// May also panic if `env` is not the one that issued the entry's ids.
    #[must_use]
    pub fn primary_decl(&self, env: &Environment) -> DeclId {
        match self {
            Self::Class(e) => e.primary_decl(env),
            Self::Module(e) => e.primary_decl(),
        }
    }
}

/// Ruby's `class_alias_decls` values: `ModuleAliasEntry | ClassAliasEntry`.
/// Only the module arm exists until class aliases are registered.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AliasEntry {
    Module(SingleEntry),
}

/// What `constant_entry` finds under a name: Ruby's `ClassEntry |
/// ModuleEntry | ModuleAliasEntry | ConstantEntry`. Class and module stay
/// split inside `ClassDeclEntry`. Named `*Lookup` to stay apart from Ruby's
/// `ConstantEntry`, which is the `Constant` arm here.
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ConstantLookup<'a> {
    ClassDecl(&'a ClassDeclEntry),
    ModuleAlias(&'a SingleEntry),
    Constant(&'a SingleEntry),
}

impl ConstantLookup<'_> {
    pub fn each_decl(&self) -> impl Iterator<Item = DeclId> + '_ {
        let decls = match self {
            Self::ClassDecl(e) => e.decls(),
            Self::ModuleAlias(e) | Self::Constant(e) => std::slice::from_ref(&e.decl),
        };
        decls.iter().copied()
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ModuleLookup<'a> {
    Module(&'a ModuleEntry),
    ModuleAlias(&'a SingleEntry),
}

impl ModuleLookup<'_> {
    #[must_use]
    pub fn name(&self) -> TypeName {
        match self {
            Self::Module(e) => e.name(),
            Self::ModuleAlias(e) => e.name,
        }
    }

    pub fn each_decl(&self) -> impl Iterator<Item = DeclId> + '_ {
        let decls = match self {
            Self::Module(e) => e.decls(),
            Self::ModuleAlias(e) => std::slice::from_ref(&e.decl),
        };
        decls.iter().copied()
    }

    /// An alias has the one declaration it was registered with.
    ///
    /// # Panics
    ///
    /// Panics if a module entry is empty, which registration never leaves behind.
    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        match self {
            Self::Module(e) => e.primary_decl(),
            Self::ModuleAlias(e) => e.decl,
        }
    }
}

impl Environment {
    #[must_use]
    pub fn is_class_decl(&self, name: TypeName) -> bool {
        matches!(self.class_decls.get(&name), Some(ClassDeclEntry::Class(_)))
    }

    #[must_use]
    pub fn is_module_decl(&self, name: TypeName) -> bool {
        matches!(self.class_decls.get(&name), Some(ClassDeclEntry::Module(_)))
    }

    #[must_use]
    pub fn is_module_alias(&self, name: TypeName) -> bool {
        matches!(
            self.class_alias_decls.get(&name),
            Some(AliasEntry::Module(_))
        )
    }

    #[must_use]
    pub fn is_module_name(&self, name: TypeName) -> bool {
        self.class_decls.contains_key(&name) || self.class_alias_decls.contains_key(&name)
    }

    #[must_use]
    pub fn is_type_name(&self, name: TypeName) -> bool {
        self.is_interface_name(name) || self.is_type_alias_name(name) || self.is_module_name(name)
    }

    /// TODO: class aliases are not consulted yet. Ruby's `class_entry`
    /// returns `ClassEntry | ClassAliasEntry`; return a lookup enum like
    /// `module_entry` does when class aliases are registered.
    #[must_use]
    pub fn class_entry(&self, name: TypeName) -> Option<&ClassEntry> {
        match self.class_decls.get(&name) {
            Some(ClassDeclEntry::Class(e)) => Some(e),
            _ => None,
        }
    }

    #[must_use]
    pub fn module_entry(&self, name: TypeName) -> Option<ModuleLookup<'_>> {
        match self.constant_entry(name)? {
            ConstantLookup::ClassDecl(ClassDeclEntry::Module(e)) => Some(ModuleLookup::Module(e)),
            ConstantLookup::ModuleAlias(e) => Some(ModuleLookup::ModuleAlias(e)),
            _ => None,
        }
    }

    #[must_use]
    pub fn constant_entry(&self, name: TypeName) -> Option<ConstantLookup<'_>> {
        if let Some(e) = self.class_decls.get(&name) {
            return Some(ConstantLookup::ClassDecl(e));
        }
        match self.class_alias_decls.get(&name) {
            Some(AliasEntry::Module(e)) => return Some(ConstantLookup::ModuleAlias(e)),
            None => {}
        }
        self.constant_decls.get(&name).map(ConstantLookup::Constant)
    }

    #[must_use]
    pub fn is_constant_decl(&self, name: TypeName) -> bool {
        self.constant_decls.contains_key(&name)
    }

    #[must_use]
    pub fn is_constant_name(&self, name: TypeName) -> bool {
        self.is_constant_decl(name) || self.is_module_name(name)
    }

    pub fn constant_entries(&self) -> impl Iterator<Item = &SingleEntry> {
        self.constant_decls.values()
    }

    pub fn class_entries(&self) -> impl Iterator<Item = &ClassDeclEntry> {
        self.class_decls.values()
    }

    #[must_use]
    pub fn is_interface_name(&self, name: TypeName) -> bool {
        self.interface_decls.contains_key(&name)
    }

    #[must_use]
    pub fn interface_entry(&self, name: TypeName) -> Option<&SingleEntry> {
        self.interface_decls.get(&name)
    }

    /// In insertion order, like iterating Ruby's `interface_decls`.
    pub fn interface_entries(&self) -> impl Iterator<Item = &SingleEntry> {
        self.interface_decls.values()
    }

    #[must_use]
    pub fn is_type_alias_name(&self, name: TypeName) -> bool {
        self.type_alias_decls.contains_key(&name)
    }

    #[must_use]
    pub fn type_alias_entry(&self, name: TypeName) -> Option<&SingleEntry> {
        self.type_alias_decls.get(&name)
    }

    pub fn type_alias_entries(&self) -> impl Iterator<Item = &SingleEntry> {
        self.type_alias_decls.values()
    }
}

impl Environment {
    #[must_use]
    pub fn is_global_name(&self, name: SymbolId) -> bool {
        self.global_decls.contains_key(&name)
    }

    #[must_use]
    pub fn global_entry(&self, name: SymbolId) -> Option<&SingleEntry<SymbolId>> {
        self.global_decls.get(&name)
    }

    pub fn global_entries(&self) -> impl Iterator<Item = &SingleEntry<SymbolId>> {
        self.global_decls.values()
    }
}

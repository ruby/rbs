use std::iter::{Chain, Copied, Once};
use std::marker::PhantomData;
use std::slice;

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

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub enum ClassDeclKind {
    Class,
    Module,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ClassTag;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ModuleTag;

pub type DeclIter<'a> = Chain<Once<DeclId>, Copied<slice::Iter<'a, DeclId>>>;

/// Ruby's `ClassEntry` and `ModuleEntry` differ only in `primary_decl`, so
/// they share one layout and the tag selects which `primary_decl` exists.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Entry<K> {
    name: TypeName,
    first: DeclId,
    rest: Vec<DeclId>,
    primary: DeclId,
    primary_has_super: bool,
    kind: PhantomData<K>,
}

pub type ClassEntry = Entry<ClassTag>;
pub type ModuleEntry = Entry<ModuleTag>;

impl<K> Entry<K> {
    pub(super) fn new(name: TypeName, first: DeclId, has_super: bool) -> Self {
        Self {
            name,
            first,
            rest: Vec::new(),
            primary: first,
            primary_has_super: has_super,
            kind: PhantomData,
        }
    }

    pub(super) fn push(&mut self, decl: DeclId, has_super: bool) {
        self.rest.push(decl);
        if has_super && !self.primary_has_super {
            self.primary = decl;
            self.primary_has_super = true;
        }
    }

    #[must_use]
    pub fn name(&self) -> TypeName {
        self.name
    }

    pub fn each_decl(&self) -> DeclIter<'_> {
        self.decls()
    }

    fn decls(&self) -> DeclIter<'_> {
        std::iter::once(self.first).chain(self.rest.iter().copied())
    }
}

impl Entry<ClassTag> {
    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        self.primary
    }
}

impl Entry<ModuleTag> {
    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        self.first
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
    pub(super) fn new(name: TypeName, kind: ClassDeclKind, first: DeclId, has_super: bool) -> Self {
        match kind {
            ClassDeclKind::Class => Self::Class(Entry::new(name, first, has_super)),
            ClassDeclKind::Module => Self::Module(Entry::new(name, first, false)),
        }
    }

    pub(super) fn push(&mut self, decl: DeclId, has_super: bool) {
        match self {
            Self::Class(e) => e.push(decl, has_super),
            Self::Module(e) => e.push(decl, false),
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

    pub fn each_decl(&self) -> DeclIter<'_> {
        self.decls()
    }

    fn decls(&self) -> DeclIter<'_> {
        match self {
            Self::Class(e) => e.decls(),
            Self::Module(e) => e.decls(),
        }
    }

    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        match self {
            Self::Class(e) => e.primary_decl(),
            Self::Module(e) => e.primary_decl(),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AliasEntry {
    Module(SingleEntry),
    Class(SingleEntry),
}

impl<N> SingleEntry<N> {
    fn decls(&self) -> DeclIter<'_> {
        std::iter::once(self.decl).chain([].iter().copied())
    }
}

/// Named `*Lookup` to stay apart from Ruby's `ConstantEntry`, which is the
/// `Constant` arm here.
#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ConstantLookup<'a> {
    ClassDecl(&'a ClassDeclEntry),
    ClassAlias(&'a SingleEntry),
    ModuleAlias(&'a SingleEntry),
    Constant(&'a SingleEntry),
}

impl<'a> ConstantLookup<'a> {
    pub fn each_decl(&self) -> DeclIter<'a> {
        match *self {
            Self::ClassDecl(e) => e.decls(),
            Self::ClassAlias(e) | Self::ModuleAlias(e) | Self::Constant(e) => e.decls(),
        }
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ClassLookup<'a> {
    Class(&'a ClassEntry),
    ClassAlias(&'a SingleEntry),
}

impl<'a> ClassLookup<'a> {
    #[must_use]
    pub fn name(&self) -> TypeName {
        match self {
            Self::Class(e) => e.name(),
            Self::ClassAlias(e) => e.name,
        }
    }

    pub fn each_decl(&self) -> DeclIter<'a> {
        match *self {
            Self::Class(e) => e.decls(),
            Self::ClassAlias(e) => e.decls(),
        }
    }

    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        match self {
            Self::Class(e) => e.primary_decl(),
            Self::ClassAlias(e) => e.decl,
        }
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ModuleClassLookup<'a> {
    ClassDecl(&'a ClassDeclEntry),
    ClassAlias(&'a SingleEntry),
    ModuleAlias(&'a SingleEntry),
}

impl<'a> ModuleClassLookup<'a> {
    #[must_use]
    pub fn name(&self) -> TypeName {
        match self {
            Self::ClassDecl(e) => e.name(),
            Self::ClassAlias(e) | Self::ModuleAlias(e) => e.name,
        }
    }

    pub fn each_decl(&self) -> DeclIter<'a> {
        match *self {
            Self::ClassDecl(e) => e.decls(),
            Self::ClassAlias(e) | Self::ModuleAlias(e) => e.decls(),
        }
    }

    #[must_use]
    pub fn primary_decl(&self) -> DeclId {
        match self {
            Self::ClassDecl(e) => e.primary_decl(),
            Self::ClassAlias(e) | Self::ModuleAlias(e) => e.decl,
        }
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub enum ModuleLookup<'a> {
    Module(&'a ModuleEntry),
    ModuleAlias(&'a SingleEntry),
}

impl<'a> ModuleLookup<'a> {
    #[must_use]
    pub fn name(&self) -> TypeName {
        match self {
            Self::Module(e) => e.name(),
            Self::ModuleAlias(e) => e.name,
        }
    }

    pub fn each_decl(&self) -> DeclIter<'a> {
        match *self {
            Self::Module(e) => e.decls(),
            Self::ModuleAlias(e) => e.decls(),
        }
    }

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
    pub fn is_class_alias(&self, name: TypeName) -> bool {
        matches!(
            self.class_alias_decls.get(&name),
            Some(AliasEntry::Class(_))
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

    #[must_use]
    pub fn class_entry(&self, name: TypeName) -> Option<ClassLookup<'_>> {
        match self.constant_entry(name)? {
            ConstantLookup::ClassDecl(ClassDeclEntry::Class(e)) => Some(ClassLookup::Class(e)),
            ConstantLookup::ClassAlias(e) => Some(ClassLookup::ClassAlias(e)),
            ConstantLookup::ClassDecl(ClassDeclEntry::Module(_))
            | ConstantLookup::ModuleAlias(_)
            | ConstantLookup::Constant(_) => None,
        }
    }

    #[must_use]
    pub fn module_entry(&self, name: TypeName) -> Option<ModuleLookup<'_>> {
        match self.constant_entry(name)? {
            ConstantLookup::ClassDecl(ClassDeclEntry::Module(e)) => Some(ModuleLookup::Module(e)),
            ConstantLookup::ModuleAlias(e) => Some(ModuleLookup::ModuleAlias(e)),
            ConstantLookup::ClassDecl(ClassDeclEntry::Class(_))
            | ConstantLookup::ClassAlias(_)
            | ConstantLookup::Constant(_) => None,
        }
    }

    #[must_use]
    pub fn module_class_entry(&self, name: TypeName) -> Option<ModuleClassLookup<'_>> {
        match self.constant_entry(name)? {
            ConstantLookup::ClassDecl(e) => Some(ModuleClassLookup::ClassDecl(e)),
            ConstantLookup::ClassAlias(e) => Some(ModuleClassLookup::ClassAlias(e)),
            ConstantLookup::ModuleAlias(e) => Some(ModuleClassLookup::ModuleAlias(e)),
            ConstantLookup::Constant(_) => None,
        }
    }

    #[must_use]
    pub fn constant_entry(&self, name: TypeName) -> Option<ConstantLookup<'_>> {
        if let Some(e) = self.class_decls.get(&name) {
            return Some(ConstantLookup::ClassDecl(e));
        }
        match self.class_alias_decls.get(&name) {
            Some(AliasEntry::Class(e)) => return Some(ConstantLookup::ClassAlias(e)),
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

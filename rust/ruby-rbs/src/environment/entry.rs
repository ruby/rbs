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

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ModuleEntry {
    name: TypeName,
    decls: Vec<DeclId>,
}

impl ModuleEntry {
    pub(super) fn new(name: TypeName) -> Self {
        Self {
            name,
            decls: Vec::new(),
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
        self.decls.iter().copied()
    }

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

impl Environment {
    #[must_use]
    pub fn is_module_decl(&self, name: TypeName) -> bool {
        self.class_decls.contains_key(&name)
    }

    #[must_use]
    pub fn is_module_name(&self, name: TypeName) -> bool {
        self.class_decls.contains_key(&name)
    }

    #[must_use]
    pub fn module_entry(&self, name: TypeName) -> Option<&ModuleEntry> {
        self.class_decls.get(&name)
    }

    pub fn class_entries(&self) -> impl Iterator<Item = &ModuleEntry> {
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

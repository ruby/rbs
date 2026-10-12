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

impl Environment {
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

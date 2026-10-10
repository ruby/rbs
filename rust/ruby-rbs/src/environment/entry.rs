use crate::ids::TypeName;

use super::{DeclId, Environment};

/// `name` repeats the table key, as in Ruby, so iterating entries alone
/// yields their names.
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
#[non_exhaustive]
pub struct SingleEntry {
    pub name: TypeName,
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
}

use crate::ast::Declaration;

use super::Environment;

/// Only valid against the [`Environment`] that issued it.
///
/// Only top-level declarations are registered for now, so an id is just the
/// declaration's position in `sources`.
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub struct DeclId {
    pub(super) source: u32,
    pub(super) index: u32,
}

impl Environment {
    /// # Panics
    ///
    /// May panic if `id` was issued by a different `Environment`.
    #[must_use]
    pub fn decl(&self, id: DeclId) -> &Declaration {
        &self.sources[id.source as usize].declarations[id.index as usize]
    }
}

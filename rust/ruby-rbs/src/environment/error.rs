use std::fmt;
use std::path::PathBuf;

use crate::ast::location::LocationRange;

#[derive(Debug, Clone, PartialEq, Eq)]
#[non_exhaustive]
pub struct DuplicatedDecl {
    pub path: PathBuf,
    pub location: Option<LocationRange>,
}

/// Owns rendered data instead of `DeclId`s because it outlives the
/// `Environment` (`Environment::from_loader` drops it on error).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DuplicatedDeclarationError {
    name: String,
    decls: Vec<DuplicatedDecl>,
}

impl DuplicatedDeclarationError {
    pub(crate) fn new(
        name: String,
        inserted: DuplicatedDecl,
        first_existing: DuplicatedDecl,
        rest: impl IntoIterator<Item = DuplicatedDecl>,
    ) -> Self {
        let decls = [inserted, first_existing].into_iter().chain(rest).collect();
        Self { name, decls }
    }

    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }

    /// The newly inserted declaration first, then the existing ones, as in
    /// Ruby. Always at least two; a slice because Ruby's error takes
    /// `*decls`, so a constant clashing with a class reports every reopening.
    #[must_use]
    pub fn decls(&self) -> &[DuplicatedDecl] {
        &self.decls
    }
}

impl fmt::Display for DuplicatedDeclarationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Ruby's nil-location fallback: line:col needs the source text, which
        // `Source` does not keep yet, and path alone matches no Ruby format.
        // TODO: render `decls.last()` as `path:line:col...line:col`.
        write!(f, "*:*:*...*:*: Duplicated declaration: {}", self.name)
    }
}

impl std::error::Error for DuplicatedDeclarationError {}

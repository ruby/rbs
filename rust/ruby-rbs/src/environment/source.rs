use std::path::PathBuf;

use crate::ast::{Declaration, Directive};
use crate::buffer::Buffer;

/// Where a loaded signature file came from, corresponding to the `source`
/// values yielded by `RBS::EnvironmentLoader#each_dir`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    Core,
    /// `path` is the library's version directory, already resolved by the
    /// caller (Ruby's `Repository#lookup` / `gem_sig_path`), holding the
    /// library's RBS files directly.
    Library {
        name: String,
        path: PathBuf,
    },
    Dir {
        path: PathBuf,
    },
}

impl SourceKind {
    /// Whether `_`-prefixed subdirectories are skipped while scanning.
    /// Only a user-specified [`SourceKind::Dir`] does not skip them.
    pub fn skips_hidden(&self) -> bool {
        !matches!(self, SourceKind::Dir { .. })
    }
}

/// `RBS::Source::RBS` equivalent.
#[derive(Debug)]
pub struct Source {
    pub buffer: Buffer,
    pub directives: Vec<Directive>,
    pub declarations: Vec<Declaration>,
    pub kind: SourceKind,
}

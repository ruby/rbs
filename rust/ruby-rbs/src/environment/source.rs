use std::path::PathBuf;

use crate::ast::{Declaration, Directive};

/// Corresponds to the `source` values yielded by
/// `RBS::EnvironmentLoader#each_dir`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    Core,
    /// `path` is the library's version directory, already resolved by the
    /// caller (Ruby's `Repository#lookup` / `gem_sig_path`), holding the
    /// library's RBS files directly. Version alone could not recover where a
    /// library's signatures came from; the path can.
    Library {
        name: String,
        path: PathBuf,
    },
    Dir {
        path: PathBuf,
    },
}

impl SourceKind {
    pub(crate) fn skips_hidden(&self) -> bool {
        !matches!(self, SourceKind::Dir { .. })
    }
}

#[derive(Debug)]
pub struct Source {
    pub path: PathBuf,
    pub directives: Vec<Directive>,
    pub declarations: Vec<Declaration>,
    pub kind: SourceKind,
}

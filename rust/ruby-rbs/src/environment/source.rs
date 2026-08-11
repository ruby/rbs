use std::path::PathBuf;

use crate::ast::{Declaration, Directive};
use crate::buffer::Buffer;

/// Where a loaded signature file came from, corresponding to the `source`
/// values yielded by `RBS::EnvironmentLoader#each_dir`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    /// Core library signatures (`:core` in Ruby).
    Core,
    /// A library resolved through the repository.
    ///
    /// `path` is the resolved version directory
    /// ([`Repository::lookup`](crate::repository::Repository::lookup)), which
    /// holds the library's RBS files directly.
    Library { name: String, path: PathBuf },
    /// An explicitly added signature directory.
    Dir { path: PathBuf },
}

/// A parsed signature file: its buffer, `use` directives, and declarations
/// (`RBS::Source::RBS` equivalent).
#[derive(Debug)]
pub struct Source {
    pub buffer: Buffer,
    pub directives: Vec<Directive>,
    pub declarations: Vec<Declaration>,
    pub kind: SourceKind,
}

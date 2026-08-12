use std::path::PathBuf;

use crate::ast::{Declaration, Directive};
use crate::buffer::Buffer;

/// Where a loaded signature file came from, corresponding to the `source`
/// values yielded by `RBS::EnvironmentLoader#each_dir`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    Core,
    /// `path` is the resolved version directory
    /// ([`Repository::lookup`](crate::repository::Repository::lookup)), which
    /// holds the library's RBS files directly.
    Library {
        name: String,
        path: PathBuf,
    },
    Dir {
        path: PathBuf,
    },
}

/// `RBS::Source::RBS` equivalent.
#[derive(Debug)]
pub struct Source {
    pub buffer: Buffer,
    pub directives: Vec<Directive>,
    pub declarations: Vec<Declaration>,
    pub kind: SourceKind,
}

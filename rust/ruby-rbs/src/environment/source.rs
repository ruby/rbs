use std::path::PathBuf;

use crate::ast::{Declaration, Directive};
use crate::buffer::Buffer;

/// Where a loaded signature file came from, corresponding to the `source`
/// values yielded by `RBS::EnvironmentLoader#each_dir`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SourceKind {
    /// Core library signatures (`:core` in Ruby).
    Core,
    /// A library resolved through the repository or a `GemSigResolver`.
    ///
    /// Carries the requested version as well as the name: Ruby keys its
    /// library set on the `(name, version)` pair, so `uri` and `uri` 1.0 are
    /// distinct entries yielded separately by `each_dir`.
    Library {
        name: String,
        version: Option<String>,
    },
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

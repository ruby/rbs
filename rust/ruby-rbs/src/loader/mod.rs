use std::collections::HashSet;
use std::fmt;
use std::io;
use std::path::{Path, PathBuf};

use crate::ast::AstConverter;
use crate::buffer::Buffer;
use crate::environment::{Environment, Source, SourceKind};
use crate::file_finder;
use crate::interners::Interners;
use crate::node;

#[derive(Debug)]
#[non_exhaustive]
pub enum LoadError {
    Io { path: PathBuf, source: io::Error },
    Parse { path: PathBuf, message: String },
}

impl fmt::Display for LoadError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LoadError::Io { path, source } => {
                write!(f, "IO error on {}: {}", path.display(), source)
            }
            LoadError::Parse { path, message } => {
                write!(f, "Syntax error in {}: {}", path.display(), message)
            }
        }
    }
}

impl std::error::Error for LoadError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            LoadError::Io { source, .. } => Some(source),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadedFile {
    pub path: PathBuf,
    pub kind: SourceKind,
}

/// Enumerates core, library, and explicit signature directories, parses
/// every `.rbs` file exactly once, and feeds the results into an
/// [`Environment`], mirroring `RBS::EnvironmentLoader`.
///
/// Unlike the Ruby implementation, this does not resolve gem names or
/// versions to directories, and does not expand `manifest.yaml`
/// dependencies: callers (Ruby's `Repository#lookup` / `gem_sig_path`) pass
/// already-resolved paths to [`EnvironmentLoader::add_library`]. Loading
/// core does not implicitly add `stringio` either — that dependency is the
/// caller's responsibility, same as any other library.
pub struct EnvironmentLoader {
    core_root: Option<PathBuf>,
    libs: Vec<(String, PathBuf)>,
    dirs: Vec<PathBuf>,
}

impl EnvironmentLoader {
    /// `core_root` is `None` to skip core.
    pub fn new(core_root: Option<PathBuf>) -> Self {
        EnvironmentLoader {
            core_root,
            libs: Vec::new(),
            dirs: Vec::new(),
        }
    }

    /// Adds a library by name and its already-resolved signature directory.
    pub fn add_library(mut self, name: &str, path: PathBuf) -> Self {
        self.libs.push((name.to_string(), path));
        self
    }

    /// Adds an explicit signature directory. Unlike libraries, `_`-prefixed
    /// subdirectories are not skipped.
    pub fn add_dir(mut self, path: PathBuf) -> Self {
        self.dirs.push(path);
        self
    }

    /// On `Err` the sources read before the failure are already in `env`, same
    /// as the Ruby implementation adding sources as it walks the directories.
    pub fn load(&self, env: &mut Environment) -> Result<Vec<LoadedFile>, LoadError> {
        let mut loaded = Vec::new();
        let mut seen_files: HashSet<PathBuf> = HashSet::new();

        for (kind, dir) in self.each_dir() {
            let files = file_finder::each_file(&dir, kind.skips_hidden()).map_err(|source| {
                LoadError::Io {
                    path: dir.clone(),
                    source,
                }
            })?;

            for path in files {
                if !seen_files.insert(path.clone()) {
                    continue;
                }
                let source = parse_one(&path, &kind, env.interners_mut())?;
                env.add_source(source);
                loaded.push(LoadedFile {
                    path,
                    kind: kind.clone(),
                });
            }
        }

        Ok(loaded)
    }

    /// Groups directories core → libs → dirs, matching
    /// `RBS::EnvironmentLoader#each_dir`'s enumeration order.
    fn each_dir(&self) -> Vec<(SourceKind, PathBuf)> {
        let mut result = Vec::new();

        if let Some(core) = &self.core_root {
            result.push((SourceKind::Core, core.clone()));
        }

        for (name, path) in &self.libs {
            result.push((
                SourceKind::Library {
                    name: name.clone(),
                    path: path.clone(),
                },
                path.clone(),
            ));
        }

        for dir in &self.dirs {
            result.push((SourceKind::Dir { path: dir.clone() }, dir.clone()));
        }

        result
    }
}

/// Deliberately a free function taking only the interners, so the load loop
/// can later be parallelised by handing each worker its own [`Interners`].
/// The parser's `SignatureNode` holds raw pointers and is not `Send`, so it
/// must not escape this function — only the owned `Source` does.
///
/// Crate-private: a caller outside the crate has no way to merge its
/// worker-local [`Interners`] into the environment, so the `Source` it
/// produced would carry ids that environment cannot resolve.
pub(crate) fn parse_one(
    path: &Path,
    kind: &SourceKind,
    interners: &mut Interners,
) -> Result<Source, LoadError> {
    let content = std::fs::read_to_string(path).map_err(|source| LoadError::Io {
        path: path.to_path_buf(),
        source,
    })?;

    let signature = node::parse(&content).map_err(|message| LoadError::Parse {
        path: path.to_path_buf(),
        message,
    })?;

    let mut converter = AstConverter::new(&mut interners.strings, &mut interners.type_names);
    let directives = signature
        .directives()
        .iter()
        .map(|node| converter.convert_directive(&node))
        .collect();
    let declarations = signature
        .declarations()
        .iter()
        .map(|node| converter.convert_declaration(&node))
        .collect();
    // SignatureNode borrows `content` and has a Drop impl; drop it
    // explicitly before moving `content` into the Buffer.
    drop(signature);

    Ok(Source {
        buffer: Buffer::new(path.to_path_buf(), content),
        directives,
        declarations,
        kind: kind.clone(),
    })
}

pub mod manifest;

use std::collections::HashSet;
use std::fmt;
use std::io;
use std::path::{Path, PathBuf};

use crate::ast::AstConverter;
use crate::buffer::Buffer;
use crate::environment::{Environment, Source, SourceKind};
use crate::file_finder;
use crate::gem_version::GemVersion;
use crate::interners::Interners;
use crate::node;
use crate::repository::Repository;

/// Errors raised while resolving and loading signature files,
/// mirroring `RBS::EnvironmentLoader::UnknownLibraryError` and friends.
#[derive(Debug)]
#[non_exhaustive]
pub enum LoadError {
    /// No signature directory was found for the library
    /// (`RBS::EnvironmentLoader::UnknownLibraryError`).
    UnknownLibrary {
        name: String,
        version: Option<String>,
    },
    /// A requested library version is not a valid `Gem::Version`, where the
    /// Ruby implementation raises `ArgumentError`.
    InvalidVersion {
        name: String,
        version: String,
    },
    Io {
        path: PathBuf,
        source: io::Error,
    },
    Parse {
        path: PathBuf,
        message: String,
    },
    Manifest {
        path: PathBuf,
        message: String,
    },
}

impl fmt::Display for LoadError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LoadError::UnknownLibrary { name, version } => write!(
                f,
                "Cannot find type definitions for library: {} ({})",
                name,
                version.as_deref().unwrap_or("[nil]")
            ),
            LoadError::InvalidVersion { name, version } => {
                write!(
                    f,
                    "Malformed version number string {version} for library {name}"
                )
            }
            LoadError::Io { path, source } => {
                write!(f, "IO error on {}: {}", path.display(), source)
            }
            LoadError::Parse { path, message } => {
                write!(f, "Syntax error in {}: {}", path.display(), message)
            }
            LoadError::Manifest { path, message } => {
                write!(f, "Invalid manifest {}: {}", path.display(), message)
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

/// A library requested by name and optional version
/// (`RBS::EnvironmentLoader::Library` equivalent).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Library {
    pub name: String,
    pub version: Option<String>,
}

/// A file loaded by [`EnvironmentLoader::load`], in load order.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadedFile {
    pub path: PathBuf,
    pub kind: SourceKind,
}

/// Resolves core, library, and explicit signature directories, parses every
/// `.rbs` file exactly once, and feeds the results into an [`Environment`],
/// mirroring `RBS::EnvironmentLoader`.
pub struct EnvironmentLoader {
    core_root: Option<PathBuf>,
    stdlib_root: Option<PathBuf>,
    repository_dirs: Vec<PathBuf>,
    libs: Vec<Library>,
    dirs: Vec<PathBuf>,
}

impl EnvironmentLoader {
    /// `core_root` is `None` to skip core; `stdlib_root` is the stdlib
    /// signature directory used for dependency expansion and for resolving
    /// requested libraries — `None` disables both.
    /// Both are required arguments, not builder defaults, so callers decide
    /// them explicitly instead of silently getting `None`.
    pub fn new(core_root: Option<PathBuf>, stdlib_root: Option<PathBuf>) -> Self {
        EnvironmentLoader {
            core_root,
            stdlib_root,
            repository_dirs: Vec::new(),
            libs: Vec::new(),
            dirs: Vec::new(),
        }
    }

    /// Adds a repository root for resolving libraries, searched after
    /// `stdlib_root`; a later root wins for the same gem and version.
    pub fn add_repository_dir(mut self, path: PathBuf) -> Self {
        self.repository_dirs.push(path);
        self
    }

    /// Requests a library. Its `manifest.yaml` dependencies are resolved
    /// transitively at load time.
    pub fn add_library(mut self, name: &str, version: Option<&str>) -> Self {
        self.libs.push(Library {
            name: name.to_string(),
            version: version.map(str::to_string),
        });
        self
    }

    /// Adds an explicit signature directory. Unlike libraries, `_`-prefixed
    /// subdirectories are not skipped.
    pub fn add_dir(mut self, path: PathBuf) -> Self {
        self.dirs.push(path);
        self
    }

    /// Loads every signature file into `env` and returns the loaded files in
    /// load order (`RBS::EnvironmentLoader#load` equivalent).
    ///
    /// On `Err` the sources read before the failure are already in `env`, same
    /// as the Ruby implementation adding sources as it walks the directories.
    pub fn load(&self, env: &mut Environment) -> Result<Vec<LoadedFile>, LoadError> {
        let stdlib = self.stdlib_repository()?;
        let repository = self.loading_repository()?;

        let mut loaded = Vec::new();
        let mut seen_files: HashSet<PathBuf> = HashSet::new();

        for (kind, dir, skip_hidden) in self.each_dir(&stdlib, &repository)? {
            let files =
                file_finder::each_file(&dir, skip_hidden).map_err(|source| LoadError::Io {
                    path: dir.clone(),
                    source,
                })?;

            for path in files {
                if !seen_files.insert(path.clone()) {
                    continue;
                }
                // `parse_one` is a free function so this loop can later be
                // spread over worker threads with worker-local `Interners`;
                // `add_source` stays in file order.
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

    /// Resolves directories in the Ruby implementation's order:
    /// core, then libraries (with dependencies), then explicit directories.
    fn each_dir(
        &self,
        stdlib: &Repository,
        repository: &Repository,
    ) -> Result<Vec<(SourceKind, PathBuf, bool)>, LoadError> {
        let mut result = Vec::new();

        if let Some(core) = &self.core_root {
            result.push((SourceKind::Core, core.clone(), true));
        }

        for library in self.resolved_libraries(stdlib)? {
            let dir =
                library_dir(repository, &library).ok_or_else(|| LoadError::UnknownLibrary {
                    name: library.name.clone(),
                    version: library.version.clone(),
                })?;
            let kind = SourceKind::Library {
                name: library.name,
                path: dir.clone(),
            };
            result.push((kind, dir, true));
        }

        for dir in &self.dirs {
            result.push((SourceKind::Dir { path: dir.clone() }, dir.clone(), false));
        }

        Ok(result)
    }

    /// The repository backing dependency expansion, mirroring
    /// `Collection::Sources::Stdlib`'s dedicated repository. Built from
    /// `stdlib_root` on each load; independent of the loading repository.
    fn stdlib_repository(&self) -> Result<Repository, LoadError> {
        let mut repository = Repository::new();
        if let Some(root) = &self.stdlib_root {
            repository.add(root).map_err(|source| LoadError::Io {
                path: root.clone(),
                source,
            })?;
        }
        Ok(repository)
    }

    /// `stdlib_root` is registered first, standing in for Ruby's
    /// `Repository.new` auto-registering `DEFAULT_STDLIB_ROOT`.
    fn loading_repository(&self) -> Result<Repository, LoadError> {
        let mut repository = Repository::new();
        if let Some(root) = &self.stdlib_root {
            repository.add(root).map_err(|source| LoadError::Io {
                path: root.clone(),
                source,
            })?;
        }
        for dir in &self.repository_dirs {
            repository.add(dir).map_err(|source| LoadError::Io {
                path: dir.clone(),
                source,
            })?;
        }
        Ok(repository)
    }

    /// Expands manifest dependencies depth-first in request order, matching
    /// the Ruby implementation's insertion-ordered `Set` of libraries.
    fn resolved_libraries(&self, stdlib: &Repository) -> Result<Vec<Library>, LoadError> {
        let mut seen: HashSet<Library> = HashSet::new();
        let mut result = Vec::new();

        for library in &self.libs {
            self.add_library_recursive(library.clone(), stdlib, &mut seen, &mut result)?;
        }

        // Loading core implies stringio (stdlib migration), unconditionally,
        // same as Ruby; an unresolvable stringio is an UnknownLibrary error.
        if self.core_root.is_some() && !seen.iter().any(|library| library.name == "stringio") {
            let stringio = Library {
                name: "stringio".to_string(),
                version: None,
            };
            self.add_library_recursive(stringio, stdlib, &mut seen, &mut result)?;
        }

        Ok(result)
    }

    fn add_library_recursive(
        &self,
        library: Library,
        stdlib: &Repository,
        seen: &mut HashSet<Library>,
        result: &mut Vec<Library>,
    ) -> Result<(), LoadError> {
        if let Some(version) = &library.version {
            // Ruby raises ArgumentError from Gem::Version/Gem::Requirement
            // while resolving; fail before any lookup can misinterpret it.
            if GemVersion::parse(version).is_none() {
                return Err(LoadError::InvalidVersion {
                    name: library.name.clone(),
                    version: version.clone(),
                });
            }
        }

        if !seen.insert(library.clone()) {
            return Ok(());
        }
        result.push(library.clone());

        // Mirrors Ruby's resolve_dependencies: the stdlib repository is
        // consulted, not the loading repository, so a library that only
        // exists in a custom repository loads without dependency expansion,
        // same as Ruby.
        let dependency_dir = stdlib
            .lookup(&library.name, library.version.as_deref())
            .map(Path::to_path_buf);
        if let Some(dir) = dependency_dir {
            for name in manifest::dependencies(&dir)? {
                self.add_library_recursive(
                    Library {
                        name,
                        version: None,
                    },
                    stdlib,
                    seen,
                    result,
                )?;
            }
        }

        Ok(())
    }
}

fn library_dir(repository: &Repository, library: &Library) -> Option<PathBuf> {
    repository
        .lookup(&library.name, library.version.as_deref())
        .map(Path::to_path_buf)
}

/// Reads, parses, and converts a single signature file into an owned
/// [`Source`].
///
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

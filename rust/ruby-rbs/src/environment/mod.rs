pub mod source;

pub use source::{Source, SourceKind};

use std::path::{Path, PathBuf};

use crate::ast::AstConverter;
use crate::buffer::Buffer;
use crate::interners::Interners;
use crate::loader::{EnvironmentLoader, LoadError};
use crate::node;

/// Owning the interners here gives a single `Environment` value the same
/// role as the Ruby implementation's global name pool: names interned while
/// loading stay resolvable and displayable for the environment's lifetime.
pub struct Environment {
    interners: Interners,
    sources: Vec<Source>,
}

impl Environment {
    pub fn new() -> Self {
        Environment {
            interners: Interners::new(),
            sources: Vec::new(),
        }
    }

    pub fn interners(&self) -> &Interners {
        &self.interners
    }

    pub fn sources(&self) -> &[Source] {
        &self.sources
    }

    /// Parses `content` with this environment's own [`Interners`] and adds it
    /// as a source, without going through an [`EnvironmentLoader`] — the
    /// entry point for editor / in-memory callers (`RBS::Environment#add_source`
    /// equivalent, e.g. Steep). Parsing always uses this environment's
    /// `Interners`, so a `Source` added this way can never carry ids from a
    /// different environment.
    pub fn add_rbs(
        &mut self,
        path: PathBuf,
        content: String,
        kind: SourceKind,
    ) -> Result<(), LoadError> {
        let signature = node::parse(&content).map_err(|message| LoadError::Parse {
            path: path.clone(),
            message,
        })?;

        let mut converter =
            AstConverter::new(&mut self.interners.strings, &mut self.interners.type_names);
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

        self.sources.push(Source {
            buffer: Buffer::new(path, content),
            directives,
            declarations,
            kind,
        });
        Ok(())
    }

    /// Reads `path` and adds it as a source; a thin wrapper around
    /// [`Environment::add_rbs`].
    pub fn add_rbs_file(&mut self, path: &Path, kind: SourceKind) -> Result<(), LoadError> {
        let content = std::fs::read_to_string(path).map_err(|source| LoadError::Io {
            path: path.to_path_buf(),
            source,
        })?;
        self.add_rbs(path.to_path_buf(), content, kind)
    }

    pub fn from_loader(loader: &EnvironmentLoader) -> Result<Environment, LoadError> {
        let mut env = Environment::new();
        loader.load(&mut env)?;
        Ok(env)
    }
}

impl Default for Environment {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ast::Declaration;

    #[test]
    fn environment_owns_interners() {
        let mut env = Environment::new();
        env.add_rbs(
            PathBuf::from("test.rbs"),
            "class Foo\nend\n".to_string(),
            SourceKind::Dir {
                path: PathBuf::from("."),
            },
        )
        .unwrap();

        let [Declaration::Class(class)] = env.sources()[0].declarations.as_slice() else {
            panic!("expected one class declaration");
        };
        let interners = env.interners();
        assert_eq!(
            interners.type_names.display(class.name, &interners.strings),
            "Foo"
        );
    }
}

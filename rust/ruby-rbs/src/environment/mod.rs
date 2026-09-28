pub mod source;

pub use source::{Source, SourceKind};

use crate::interners::Interners;
use crate::loader::{EnvironmentLoader, LoadError};

/// Owning the interners here gives a single `Environment` value the same
/// role as the Ruby implementation's global name pool: names interned while
/// loading stay resolvable and displayable for the environment's lifetime.
#[derive(Default)]
pub struct Environment {
    interners: Interners,
    sources: Vec<Source>,
}

impl Environment {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    pub fn interners(&self) -> &Interners {
        &self.interners
    }

    pub fn sources(&self) -> &[Source] {
        &self.sources
    }

    pub(crate) fn interners_mut(&mut self) -> &mut Interners {
        &mut self.interners
    }

    pub(crate) fn add_source(&mut self, source: Source) {
        self.sources.push(source);
    }

    pub fn from_loader(loader: &EnvironmentLoader) -> Result<Environment, LoadError> {
        let mut env = Environment::new();
        loader.load(&mut env)?;
        Ok(env)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn environment_owns_interners() {
        let mut env = Environment::new();

        let interners = env.interners_mut();
        let symbol = interners.strings.intern("Foo");
        let root = interners.type_names.absolute_root();
        let name = interners.type_names.append(root, symbol);

        let interners = env.interners();
        assert_eq!(
            interners.type_names.display(name, &interners.strings),
            "::Foo"
        );
        assert!(env.sources().is_empty());
    }
}

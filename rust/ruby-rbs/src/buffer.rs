use std::path::{Path, PathBuf};

/// A signature file's content, mirroring `RBS::Buffer`.
#[derive(Debug, Clone)]
pub struct Buffer {
    name: PathBuf,
    content: String,
}

impl Buffer {
    pub fn new(name: PathBuf, content: String) -> Self {
        Self { name, content }
    }

    pub fn name(&self) -> &Path {
        &self.name
    }

    pub fn content(&self) -> &str {
        &self.content
    }
}

use std::path::PathBuf;

/// Resolves the `sig/` directory of an installed gem.
///
/// The Ruby implementation asks `Gem::Specification`; Rust tools inject their
/// own strategy here (spawning Ruby, reading a cache, ...). The default
/// [`NoGemSigs`] never finds anything, so only the repository is consulted.
///
/// Implementations must be `Send + Sync`. Loading is planned to run its parse
/// stage on worker threads, which requires the loader holding this resolver to
/// be `Sync`; a supertrait cannot be added later without breaking downstream
/// implementations, so the bound is here from the start.
pub trait GemSigResolver: Send + Sync {
    /// Returns the path to the gem's `sig/` directory, or `None` when the gem
    /// is not installed or does not ship signatures.
    fn sig_path(&self, name: &str, version: Option<&str>) -> Option<PathBuf>;
}

/// Default resolver that never finds installed gems.
#[derive(Debug, Clone, Copy, Default)]
pub struct NoGemSigs;

impl GemSigResolver for NoGemSigs {
    fn sig_path(&self, _name: &str, _version: Option<&str>) -> Option<PathBuf> {
        None
    }
}

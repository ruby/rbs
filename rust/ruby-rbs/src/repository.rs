use std::collections::{BTreeMap, HashMap};
use std::io;
use std::path::{Path, PathBuf};

use crate::gem_version::GemVersion;

/// An index of versioned RBS directories laid out as `{dir}/{gem}/{version}/`,
/// mirroring `RBS::Repository`.
///
/// Unlike the Ruby implementation, no default stdlib directory is registered;
/// callers add repository roots explicitly via [`Repository::add`].
#[derive(Debug, Default)]
pub struct Repository {
    dirs: Vec<PathBuf>,
    gems: HashMap<String, GemRbs>,
}

#[derive(Debug, Default)]
struct GemRbs {
    /// Keyed by the raw version directory name: Ruby's versions hash uses
    /// `Gem::Version` string equality, keeping `1.0` and `1.0.0` distinct.
    versions: BTreeMap<String, VersionPath>,
}

#[derive(Debug)]
struct VersionPath {
    version: GemVersion,
    path: PathBuf,
}

impl Repository {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn dirs(&self) -> &[PathBuf] {
        &self.dirs
    }

    pub fn add(&mut self, dir: &Path) -> io::Result<()> {
        self.dirs.push(dir.to_path_buf());

        for gem_entry in std::fs::read_dir(dir)? {
            let gem_entry = gem_entry?;
            if !gem_entry.path().is_dir() {
                continue;
            }

            let gem_name = gem_entry.file_name().to_string_lossy().into_owned();
            let gem = self.gems.entry(gem_name).or_default();

            for version_entry in std::fs::read_dir(gem_entry.path())? {
                let version_entry = version_entry?;
                let name = version_entry.file_name().to_string_lossy().into_owned();
                let Some(version) = GemVersion::parse(&name) else {
                    continue;
                };
                if version.is_prerelease() {
                    continue;
                }
                gem.versions.insert(
                    name,
                    VersionPath {
                        version,
                        path: version_entry.path(),
                    },
                );
            }
        }

        Ok(())
    }

    /// Returns the signature directory for `gem`, choosing the newest version
    /// `<= version`, or, when `version` is `None`, the version whose *name
    /// string* sorts last — Ruby's `latest_version` sorts by the version
    /// string, so `1.2` beats `1.11`.
    ///
    /// Takes an already-parsed `GemVersion` rather than a raw string: an
    /// invalid version string is a caller error (Ruby raises `ArgumentError`
    /// resolving it), not a "not found" result, so it must be rejected
    /// before it can reach `lookup` at all.
    pub fn lookup(&self, gem: &str, version: Option<&GemVersion>) -> Option<&Path> {
        let gem = self.gems.get(gem)?;
        if gem.versions.is_empty() {
            return None;
        }

        match version {
            Some(requested) => find_best_version(&gem.versions, &requested.release()),
            None => gem
                .versions
                .last_key_value()
                .map(|(_, vp)| vp.path.as_path()),
        }
    }
}

/// Returns the semantically newest version that is `<= requested`, or the
/// semantically oldest one when every candidate is newer
/// (`RBS::Repository.find_best_version` compatible). Versions that compare
/// equal (`1.0` vs `1.0.0`) tie-break deterministically on the string-wise
/// last key; Ruby's unstable sort leaves that case unspecified.
fn find_best_version<'a>(
    versions: &'a BTreeMap<String, VersionPath>,
    requested: &GemVersion,
) -> Option<&'a Path> {
    versions
        .values()
        .filter(|vp| vp.version <= *requested)
        .max_by(|a, b| a.version.cmp(&b.version))
        .or_else(|| versions.values().min_by(|a, b| a.version.cmp(&b.version)))
        .map(|vp| vp.path.as_path())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    fn fixture(entries: &[&str]) -> tempfile::TempDir {
        let dir = tempfile::tempdir().unwrap();
        for entry in entries {
            fs::create_dir_all(dir.path().join(entry)).unwrap();
        }
        dir
    }

    fn lookup_name(repository: &Repository, gem: &str, version: Option<&str>) -> Option<String> {
        let version = version.map(|v| GemVersion::parse(v).unwrap());
        repository
            .lookup(gem, version.as_ref())
            .map(|path| path.file_name().unwrap().to_string_lossy().into_owned())
    }

    #[test]
    fn lookup_returns_latest_version_without_request() {
        let dir = fixture(&["uri/0", "uri/1.0", "csv/2.0", "csv/3.0.pre"]);
        let mut repository = Repository::new();
        repository.add(dir.path()).unwrap();

        assert_eq!(
            lookup_name(&repository, "uri", None),
            Some("1.0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "csv", None),
            Some("2.0".to_string())
        );
        assert_eq!(repository.lookup("no_such_gem", None), None);
    }

    #[test]
    fn lookup_finds_best_version() {
        let dir = fixture(&["uri/0", "uri/1.0", "uri/2.0"]);
        let mut repository = Repository::new();
        repository.add(dir.path()).unwrap();

        assert_eq!(
            lookup_name(&repository, "uri", Some("1.5")),
            Some("1.0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", Some("1.0")),
            Some("1.0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", Some("3.0")),
            Some("2.0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", Some("0.0.1")),
            Some("0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", Some("1.0.pre")),
            Some("1.0".to_string())
        );
    }

    #[test]
    fn non_version_directories_are_ignored() {
        let dir = fixture(&["uri/not_a_version", "uri/1.0"]);
        let mut repository = Repository::new();
        repository.add(dir.path()).unwrap();

        assert_eq!(
            lookup_name(&repository, "uri", None),
            Some("1.0".to_string())
        );
    }

    #[test]
    fn later_add_overwrites_same_version() {
        let dir1 = fixture(&["uri/1.0"]);
        let dir2 = fixture(&["uri/1.0"]);
        let mut repository = Repository::new();
        repository.add(dir1.path()).unwrap();
        repository.add(dir2.path()).unwrap();

        let path = repository.lookup("uri", None).unwrap();
        assert!(path.starts_with(dir2.path()));
        assert_eq!(repository.dirs().len(), 2);
    }

    #[test]
    fn lookup_without_version_uses_string_order() {
        let dir = fixture(&["uri/1.2", "uri/1.11"]);
        let mut repository = Repository::new();
        repository.add(dir.path()).unwrap();

        assert_eq!(
            lookup_name(&repository, "uri", None),
            Some("1.2".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", Some("99")),
            Some("1.11".to_string())
        );
    }

    #[test]
    fn equal_versions_with_different_spellings_stay_distinct() {
        let dir = fixture(&["uri/1.0", "uri/1.0.0"]);
        let mut repository = Repository::new();
        repository.add(dir.path()).unwrap();

        assert_eq!(
            lookup_name(&repository, "uri", Some("1.0")),
            Some("1.0.0".to_string())
        );
        assert_eq!(
            lookup_name(&repository, "uri", None),
            Some("1.0.0".to_string())
        );
    }
}

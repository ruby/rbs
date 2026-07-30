use std::io;
use std::path::{Path, PathBuf};

/// Enumerates `.rbs` entries under `path` in a deterministic (path-sorted)
/// order, mirroring `RBS::FileFinder.each_file` and its `Dir.glob`
/// semantics: entries whose name starts with `.` are neither listed nor
/// descended into, symlinked directories are not descended into, and any
/// entry named `*.rbs` is listed regardless of its file type.
///
/// When `path` is a file it is returned as-is. When `skip_hidden` is true,
/// entries under a directory whose name starts with `_` are skipped; the
/// entry's own name is not checked, same as the Ruby implementation.
///
/// One divergence: Ruby sorts the `/`-joined strings `Dir.glob` returns, while
/// the sort here compares the platform separator. The two agree except on
/// Windows for names containing a character below `/`.
pub fn each_file(path: &Path, skip_hidden: bool) -> io::Result<Vec<PathBuf>> {
    let mut files = Vec::new();

    if path.is_file() {
        files.push(path.to_path_buf());
    } else if path.is_dir() {
        collect(path, skip_hidden, &mut files)?;
        files.sort_by(|a, b| a.as_os_str().cmp(b.as_os_str()));
    }

    Ok(files)
}

fn collect(dir: &Path, skip_hidden: bool, files: &mut Vec<PathBuf>) -> io::Result<()> {
    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();

        if entry.file_name().to_string_lossy().starts_with('.') {
            continue;
        }

        if path.extension().is_some_and(|ext| ext == "rbs") {
            files.push(path.clone());
        }

        // `file_type()` does not follow symlinks, so this naturally skips
        // symlinked directories.
        if entry.file_type()?.is_dir() {
            let hidden = path
                .file_name()
                .is_some_and(|name| name.to_string_lossy().starts_with('_'));
            if skip_hidden && hidden {
                continue;
            }
            collect(&path, skip_hidden, files)?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    fn fixture(files: &[&str]) -> tempfile::TempDir {
        let dir = tempfile::tempdir().unwrap();
        for file in files {
            let path = dir.path().join(file);
            fs::create_dir_all(path.parent().unwrap()).unwrap();
            fs::write(&path, "").unwrap();
        }
        dir
    }

    /// Paths relative to `root`, always `/`-joined so the expectations below
    /// read the same on Windows.
    fn relative(paths: Vec<PathBuf>, root: &Path) -> Vec<String> {
        paths
            .iter()
            .map(|path| {
                path.strip_prefix(root)
                    .unwrap()
                    .components()
                    .map(|component| component.as_os_str().to_string_lossy())
                    .collect::<Vec<_>>()
                    .join("/")
            })
            .collect()
    }

    #[test]
    fn returns_single_file_as_is() {
        let dir = fixture(&["a.txt"]);
        let file = dir.path().join("a.txt");
        assert_eq!(each_file(&file, true).unwrap(), vec![file]);
    }

    #[test]
    fn collects_rbs_files_sorted() {
        let dir = fixture(&["b.rbs", "a.rbs", "nested/c.rbs", "ignored.txt"]);
        let found = each_file(dir.path(), false).unwrap();
        assert_eq!(
            relative(found, dir.path()),
            vec!["a.rbs", "b.rbs", "nested/c.rbs"]
        );
    }

    #[test]
    fn skip_hidden_skips_underscore_directories_only() {
        let dir = fixture(&[
            "a.rbs",
            "_private/b.rbs",
            "nested/_private/c.rbs",
            "_top.rbs",
        ]);

        let found = each_file(dir.path(), true).unwrap();
        assert_eq!(relative(found, dir.path()), vec!["_top.rbs", "a.rbs"]);

        let found = each_file(dir.path(), false).unwrap();
        assert_eq!(
            relative(found, dir.path()),
            vec![
                "_private/b.rbs",
                "_top.rbs",
                "a.rbs",
                "nested/_private/c.rbs"
            ]
        );
    }

    #[test]
    fn missing_path_yields_nothing() {
        let dir = fixture(&[]);
        let found = each_file(&dir.path().join("no_such"), true).unwrap();
        assert!(found.is_empty());
    }

    #[cfg(unix)]
    #[test]
    fn symlinked_directories_are_not_traversed() {
        let dir = fixture(&["a.rbs", "real/b.rbs"]);
        std::os::unix::fs::symlink(dir.path().join("real"), dir.path().join("linked")).unwrap();

        let found = each_file(dir.path(), false).unwrap();
        assert_eq!(relative(found, dir.path()), vec!["a.rbs", "real/b.rbs"]);
    }

    #[test]
    fn dot_entries_are_neither_listed_nor_traversed() {
        let dir = fixture(&[".hidden.rbs", ".git/objects/x.rbs", "normal/ok.rbs"]);

        let found = each_file(dir.path(), false).unwrap();
        assert_eq!(relative(found, dir.path()), vec!["normal/ok.rbs"]);
    }

    #[test]
    fn entries_named_rbs_match_regardless_of_file_type() {
        let dir = fixture(&["dir.rbs/inner.rbs"]);

        let found = each_file(dir.path(), false).unwrap();
        assert_eq!(
            relative(found, dir.path()),
            vec!["dir.rbs", "dir.rbs/inner.rbs"]
        );
    }
}

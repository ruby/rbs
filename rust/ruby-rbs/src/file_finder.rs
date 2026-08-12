use std::io;
use std::path::{Path, PathBuf};

/// Enumerates `.rbs` entries under `path` in path-sorted order, mirroring
/// `RBS::FileFinder.each_file` and its `Dir.glob` semantics.
///
/// Divergences: the sort compares the platform separator rather than
/// `/`-joined strings, and only `PermissionDenied`/`NotFound` are skipped
/// where Ruby skips every open/stat failure.
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

fn is_skippable(error: &io::Error) -> bool {
    matches!(
        error.kind(),
        io::ErrorKind::PermissionDenied | io::ErrorKind::NotFound
    )
}

fn collect(dir: &Path, skip_hidden: bool, files: &mut Vec<PathBuf>) -> io::Result<()> {
    let entries = match std::fs::read_dir(dir) {
        Ok(entries) => entries,
        Err(error) if is_skippable(&error) => return Ok(()),
        Err(error) => return Err(error),
    };

    for entry in entries {
        let entry = match entry {
            Ok(entry) => entry,
            Err(error) if is_skippable(&error) => continue,
            Err(error) => return Err(error),
        };
        let path = entry.path();

        if entry.file_name().to_string_lossy().starts_with('.') {
            continue;
        }

        if path.extension().is_some_and(|ext| ext == "rbs") {
            files.push(path.clone());
        }

        // `file_type()` does not follow symlinks, which skips symlinked dirs.
        let file_type = match entry.file_type() {
            Ok(file_type) => file_type,
            Err(error) if is_skippable(&error) => continue,
            Err(error) => return Err(error),
        };
        if file_type.is_dir() {
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

    #[cfg(unix)]
    #[test]
    fn unreadable_directories_are_skipped() {
        use std::os::unix::fs::PermissionsExt;

        let dir = fixture(&["a.rbs", "readable/b.rbs", "locked/c.rbs"]);
        let locked = dir.path().join("locked");
        fs::set_permissions(&locked, fs::Permissions::from_mode(0o000)).unwrap();

        // Permission bits do not deny root (common in CI containers).
        if fs::read_dir(&locked).is_ok() {
            fs::set_permissions(&locked, fs::Permissions::from_mode(0o755)).unwrap();
            return;
        }

        let found = each_file(dir.path(), false);

        fs::set_permissions(&locked, fs::Permissions::from_mode(0o755)).unwrap();

        assert_eq!(
            relative(found.unwrap(), dir.path()),
            vec!["a.rbs", "readable/b.rbs"]
        );
    }

    #[cfg(unix)]
    #[test]
    fn unstattable_entries_are_skipped() {
        use std::os::unix::fs::PermissionsExt;

        let dir = fixture(&["a.rbs", "listable/b.rbs", "listable/nested/c.rbs"]);
        let listable = dir.path().join("listable");
        fs::set_permissions(&listable, fs::Permissions::from_mode(0o444)).unwrap();

        // Permission bits do not deny root (common in CI containers).
        if fs::metadata(listable.join("b.rbs")).is_ok() {
            fs::set_permissions(&listable, fs::Permissions::from_mode(0o755)).unwrap();
            return;
        }

        let found = each_file(dir.path(), false);

        fs::set_permissions(&listable, fs::Permissions::from_mode(0o755)).unwrap();

        // `b.rbs` is listed by name; `nested` cannot be identified as a dir.
        assert_eq!(
            relative(found.unwrap(), dir.path()),
            vec!["a.rbs", "listable/b.rbs"]
        );
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

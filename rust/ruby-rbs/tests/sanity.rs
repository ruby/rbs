use std::path::Path;

use ruby_rbs::node::parse;

fn collect_rbs_files(dir: &Path) -> Vec<std::path::PathBuf> {
    let mut files = Vec::new();

    for entry in std::fs::read_dir(dir).unwrap() {
        let entry = entry.unwrap();
        let path = entry.path();

        if path.is_dir() {
            files.extend(collect_rbs_files(&path));
        } else if path.extension().is_some_and(|ext| ext == "rbs") {
            files.push(path);
        }
    }

    files
}

#[test]
fn all_included_rbs_can_be_parsed() {
    let repo_root = Path::new(env!("CARGO_MANIFEST_DIR")).join("../..");
    let dirs = [repo_root.join("core"), repo_root.join("stdlib")];

    let mut files: Vec<_> = dirs.iter().flat_map(|d| collect_rbs_files(d)).collect();
    files.sort();
    assert!(!files.is_empty());

    let mut failures = Vec::new();

    for file in &files {
        let content = std::fs::read_to_string(file).unwrap();

        if let Err(e) = parse(&content) {
            failures.push(format!("{}: {}", file.display(), e));
        }
    }

    assert!(
        failures.is_empty(),
        "Failed to parse {} RBS file(s):\n{}",
        failures.len(),
        failures.join("\n")
    );
}

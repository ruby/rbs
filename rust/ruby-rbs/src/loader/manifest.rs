use std::path::Path;

use serde::Deserialize;

use super::LoadError;

/// Reads dependency library names from `manifest.yaml` directly under `dir`,
/// as used by stdlib and gem signature directories. Returns an empty list
/// when the file does not exist.
///
/// Reads exactly what Ruby reads — `manifest['dependencies'][*]['name']` —
/// and nothing else about the notation, so any YAML that `YAML.safe_load`
/// accepts is accepted here too.
///
/// Anything outside that is a [`LoadError::Manifest`] rather than silently
/// ignored: a gem's `sig/manifest.yaml` is written by a third party, and a
/// dropped dependency would otherwise surface much later as a confusing
/// missing-type error.
pub fn dependencies(dir: &Path) -> Result<Vec<String>, LoadError> {
    let path = dir.join("manifest.yaml");

    let content = match std::fs::read_to_string(&path) {
        Ok(content) => content,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(source) => return Err(LoadError::Io { path, source }),
    };

    parse(&content).map_err(|message| LoadError::Manifest { path, message })
}

#[derive(Deserialize, Default)]
struct Manifest {
    #[serde(default)]
    dependencies: Vec<Dependency>,
}

#[derive(Deserialize)]
struct Dependency {
    name: Option<String>,
}

fn parse(content: &str) -> Result<Vec<String>, String> {
    // An empty or all-comment file has no document; Ruby's YAML.safe_load
    // returns nil for it, which yields no dependencies.
    if content.trim().is_empty() {
        return Ok(Vec::new());
    }

    let manifest: Manifest = serde_yaml::from_str(content).map_err(|error| error.to_string())?;

    manifest
        .dependencies
        .into_iter()
        .enumerate()
        .map(|(index, dependency)| {
            dependency
                .name
                .filter(|name| !name.is_empty())
                .ok_or_else(|| format!("dependencies[{index}] has no `name` key"))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    fn manifest(content: &str) -> tempfile::TempDir {
        let dir = tempfile::tempdir().unwrap();
        fs::write(dir.path().join("manifest.yaml"), content).unwrap();
        dir
    }

    #[test]
    fn reads_dependency_names() {
        let dir = manifest("dependencies:\n  - name: bigdecimal\n  - name: singleton\n");
        assert_eq!(
            dependencies(dir.path()).unwrap(),
            vec!["bigdecimal", "singleton"]
        );
    }

    #[test]
    fn missing_manifest_means_no_dependencies() {
        let dir = tempfile::tempdir().unwrap();
        assert_eq!(dependencies(dir.path()).unwrap(), Vec::<String>::new());
    }

    #[test]
    fn comments_blank_lines_and_quotes_are_accepted() {
        let dir = manifest("# a comment\n\ndependencies:\n  - name: 'uri'\n  - name: \"csv\"\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri", "csv"]);
    }

    #[test]
    fn unrelated_top_level_keys_are_ignored() {
        let dir = manifest("type: stdlib\ndependencies:\n  - name: uri\nother:\n  - name: nope\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn empty_flow_sequence_means_no_dependencies() {
        let dir = manifest("dependencies: []\n");
        assert_eq!(dependencies(dir.path()).unwrap(), Vec::<String>::new());
    }

    #[test]
    fn non_sequence_dependencies_is_an_error() {
        let dir = manifest("dependencies: 42\n");
        assert!(matches!(
            dependencies(dir.path()),
            Err(LoadError::Manifest { .. })
        ));
    }

    #[test]
    fn flow_style_dependencies_are_accepted() {
        // Rejecting this would break a gem that loads fine under Ruby.
        let dir = manifest("dependencies: [{name: uri}, {name: 'csv'}]\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri", "csv"]);
    }

    #[test]
    fn multi_line_flow_style_is_accepted() {
        // The hand-rolled parser this replaced rejected multi-line flow
        // style; Ruby's YAML.safe_load accepts it.
        let dir = manifest("dependencies: [\n  {name: uri}\n]\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn unexpected_entry_shape_is_an_error() {
        let dir = manifest("dependencies:\n  - uri\n");
        assert!(matches!(
            dependencies(dir.path()),
            Err(LoadError::Manifest { .. })
        ));
    }

    // The tests below all cover input `YAML.safe_load` reads without
    // complaint, verified against Ruby. Rejecting or silently dropping any of
    // it would make a gem that loads under the Ruby implementation fail here.

    #[test]
    fn sequence_at_the_keys_own_indent_is_accepted() {
        // Reading `- name: uri` as the next top-level key silently returned
        // no dependencies at all.
        let dir = manifest("dependencies:\n- name: uri\n- name: csv\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri", "csv"]);
    }

    #[test]
    fn document_and_directive_markers_are_accepted() {
        // `YAML.dump` always emits `---`.
        let dir = manifest("%YAML 1.1\n---\ndependencies:\n  - name: uri\n...\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn entry_keys_other_than_name_are_ignored() {
        let dir =
            manifest("dependencies:\n  - name: uri\n    kind: gem\n  - kind: gem\n    name: csv\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri", "csv"]);
    }

    #[test]
    fn an_entrys_mapping_may_start_on_the_next_line() {
        let dir = manifest("dependencies:\n  -\n    name: uri\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn trailing_comments_are_stripped() {
        let dir = manifest("dependencies:\n  - name: uri # needed by Foo\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);

        let dir = manifest("dependencies: [{name: uri}] # needed by Foo\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn a_hash_inside_quotes_is_not_a_comment() {
        let dir = manifest("dependencies:\n  - name: \"x # y\"\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["x # y"]);
    }

    #[test]
    fn an_entry_without_a_name_is_an_error() {
        // Ruby yields a nil name here, which fails later and confusingly.
        let dir = manifest("dependencies:\n  - kind: gem\n");
        assert!(matches!(
            dependencies(dir.path()),
            Err(LoadError::Manifest { .. })
        ));
    }

    #[test]
    fn a_mapping_instead_of_a_sequence_is_an_error() {
        let dir = manifest("dependencies:\n  foo: bar\n");
        assert!(matches!(
            dependencies(dir.path()),
            Err(LoadError::Manifest { .. })
        ));
    }

    #[test]
    fn a_trailing_entry_is_not_lost() {
        let dir = manifest("dependencies:\n  - name: uri");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn a_nested_block_sequence_inside_an_entry_is_accepted() {
        let dir = manifest("dependencies:\n  - name: uri\n    platforms:\n      - mri\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn a_flow_mapping_as_a_block_sequence_item_is_accepted() {
        let dir = manifest("dependencies:\n  - {name: uri}\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }

    #[test]
    fn a_column_zero_sequence_under_an_unrelated_key_is_accepted() {
        let dir = manifest("authors:\n- John Doe\ndependencies:\n  - name: uri\n");
        assert_eq!(dependencies(dir.path()).unwrap(), vec!["uri"]);
    }
}

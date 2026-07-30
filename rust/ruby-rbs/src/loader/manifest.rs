use std::path::Path;

use super::LoadError;

/// Reads dependency library names from `manifest.yaml` directly under `dir`,
/// as used by stdlib and gem signature directories. Returns an empty list
/// when the file does not exist.
///
/// A deliberately small hand-written reader rather than a YAML parser
/// dependency: its acceptance criterion is Ruby's, since Ruby looks only at
/// `manifest['dependencies']` and never at the notation. So all of this is
/// accepted, in one file:
///
/// ```yaml
/// ---
/// dependencies:
///   - name: bigdecimal
/// - name: singleton
///   - name: uri
///     kind: gem
///   -
///     name: csv
/// ```
///
/// as are a single-line flow sequence (`dependencies: [{name: uri}]`, `[]`),
/// blank lines, comments, quoted names, and unrelated top-level keys.
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

fn parse(content: &str) -> Result<Vec<String>, String> {
    let mut names = Vec::new();
    let mut in_dependencies = false;
    let mut entry: Option<Entry> = None;

    for (index, raw) in content.lines().enumerate() {
        let line_number = index + 1;
        let line = strip_comment(raw).trim_end();
        let body = line.trim_start();
        if body.is_empty() {
            continue;
        }

        // Document and directive markers belong to no key.
        if body == "---" || body == "..." || body.starts_with("--- ") || body.starts_with('%') {
            finish_entry(entry.take(), &mut names)?;
            in_dependencies = false;
            continue;
        }

        let indented = line.len() != body.len();

        if in_dependencies {
            // The dash may sit at any indent, including column 0 at the
            // `dependencies:` key's own level — that is ordinary YAML, and
            // reading it as the next top-level key would drop the dependency
            // without a word.
            if body == "-" || body.starts_with("- ") || body.starts_with("-\t") {
                finish_entry(entry.take(), &mut names)?;
                let mut started = Entry::new(line_number);
                let item = body[1..].trim_start();
                if !item.is_empty() {
                    started.read_pair(item, line_number)?;
                }
                entry = Some(started);
                continue;
            }

            if indented {
                let Some(entry) = entry.as_mut() else {
                    return Err(format!(
                        "line {line_number}: `dependencies:` must be a sequence of `name:` entries, found {body:?}"
                    ));
                };
                entry.read_pair(body, line_number)?;
                continue;
            }

            finish_entry(entry.take(), &mut names)?;
            in_dependencies = false;
        }

        // Inside some other key's block; Ruby reads only the top-level
        // `dependencies`.
        if indented {
            continue;
        }

        let Some((key, rest)) = body.split_once(':') else {
            return Err(format!(
                "line {line_number}: expected `key:`, found {body:?}"
            ));
        };
        in_dependencies = unquote(key.trim()) == "dependencies";

        // `dependencies: [...]` is a flow sequence on this line, so no block
        // items follow.
        if in_dependencies && !rest.trim().is_empty() {
            names.extend(parse_flow_sequence(rest.trim(), line_number)?);
            in_dependencies = false;
        }
    }

    finish_entry(entry.take(), &mut names)?;

    Ok(names)
}

/// One in-progress `dependencies` entry. An entry spans its `-` line plus any
/// deeper continuation lines, so its name is only known once the next item,
/// the next top-level key, or the end of the file arrives.
struct Entry {
    name: Option<String>,
    line: usize,
}

impl Entry {
    fn new(line: usize) -> Self {
        Entry { name: None, line }
    }

    /// Reads one `key: value` pair of the entry's mapping, keeping only
    /// `name` — Ruby looks at nothing else.
    fn read_pair(&mut self, body: &str, line: usize) -> Result<(), String> {
        let Some((key, value)) = body.split_once(':') else {
            return Err(format!(
                "line {line}: expected `- name: <name>`, found {body:?}"
            ));
        };
        if unquote(key.trim()) != "name" {
            return Ok(());
        }

        let value = unquote(value.trim());
        if value.is_empty() {
            return Err(format!("line {line}: empty dependency name"));
        }
        if self.name.is_none() {
            self.name = Some(value.to_string());
        }
        Ok(())
    }
}

fn finish_entry(entry: Option<Entry>, names: &mut Vec<String>) -> Result<(), String> {
    let Some(entry) = entry else {
        return Ok(());
    };
    match entry.name {
        Some(name) => {
            names.push(name);
            Ok(())
        }
        None => Err(format!("line {}: entry has no `name` key", entry.line)),
    }
}

/// Cuts a trailing comment, applying YAML's rule that `#` starts one only at
/// the start of a line or after whitespace, and never inside quotes.
fn strip_comment(line: &str) -> &str {
    let bytes = line.as_bytes();
    let mut quote: Option<u8> = None;

    for (index, &byte) in bytes.iter().enumerate() {
        match quote {
            Some(open) if byte == open => quote = None,
            Some(_) => {}
            None => match byte {
                b'\'' | b'"' => quote = Some(byte),
                b'#' if index == 0 || bytes[index - 1].is_ascii_whitespace() => {
                    return &line[..index];
                }
                _ => {}
            },
        }
    }

    line
}

/// Reads `[{name: a}, {name: b}]` and `[]`. Only single-line flow sequences
/// are supported; anything else is an error rather than a silent skip.
fn parse_flow_sequence(rest: &str, line: usize) -> Result<Vec<String>, String> {
    let Some(inner) = rest.strip_prefix('[') else {
        return Err(format!(
            "line {line}: `dependencies:` must be a sequence of `name:` entries, found {rest:?}"
        ));
    };
    let Some(inner) = inner.strip_suffix(']') else {
        return Err(format!(
            "line {line}: unterminated flow sequence; multi-line flow style is not supported"
        ));
    };

    let mut names = Vec::new();
    let mut rest = inner.trim();

    while !rest.is_empty() {
        let item = rest
            .strip_prefix('{')
            .ok_or_else(|| format!("line {line}: expected `{{name: <name>}}`, found {rest:?}"))?;
        let (body, tail) = item
            .split_once('}')
            .ok_or_else(|| format!("line {line}: unterminated flow mapping"))?;

        names.push(flow_mapping_name(body, line)?);

        rest = tail.trim_start();
        match rest.strip_prefix(',') {
            Some(next) => rest = next.trim_start(),
            None if rest.is_empty() => {}
            None => {
                return Err(format!(
                    "line {line}: expected `,` between entries, found {rest:?}"
                ));
            }
        }
    }

    Ok(names)
}

/// Picks the `name` value out of a flow mapping body (`name: uri, kind: x`),
/// mirroring Ruby reading only `dep['name']`.
fn flow_mapping_name(body: &str, line: usize) -> Result<String, String> {
    for pair in body.split(',') {
        let Some((key, value)) = pair.split_once(':') else {
            return Err(format!(
                "line {line}: expected `key: value`, found {pair:?}"
            ));
        };
        if unquote(key.trim()) == "name" {
            let name = unquote(value.trim());
            if name.is_empty() {
                return Err(format!("line {line}: empty dependency name"));
            }
            return Ok(name.to_string());
        }
    }

    Err(format!("line {line}: entry has no `name` key: {body:?}"))
}

/// Strips one pair of matching quotes. Escape sequences are not supported;
/// no signature manifest uses them.
fn unquote(value: &str) -> &str {
    for quote in ['\'', '"'] {
        if let Some(inner) = value
            .strip_prefix(quote)
            .and_then(|v| v.strip_suffix(quote))
        {
            return inner;
        }
    }
    value
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
    fn multi_line_flow_style_is_an_error() {
        let dir = manifest("dependencies: [\n  {name: uri}\n]\n");
        assert!(matches!(
            dependencies(dir.path()),
            Err(LoadError::Manifest { .. })
        ));
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
}

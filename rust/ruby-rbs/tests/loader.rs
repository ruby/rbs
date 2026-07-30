use std::fs;
use std::path::{Path, PathBuf};

use ruby_rbs::ast::{Declaration, Directive};
use ruby_rbs::environment::{Environment, SourceKind};
use ruby_rbs::loader::{EnvironmentLoader, GemSigResolver, LoadError};
use ruby_rbs::repository::Repository;

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn stdlib_repository() -> Repository {
    let mut repository = Repository::new();
    repository.add(&repo_root().join("stdlib")).unwrap();
    repository
}

fn lib(name: &str) -> SourceKind {
    SourceKind::Library {
        name: name.to_string(),
        version: None,
    }
}

/// Writes `files` (relative path to content) under a fresh temporary
/// directory.
fn tree(files: &[(&str, &str)]) -> tempfile::TempDir {
    let dir = tempfile::tempdir().unwrap();
    for (path, content) in files {
        let path = dir.path().join(path);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, content).unwrap();
    }
    dir
}

/// Stands in for `Gem::Specification.find_by_name(...).full_gem_path + "/sig"`.
///
/// Matching on the requested version as well as the name keeps the tests
/// honest about what the loader passes through.
struct FakeGemSigs(Vec<(&'static str, Option<&'static str>, PathBuf)>);

impl GemSigResolver for FakeGemSigs {
    fn sig_path(&self, name: &str, version: Option<&str>) -> Option<PathBuf> {
        self.0
            .iter()
            .find(|(gem, gem_version, _)| *gem == name && *gem_version == version)
            .map(|(_, _, path)| path.clone())
    }
}

#[test]
fn loads_core_stdlib_and_dependencies_in_ruby_order() {
    let loader = EnvironmentLoader::new()
        .core_root(Some(repo_root().join("core")))
        .stdlib_root(Some(repo_root().join("stdlib")))
        .repository(stdlib_repository())
        .add_library("bigdecimal-math", None);

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.first().unwrap().kind, SourceKind::Core);
    // bigdecimal-math pulls bigdecimal via manifest.yaml, after itself
    let first_math = loaded
        .iter()
        .position(|f| f.kind == lib("bigdecimal-math"))
        .unwrap();
    let first_dep = loaded
        .iter()
        .position(|f| f.kind == lib("bigdecimal"))
        .unwrap();
    assert!(first_math < first_dep);
    // loading core implies stringio (stdlib migration compatibility)
    assert!(loaded.iter().any(|f| f.kind == lib("stringio")));
    assert_eq!(env.sources().len(), loaded.len());
    assert!(!env.interners().strings.is_empty());
}

#[test]
fn from_loader_is_the_primary_entry_point() {
    let loader = EnvironmentLoader::new()
        .core_root(Some(repo_root().join("core")))
        .stdlib_root(Some(repo_root().join("stdlib")))
        .repository(stdlib_repository());

    let env = Environment::from_loader(&loader).unwrap();

    assert!(!env.sources().is_empty());
}

#[test]
fn files_are_loaded_once_first_wins() {
    let dir = tempfile::tempdir().unwrap();
    fs::write(dir.path().join("a.rbs"), "class Foo\nend\n").unwrap();

    let loader = EnvironmentLoader::new()
        .add_dir(dir.path().to_path_buf())
        .add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
    assert_eq!(env.sources().len(), 1);
}

#[test]
fn explicit_dirs_do_not_skip_underscore_directories() {
    let dir = tempfile::tempdir().unwrap();
    fs::create_dir(dir.path().join("_private")).unwrap();
    fs::write(dir.path().join("_private/a.rbs"), "class Foo\nend\n").unwrap();

    let loader = EnvironmentLoader::new().add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
}

#[test]
fn unknown_library_is_an_error() {
    let loader = EnvironmentLoader::new().add_library("no_such_gem", None);

    let mut env = Environment::new();
    let error = loader.load(&mut env).unwrap_err();

    assert!(matches!(
        error,
        LoadError::UnknownLibrary { ref name, version: None } if name == "no_such_gem"
    ));
}

#[test]
fn parse_errors_carry_the_file_path() {
    let dir = tempfile::tempdir().unwrap();
    fs::write(dir.path().join("broken.rbs"), "class\n").unwrap();

    let loader = EnvironmentLoader::new().add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let error = loader.load(&mut env).unwrap_err();

    assert!(matches!(
        error,
        LoadError::Parse { ref path, .. } if path.ends_with("broken.rbs")
    ));
}

#[test]
fn core_requires_resolvable_stringio() {
    let loader = EnvironmentLoader::new().core_root(Some(repo_root().join("core")));

    let mut env = Environment::new();
    let error = loader.load(&mut env).unwrap_err();

    assert!(matches!(
        error,
        LoadError::UnknownLibrary { ref name, version: None } if name == "stringio"
    ));
}

#[test]
fn custom_repository_manifests_do_not_expand_dependencies() {
    // Without stdlib_root the bigdecimal-math manifest is ignored even
    // though the loading repository resolves the library itself.
    let loader = EnvironmentLoader::new()
        .repository(stdlib_repository())
        .add_library("bigdecimal-math", None);

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert!(!loaded.is_empty());
    assert!(loaded.iter().all(|f| f.kind == lib("bigdecimal-math")));
}

#[test]
fn loaded_sources_carry_converted_declarations_and_directives() {
    let dir = tree(&[(
        "person.rbs",
        "use Foo::Bar\n\nclass Person\n  def name: () -> String\nend\n",
    )]);

    let loader = EnvironmentLoader::new().add_dir(dir.path().to_path_buf());
    let env = Environment::from_loader(&loader).unwrap();

    let source = &env.sources()[0];
    assert!(source.buffer.name().ends_with("person.rbs"));
    assert!(matches!(source.directives.as_slice(), [Directive::Use(_)]));

    let [Declaration::Class(class)] = source.declarations.as_slice() else {
        panic!(
            "expected one class declaration, got {:?}",
            source.declarations
        );
    };
    // Names stay as written; Ruby absolutises them in `insert_rbs_decl`,
    // which comes with declaration indexing later.
    let interners = env.interners();
    assert_eq!(
        interners.type_names.display(class.name, &interners.strings),
        "Person"
    );
    assert_eq!(class.members.len(), 1);
}

#[test]
fn library_dirs_skip_underscore_directories() {
    // Ruby passes skip_hidden: true for libraries, unlike explicit dirs.
    let dir = tree(&[
        ("gem1/1.2.3/a.rbs", "class Person\nend\n"),
        ("gem1/1.2.3/_private/b.rbs", "class Person::Internal\nend\n"),
    ]);

    let mut repository = Repository::new();
    repository.add(dir.path()).unwrap();

    let loader = EnvironmentLoader::new()
        .repository(repository)
        .add_library("gem1", Some("1.2.3"));

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
    assert!(loaded[0].path.ends_with("a.rbs"));
    assert_eq!(
        loaded[0].kind,
        SourceKind::Library {
            name: "gem1".to_string(),
            version: Some("1.2.3".to_string()),
        }
    );
}

#[test]
fn gem_sig_resolver_wins_over_the_repository() {
    let gem_sigs = tree(&[("sig/from_resolver.rbs", "class FromResolver\nend\n")]);
    let repository_root = tree(&[("gem1/1.0.0/from_repository.rbs", "class FromRepo\nend\n")]);

    let mut repository = Repository::new();
    repository.add(repository_root.path()).unwrap();

    let loader = EnvironmentLoader::new()
        .repository(repository)
        .gem_sig_resolver(FakeGemSigs(vec![(
            "gem1",
            None,
            gem_sigs.path().join("sig"),
        )]))
        .add_library("gem1", None);

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
    assert!(loaded[0].path.ends_with("from_resolver.rbs"));
}

#[test]
fn gem_sig_resolver_manifests_expand_dependencies() {
    // resolve_dependencies consults the resolver first, so a manifest in an
    // installed gem's sig/ directory pulls its dependencies in too.
    let gem_sigs = tree(&[
        ("gem1/sig/manifest.yaml", "dependencies:\n  - name: gem2\n"),
        ("gem1/sig/a.rbs", "class Gem1\nend\n"),
        ("gem2/sig/b.rbs", "class Gem2\nend\n"),
    ]);

    let loader = EnvironmentLoader::new()
        .gem_sig_resolver(FakeGemSigs(vec![
            ("gem1", Some("1.2.3"), gem_sigs.path().join("gem1/sig")),
            ("gem2", None, gem_sigs.path().join("gem2/sig")),
        ]))
        .add_library("gem1", Some("1.2.3"));

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 2);
    assert_eq!(
        loaded[0].kind,
        SourceKind::Library {
            name: "gem1".to_string(),
            version: Some("1.2.3".to_string()),
        }
    );
    assert_eq!(loaded[1].kind, lib("gem2"));
}

#[test]
fn invalid_library_version_is_reported_distinctly() {
    let loader = EnvironmentLoader::new().add_library("uri", Some("junk"));

    let mut env = Environment::new();
    let error = loader.load(&mut env).unwrap_err();

    assert!(matches!(
        error,
        LoadError::InvalidVersion { ref name, ref version } if name == "uri" && version == "junk"
    ));
}

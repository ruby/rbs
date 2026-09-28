use std::fs;
use std::path::{Path, PathBuf};

use ruby_rbs::ast::{Declaration, Directive};
use ruby_rbs::environment::{Environment, SourceKind};
use ruby_rbs::loader::{EnvironmentLoader, LoadError};

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("../..")
}

fn stdlib_dir(name: &str) -> PathBuf {
    repo_root().join("stdlib").join(name).join("0")
}

fn lib(name: &str) -> SourceKind {
    SourceKind::Library {
        name: name.to_string(),
        path: stdlib_dir(name),
    }
}

fn tree(files: &[(&str, &str)]) -> tempfile::TempDir {
    let dir = tempfile::tempdir().unwrap();
    for (path, content) in files {
        let path = dir.path().join(path);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, content).unwrap();
    }
    dir
}

#[test]
fn loads_registered_sources_in_registration_order() {
    let loader = EnvironmentLoader::new(Some(repo_root().join("core")))
        .add_library("bigdecimal-math", stdlib_dir("bigdecimal-math"))
        .add_library("bigdecimal", stdlib_dir("bigdecimal"));

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.first().unwrap().kind, SourceKind::Core);
    let first_math = loaded
        .iter()
        .position(|f| f.kind == lib("bigdecimal-math"))
        .unwrap();
    let first_dep = loaded
        .iter()
        .position(|f| f.kind == lib("bigdecimal"))
        .unwrap();
    assert!(first_math < first_dep);
    assert_eq!(env.sources().len(), loaded.len());
    assert!(!env.interners().strings.is_empty());
}

#[test]
fn from_loader_is_the_primary_entry_point() {
    let dir = tree(&[("a.rbs", "class Foo\nend\n")]);

    let loader = EnvironmentLoader::new(None).add_dir(dir.path().to_path_buf());
    let env = Environment::from_loader(&loader).unwrap();

    assert_eq!(env.sources().len(), 1);
}

#[test]
fn files_are_loaded_once_first_wins() {
    let dir = tree(&[("a.rbs", "class Foo\nend\n")]);

    let loader = EnvironmentLoader::new(None)
        .add_dir(dir.path().to_path_buf())
        .add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
    assert_eq!(env.sources().len(), 1);
}

#[test]
fn load_reports_only_what_this_call_added() {
    let first = tree(&[("a.rbs", "class Foo\nend\n")]);
    let second = tree(&[("b.rbs", "class Bar\nend\n")]);

    let mut env = Environment::new();
    EnvironmentLoader::new(None)
        .add_dir(first.path().to_path_buf())
        .load(&mut env)
        .unwrap();
    let loaded = EnvironmentLoader::new(None)
        .add_dir(second.path().to_path_buf())
        .load(&mut env)
        .unwrap();

    assert_eq!(env.sources().len(), 2);
    let [only] = loaded.as_slice() else {
        panic!("expected one loaded file, got {loaded:?}");
    };
    assert!(only.path.ends_with("b.rbs"));
}

#[test]
fn explicit_dirs_do_not_skip_underscore_directories() {
    let dir = tree(&[("_private/a.rbs", "class Foo\nend\n")]);

    let loader = EnvironmentLoader::new(None).add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    assert_eq!(loaded.len(), 1);
}

#[test]
fn parse_errors_carry_the_file_path() {
    let dir = tree(&[("broken.rbs", "class\n")]);

    let loader = EnvironmentLoader::new(None).add_dir(dir.path().to_path_buf());

    let mut env = Environment::new();
    let error = loader.load(&mut env).unwrap_err();

    assert!(matches!(
        error,
        LoadError::Parse { ref path, .. } if path.ends_with("broken.rbs")
    ));
}

#[test]
fn loaded_sources_carry_converted_declarations_and_directives() {
    let dir = tree(&[(
        "person.rbs",
        "use Foo::Bar\n\nclass Person\n  def name: () -> String\nend\n",
    )]);

    let loader = EnvironmentLoader::new(None).add_dir(dir.path().to_path_buf());
    let env = Environment::from_loader(&loader).unwrap();

    let source = &env.sources()[0];
    assert!(source.path.ends_with("person.rbs"));
    assert!(matches!(source.directives.as_slice(), [Directive::Use(_)]));

    let [Declaration::Class(class)] = source.declarations.as_slice() else {
        panic!(
            "expected one class declaration, got {:?}",
            source.declarations
        );
    };
    // Names stay as written; Ruby absolutises them in `insert_rbs_decl`.
    let interners = env.interners();
    assert_eq!(
        interners.type_names.display(class.name, &interners.strings),
        "Person"
    );
    assert_eq!(class.members.len(), 1);
}

#[test]
fn library_dirs_skip_underscore_directories() {
    let dir = tree(&[
        ("gem1/1.2.3/a.rbs", "class Person\nend\n"),
        ("gem1/1.2.3/_private/b.rbs", "class Person::Internal\nend\n"),
    ]);

    let loader = EnvironmentLoader::new(None).add_library("gem1", dir.path().join("gem1/1.2.3"));

    let mut env = Environment::new();
    let loaded = loader.load(&mut env).unwrap();

    let [only] = loaded.as_slice() else {
        panic!("expected one loaded file, got {loaded:?}");
    };
    assert!(only.path.ends_with("a.rbs"));
    assert_eq!(
        only.kind,
        SourceKind::Library {
            name: "gem1".to_string(),
            path: dir.path().join("gem1/1.2.3"),
        }
    );
}

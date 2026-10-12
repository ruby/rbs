use crate::ast::Declaration;
use crate::ids::{IdIndexMap, TypeName, TypeNameTag};

use super::entry::SingleEntry;
use super::error::{DuplicatedDecl, DuplicatedDeclarationError};
use super::source::Source;
use super::{DeclId, Environment};

type SingleTable = IdIndexMap<TypeNameTag, SingleEntry>;

impl Environment {
    /// Like Ruby, the source and the entries inserted before a duplication
    /// error are not rolled back. The rejected declaration itself is not
    /// registered.
    pub(crate) fn add_source(&mut self, source: Source) -> Result<(), DuplicatedDeclarationError> {
        let source_index = u32::try_from(self.sources.len()).expect("too many sources");
        let decl_count =
            u32::try_from(source.declarations.len()).expect("too many declarations in one source");
        self.sources.push(source);

        for index in 0..decl_count {
            self.insert_decl(DeclId {
                source: source_index,
                index,
            })?;
        }
        Ok(())
    }

    fn insert_decl(&mut self, id: DeclId) -> Result<(), DuplicatedDeclarationError> {
        match self.decl(id) {
            Declaration::Interface(d) => {
                let name = d.name;
                self.insert_single(|env| &mut env.interface_decls, name, id)
            }
            Declaration::TypeAlias(d) => {
                let name = d.name;
                self.insert_single(|env| &mut env.type_alias_decls, name, id)
            }
            // TODO: register the other declaration kinds.
            _ => Ok(()),
        }
    }

    fn insert_single(
        &mut self,
        table: fn(&mut Self) -> &mut SingleTable,
        name: TypeName,
        id: DeclId,
    ) -> Result<(), DuplicatedDeclarationError> {
        let name = self.interners.type_names.to_absolute(name);
        let decls = table(self);
        if let Some(entry) = decls.get(&name) {
            let existing = entry.decl;
            return Err(self.duplicated_declaration(name, id, existing));
        }
        decls.insert(name, SingleEntry { name, decl: id });

        Ok(())
    }

    fn duplicated_declaration(
        &self,
        name: TypeName,
        inserted: DeclId,
        existing: DeclId,
    ) -> DuplicatedDeclarationError {
        let interners = &self.interners;
        DuplicatedDeclarationError::new(
            interners.type_names.display(name, &interners.strings),
            self.duplicated_decl(inserted),
            self.duplicated_decl(existing),
        )
    }

    fn duplicated_decl(&self, id: DeclId) -> DuplicatedDecl {
        DuplicatedDecl {
            path: self.sources[id.source as usize].path.clone(),
            location: self.decl(id).location_range(),
        }
    }
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use crate::ast::{AstConverter, Declaration};
    use crate::environment::{DuplicatedDeclarationError, Environment, Source, SourceKind};
    use crate::ids::TypeName;
    use crate::node;

    fn parse_decls(env: &mut Environment, src: &str) -> Vec<Declaration> {
        let signature = node::parse(src).expect("valid RBS source");
        let interners = env.interners_mut();
        let mut converter = AstConverter::new(&mut interners.strings, &mut interners.type_names);
        signature
            .declarations()
            .iter()
            .map(|node| converter.convert_declaration(&node))
            .collect()
    }

    fn add_rbs_source(
        env: &mut Environment,
        path: &str,
        declarations: Vec<Declaration>,
    ) -> Result<(), DuplicatedDeclarationError> {
        env.add_source(Source {
            path: PathBuf::from(path),
            directives: Vec::new(),
            declarations,
            kind: SourceKind::Dir {
                path: PathBuf::from("."),
            },
        })
    }

    fn type_name(env: &mut Environment, name: &str) -> TypeName {
        let interners = env.interners_mut();
        interners.type_names.parse(&mut interners.strings, name)
    }

    fn assert_duplicate(
        err: &DuplicatedDeclarationError,
        inserted: (&str, &Declaration),
        existing: (&str, &Declaration),
    ) {
        let [got_inserted, got_existing] = err.decls() else {
            panic!("expected two decls, got {:?}", err.decls());
        };
        assert_eq!(got_inserted.path, PathBuf::from(inserted.0));
        assert_eq!(got_inserted.location, inserted.1.location_range());
        assert_eq!(got_existing.path, PathBuf::from(existing.0));
        assert_eq!(got_existing.location, existing.1.location_range());
    }

    // environment_test.rb:169
    #[test]
    fn interface_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _I\nend\ninterface _I\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::_I");
        assert_duplicate(&err, ("b.rbs", &decls[1]), ("a.rbs", &decls[0]));
        assert_eq!(err.to_string(), "*:*:*...*:*: Duplicated declaration: ::_I");

        // The rejected declaration is not registered.
        assert_eq!(env.interface_entries().count(), 1);
        let name = type_name(&mut env, "::_I");
        let entry = env.interface_entry(name).unwrap();
        assert_eq!(env.decl(entry.decl), &decls[0]);
    }

    #[test]
    fn absolute_and_relative_names_collide() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _I\nend\ninterface ::_I\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::_I");
    }

    #[test]
    fn duplication_within_a_source_keeps_earlier_entries() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "interface _A\nend\ninterface _I\nend\ninterface _I\nend\ninterface _B\nend\n",
        );

        let err = add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap_err();

        assert_duplicate(&err, ("a.rbs", &decls[2]), ("a.rbs", &decls[1]));

        // Not rolled back: the source and the entries before the duplicate stay.
        assert_eq!(env.sources().len(), 1);
        let a = type_name(&mut env, "::_A");
        let i = type_name(&mut env, "::_I");
        let b = type_name(&mut env, "::_B");
        let names: Vec<_> = env.interface_entries().map(|e| e.name).collect();
        assert_eq!(names, [a, i]);
        assert_eq!(env.decl(env.interface_entry(i).unwrap().decl), &decls[1]);
        // Declarations after the duplicate are never reached.
        assert!(!env.is_interface_name(b));
    }

    #[test]
    fn distinct_interfaces_are_registered_in_order() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _A\nend\ninterface _B\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap();

        let a = type_name(&mut env, "::_A");
        let b = type_name(&mut env, "::_B");
        let unknown = type_name(&mut env, "::_C");
        assert!(env.is_interface_name(a));
        assert!(env.is_interface_name(b));
        assert!(!env.is_interface_name(unknown));
        assert!(env.interface_entry(unknown).is_none());

        let names: Vec<_> = env.interface_entries().map(|e| e.name).collect();
        assert_eq!(names, [a, b]);
        for (entry, decl) in env.interface_entries().zip(&decls) {
            assert_eq!(env.decl(entry.decl), decl);
        }
    }

    #[test]
    fn type_alias_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "type foo = String\ntype foo = Integer\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::foo");
        assert_duplicate(&err, ("b.rbs", &decls[1]), ("a.rbs", &decls[0]));

        assert_eq!(env.type_alias_entries().count(), 1);
        let name = type_name(&mut env, "::foo");
        let entry = env.type_alias_entry(name).unwrap();
        assert_eq!(env.decl(entry.decl), &decls[0]);
    }

    #[test]
    fn interface_and_type_alias_tables_are_independent() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _I\nend\ntype i = String\n");

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let interface = type_name(&mut env, "::_I");
        let alias = type_name(&mut env, "::i");
        assert!(env.is_interface_name(interface));
        assert!(!env.is_type_alias_name(interface));
        assert!(env.is_type_alias_name(alias));
        assert!(!env.is_interface_name(alias));
        assert_eq!(env.interface_entries().count(), 1);
        assert_eq!(env.type_alias_entries().count(), 1);
    }
}

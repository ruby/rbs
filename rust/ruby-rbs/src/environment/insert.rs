use crate::ast::Declaration;
use crate::ids::TypeName;

use super::entry::SingleEntry;
use super::error::{DuplicatedDecl, DuplicatedDeclarationError};
use super::source::Source;
use super::{DeclId, Environment};

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
        let decl_name = match self.decl(id) {
            Declaration::Interface(d) => d.name,
            // TODO: register the other declaration kinds.
            _ => return Ok(()),
        };

        let name = self.interners.type_names.to_absolute(decl_name);
        if let Some(existing) = self.interface_decls.get(&name) {
            return Err(self.duplicated_declaration(name, id, existing.decl));
        }
        self.interface_decls
            .insert(name, SingleEntry { name, decl: id });

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

    // environment_test.rb:169
    #[test]
    fn interface_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _I\nend\ninterface _I\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::_I");
        let [inserted, existing] = err.decls() else {
            panic!("expected two decls, got {:?}", err.decls());
        };
        assert_eq!(inserted.path, PathBuf::from("b.rbs"));
        assert_eq!(inserted.location, decls[1].location_range());
        assert_eq!(existing.path, PathBuf::from("a.rbs"));
        assert_eq!(existing.location, decls[0].location_range());
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

        let [inserted, existing] = err.decls() else {
            panic!("expected two decls, got {:?}", err.decls());
        };
        assert_eq!(inserted.path, PathBuf::from("a.rbs"));
        assert_eq!(inserted.location, decls[2].location_range());
        assert_eq!(existing.path, PathBuf::from("a.rbs"));
        assert_eq!(existing.location, decls[1].location_range());

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
}

use crate::ast::{ClassMember, Declaration, ModuleMember};
use crate::ids::{Id, IdIndexMap, SymbolId, TypeName};
use crate::interners::Interners;

use super::decl::{Context, DeclNode};
use super::entry::{ClassDeclEntry, ClassDeclKind, SingleEntry};
use super::error::{DuplicatedDecl, DuplicatedDeclarationError};
use super::source::Source;
use super::{DeclId, Environment};

type SingleTable<T> = IdIndexMap<T, SingleEntry<Id<T>>>;

impl Environment {
    /// Like Ruby, nothing is rolled back on a duplication error: the source,
    /// the entries inserted before the duplicate and the reopening of
    /// enclosing modules all stay. The rejected declaration and everything
    /// after it are not registered.
    pub(crate) fn add_source(&mut self, source: Source) -> Result<(), DuplicatedDeclarationError> {
        let source_index = u32::try_from(self.sources.len()).expect("too many sources");
        let decl_count =
            u32::try_from(source.declarations.len()).expect("too many declarations in one source");
        self.sources.push(source);

        let root = self.interners.type_names.absolute_root();
        for index in 0..decl_count {
            self.insert_decl(source_index, None, index, root, Context::root())?;
        }
        Ok(())
    }

    fn insert_decl(
        &mut self,
        source: u32,
        parent: Option<DeclId>,
        index: u32,
        namespace: TypeName,
        context: Context,
    ) -> Result<(), DuplicatedDeclarationError> {
        enum Kind {
            ClassOrModule {
                kind: ClassDeclKind,
                name: TypeName,
                decl_members: Vec<u32>,
            },
            Interface(TypeName),
            TypeAlias(TypeName),
            Global(SymbolId),
            Other,
        }

        let node = DeclNode {
            source,
            parent,
            index,
            context,
        };
        let kind = match self.member_decl(&node) {
            Declaration::Class(c) => Kind::ClassOrModule {
                kind: ClassDeclKind::Class,
                name: c.name,
                decl_members: decl_member_indices(&c.members, ClassMember::as_declaration),
            },
            Declaration::Module(m) => Kind::ClassOrModule {
                kind: ClassDeclKind::Module,
                name: m.name,
                decl_members: decl_member_indices(&m.members, ModuleMember::as_declaration),
            },
            Declaration::Interface(d) => Kind::Interface(d.name),
            Declaration::TypeAlias(d) => Kind::TypeAlias(d.name),
            Declaration::Global(d) => Kind::Global(d.name),
            // TODO: constants, class aliases and module aliases are skipped.
            // A class or module name clashing with one of them is not
            // detected, and the query side (`is_module_name`,
            // `class_entry`, `module_entry`) ignores alias entries too.
            _ => Kind::Other,
        };

        match kind {
            Kind::ClassOrModule {
                kind,
                name,
                decl_members,
            } => {
                let name = self.interners.type_names.concat(namespace, name);
                if let Some(existing) = self.class_decls.get(&name)
                    && existing.kind() != kind
                {
                    let existing = existing.primary_decl(self);
                    let name = self
                        .interners
                        .type_names
                        .display(name, &self.interners.strings);
                    return Err(self.duplicated_declaration(name, &node, existing));
                }
                let id = self.push_node(node);
                self.class_decls
                    .entry(name)
                    .or_insert_with(|| ClassDeclEntry::new(name, kind))
                    .push(id);
                self.insert_members(node.source, node.context, id, name, &decl_members)
            }
            Kind::Interface(name) => {
                let name = self.interners.type_names.concat(namespace, name);
                self.insert_single(
                    |env| &mut env.interface_decls,
                    name,
                    node,
                    |i, n| i.type_names.display(n, &i.strings),
                )
            }
            Kind::TypeAlias(name) => {
                let name = self.interners.type_names.concat(namespace, name);
                self.insert_single(
                    |env| &mut env.type_alias_decls,
                    name,
                    node,
                    |i, n| i.type_names.display(n, &i.strings),
                )
            }
            Kind::Global(name) => self.insert_single(
                |env| &mut env.global_decls,
                name,
                node,
                |i, n| i.strings.resolve(n).to_owned(),
            ),
            Kind::Other => Ok(()),
        }
    }

    fn insert_members(
        &mut self,
        source: u32,
        context: Context,
        id: DeclId,
        name: TypeName,
        decl_members: &[u32],
    ) -> Result<(), DuplicatedDeclarationError> {
        if decl_members.is_empty() {
            return Ok(());
        }
        let inner = self.intern_context(context, name);
        for &member in decl_members {
            self.insert_decl(source, Some(id), member, name, inner)?;
        }
        Ok(())
    }

    fn insert_single<T>(
        &mut self,
        table: fn(&mut Self) -> &mut SingleTable<T>,
        name: Id<T>,
        node: DeclNode,
        render: fn(&Interners, Id<T>) -> String,
    ) -> Result<(), DuplicatedDeclarationError> {
        if let Some(entry) = table(self).get(&name) {
            let existing = entry.decl;
            let name = render(&self.interners, name);
            return Err(self.duplicated_declaration(name, &node, existing));
        }
        let decl = self.push_node(node);
        table(self).insert(name, SingleEntry { name, decl });

        Ok(())
    }

    fn duplicated_declaration(
        &self,
        name: String,
        inserted: &DeclNode,
        existing: DeclId,
    ) -> DuplicatedDeclarationError {
        DuplicatedDeclarationError::new(
            name,
            self.duplicated_decl(inserted),
            self.duplicated_decl(self.node(existing)),
        )
    }

    fn duplicated_decl(&self, node: &DeclNode) -> DuplicatedDecl {
        DuplicatedDecl {
            path: self.sources[node.source as usize].path.clone(),
            location: self.member_decl(node).location_range(),
        }
    }
}

fn decl_member_indices<M>(
    members: &[M],
    as_declaration: impl Fn(&M) -> Option<&Declaration>,
) -> Vec<u32> {
    members
        .iter()
        .enumerate()
        .filter(|(_, m)| as_declaration(m).is_some())
        .map(|(i, _)| u32::try_from(i).expect("too many members"))
        .collect()
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use crate::ast::{AstConverter, Declaration};
    use crate::environment::{
        ClassDeclEntry, Context, DuplicatedDeclarationError, Environment, Source, SourceKind,
    };
    use crate::ids::{SymbolId, TypeName};
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

    fn intern(env: &mut Environment, name: &str) -> SymbolId {
        env.interners_mut().strings.intern(name)
    }

    fn nested_decl(parent: &Declaration, index: usize) -> &Declaration {
        let member = match parent {
            Declaration::Class(c) => c.members[index].as_declaration(),
            Declaration::Module(m) => m.members[index].as_declaration(),
            _ => panic!("expected a class or module declaration"),
        };
        member.unwrap_or_else(|| panic!("expected member {index} to be a declaration"))
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
        // The rejected declaration is not registered.
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
        let decls = parse_decls(&mut env, "interface _I\nend\ntype i = String\n$g: String\n");

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let interface = type_name(&mut env, "::_I");
        let alias = type_name(&mut env, "::i");
        assert!(env.is_interface_name(interface));
        assert!(!env.is_type_alias_name(interface));
        assert!(env.is_type_alias_name(alias));
        assert!(!env.is_interface_name(alias));
        assert_eq!(env.interface_entries().count(), 1);
        assert_eq!(env.type_alias_entries().count(), 1);
        assert_eq!(env.global_entries().count(), 1);
    }

    #[test]
    fn insert_global() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "$VERSION: String\n");

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let name = intern(&mut env, "$VERSION");
        assert!(env.is_global_name(name));
        let entry = env.global_entry(name).unwrap();
        assert_eq!(entry.name, name);
        assert_eq!(env.decl(entry.decl), &decls[0]);

        let other = intern(&mut env, "$OTHER");
        assert!(!env.is_global_name(other));
        assert!(env.global_entry(other).is_none());
    }

    #[test]
    fn global_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "$VERSION: String\n$VERSION: Integer\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "$VERSION");
        assert_duplicate(&err, ("b.rbs", &decls[1]), ("a.rbs", &decls[0]));

        assert_eq!(env.global_entries().count(), 1);
        let name = intern(&mut env, "$VERSION");
        let entry = env.global_entry(name).unwrap();
        assert_eq!(env.decl(entry.decl), &decls[0]);
    }

    #[test]
    fn globals_are_registered_in_order() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "$B: String\n$A: String\n");

        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let a = intern(&mut env, "$A");
        let b = intern(&mut env, "$B");
        let names: Vec<_> = env.global_entries().map(|e| e.name).collect();
        assert_eq!(names, [b, a]);
    }

    #[test]
    fn primary_decl_is_first_declaration() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "interface _Animal\nend\nmodule Foo : _Animal\nend\nmodule Foo : Object\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let foo = type_name(&mut env, "::Foo");
        let entry = env.module_entry(foo).unwrap();
        assert_eq!(env.decl(entry.primary_decl()), &decls[1]);
    }

    #[test]
    fn insert_nested_modules() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\n  module Bar\n  end\n  module ::Baz\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let names: Vec<_> = env.class_entries().map(ClassDeclEntry::name).collect();
        let expected: Vec<_> = ["::Foo", "::Foo::Bar", "::Baz"]
            .into_iter()
            .map(|n| type_name(&mut env, n))
            .collect();
        assert_eq!(names, expected);
        for name in expected {
            assert!(env.is_module_decl(name));
            assert!(env.is_module_name(name));
        }
        let unknown = type_name(&mut env, "::Foo::Baz");
        assert!(!env.is_module_decl(unknown));
        assert!(!env.is_module_name(unknown));
    }

    #[test]
    fn reopened_module_is_one_entry() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo\nend\nmodule Foo\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap();

        assert_eq!(env.class_entries().count(), 1);
        let foo = type_name(&mut env, "::Foo");
        let entry = env.module_entry(foo).unwrap();
        let registered: Vec<_> = entry.each_decl().map(|id| env.decl(id)).collect();
        assert_eq!(registered, [&decls[0], &decls[1]]);
    }

    #[test]
    fn context_of_nested_declarations() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\n  module ::Baz\n    module Qux\n    end\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [foo, baz, qux] = ["::Foo", "::Baz", "::Baz::Qux"].map(|n| type_name(&mut env, n));
        let id = |name| env.module_entry(name).unwrap().each_decl().next().unwrap();

        assert_eq!(env.context_names(env.context_of(id(foo))).count(), 0);
        let names: Vec<_> = env.context_names(env.context_of(id(baz))).collect();
        assert_eq!(names, [foo]);
        let names: Vec<_> = env.context_names(env.context_of(id(qux))).collect();
        assert_eq!(names, [baz, foo]);

        assert_eq!(env.decl(id(qux)), nested_decl(nested_decl(&decls[0], 0), 0));
    }

    #[test]
    fn context_is_equal_across_reopenings() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\n  module Bar\n  end\nend\nmodule Foo\n  module Bar\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let bar = type_name(&mut env, "::Foo::Bar");
        let ids: Vec<_> = env.module_entry(bar).unwrap().each_decl().collect();
        assert_eq!(ids.len(), 2);
        assert_eq!(env.context_of(ids[0]), env.context_of(ids[1]));
        assert_ne!(env.context_of(ids[0]), Context::root());
    }

    #[test]
    fn context_is_per_declaration_within_an_entry() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo::Bar\nend\nmodule Foo\n  module Bar\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [foo, bar] = ["::Foo", "::Foo::Bar"].map(|n| type_name(&mut env, n));
        let ids: Vec<_> = env.module_entry(bar).unwrap().each_decl().collect();
        assert_eq!(ids.len(), 2);
        assert_eq!(env.decl(ids[0]), &decls[0]);
        assert_eq!(env.decl(ids[1]), nested_decl(&decls[1], 0));
        assert_eq!(env.context_of(ids[0]), Context::root());
        let names: Vec<_> = env.context_names(env.context_of(ids[1])).collect();
        assert_eq!(names, [foo]);
    }

    #[test]
    fn declarations_in_a_module_use_its_namespace() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\n  interface _I\n  end\n  type t = String\n  def foo: () -> void\n  $g: String\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let interface = type_name(&mut env, "::Foo::_I");
        let alias = type_name(&mut env, "::Foo::t");
        let relative = type_name(&mut env, "::_I");
        assert!(env.is_interface_name(interface));
        assert!(env.is_type_alias_name(alias));
        assert!(!env.is_interface_name(relative));
        let global = intern(&mut env, "$g");
        assert!(env.is_global_name(global));

        let module = &decls[0];
        let entry = env.interface_entry(interface).unwrap();
        assert_eq!(env.decl(entry.decl), nested_decl(module, 0));
        let entry = env.type_alias_entry(alias).unwrap();
        assert_eq!(env.decl(entry.decl), nested_decl(module, 1));
        let entry = env.global_entry(global).unwrap();
        assert_eq!(env.decl(entry.decl), nested_decl(module, 3));

        let entry = env.interface_entry(interface).unwrap();
        let names: Vec<_> = env.context_names(env.context_of(entry.decl)).collect();
        let foo = type_name(&mut env, "::Foo");
        assert_eq!(names, [foo]);
    }

    #[test]
    fn nested_duplicate_is_reported_without_leaving_a_node() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\n  interface _I\n  end\nend\nmodule Foo\n  interface _I\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let nodes = env.decl_nodes.len();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::Foo::_I");
        assert_duplicate(
            &err,
            ("b.rbs", nested_decl(&decls[1], 0)),
            ("a.rbs", nested_decl(&decls[0], 0)),
        );
        assert_eq!(env.decl_nodes.len(), nodes + 1);
        assert_eq!(env.interface_entries().count(), 1);
        let foo = type_name(&mut env, "::Foo");
        assert_eq!(env.module_entry(foo).unwrap().each_decl().count(), 2);
    }

    #[test]
    fn insert_nested_modules_in_a_class() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class Foo\n  module Bar\n  end\n  module ::Baz\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let [foo, bar, baz] = ["::Foo", "::Foo::Bar", "::Baz"].map(|n| type_name(&mut env, n));
        assert!(env.is_class_decl(foo));
        assert!(!env.is_module_decl(foo));
        assert!(env.is_module_decl(bar));
        assert!(env.is_module_decl(baz));
        assert!(env.is_module_name(foo));
        assert!(env.class_entry(bar).is_none());
        assert!(env.module_entry(foo).is_none());
        let names: Vec<_> = env.class_entries().map(ClassDeclEntry::name).collect();
        assert_eq!(names, [foo, bar, baz]);
        let names: Vec<_> = env
            .context_names(env.context_of(env.module_entry(bar).unwrap().primary_decl()))
            .collect();
        assert_eq!(names, [foo]);
    }

    #[test]
    fn insert_open_class() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class Foo\n  module Bar\n  end\nend\nclass Foo < String\n  module Bar\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [foo, bar] = ["::Foo", "::Foo::Bar"].map(|n| type_name(&mut env, n));
        let string = type_name(&mut env, "String");
        let entry = env.class_entry(foo).unwrap();
        assert_eq!(entry.each_decl().count(), 2);
        let primary = env.decl(entry.primary_decl(&env));
        assert_eq!(primary, &decls[1]);
        let Declaration::Class(primary) = primary else {
            panic!("expected a class declaration");
        };
        assert_eq!(primary.super_class.as_ref().unwrap().name, string);

        assert_eq!(env.module_entry(bar).unwrap().each_decl().count(), 2);
    }

    #[test]
    fn class_primary_decl_falls_back_to_first() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "class Foo\nend\nclass Foo\nend\n");

        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let foo = type_name(&mut env, "::Foo");
        let entry = env.class_entry(foo).unwrap();
        assert_eq!(env.decl(entry.primary_decl(&env)), &decls[0]);
    }

    #[test]
    fn module_then_class_is_rejected() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo\nend\nclass Foo < String\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::Foo");
        assert_duplicate(&err, ("b.rbs", &decls[1]), ("a.rbs", &decls[0]));
        let foo = type_name(&mut env, "::Foo");
        assert!(env.is_module_decl(foo));
        assert!(!env.is_class_decl(foo));
    }

    #[test]
    fn class_then_module_reports_the_primary_decl() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class Foo\nend\nclass Foo < String\nend\nmodule Foo\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();

        assert_duplicate(&err, ("b.rbs", &decls[2]), ("a.rbs", &decls[1]));
        let foo = type_name(&mut env, "::Foo");
        assert!(env.is_class_decl(foo));
        assert_eq!(env.class_entry(foo).unwrap().each_decl().count(), 2);
    }

    #[test]
    fn nested_kind_mismatch_is_rejected() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class Foo\n  module Bar\n  end\nend\nclass Foo\n  class Bar\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::Foo::Bar");
        assert_duplicate(
            &err,
            ("b.rbs", nested_decl(&decls[1], 0)),
            ("a.rbs", nested_decl(&decls[0], 0)),
        );
    }

    #[test]
    fn members_of_a_rejected_declaration_are_not_registered() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\nend\nclass Foo\n  module Baz\n  end\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let nodes = env.decl_nodes.len();
        add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        let baz = type_name(&mut env, "::Foo::Baz");
        assert!(!env.is_module_name(baz));
        assert_eq!(env.class_entries().count(), 1);
        assert_eq!(env.decl_nodes.len(), nodes);
    }

    #[test]
    fn insert_class_in_a_module() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo\n  class Bar\n  end\nend\n");

        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let [foo, bar] = ["::Foo", "::Foo::Bar"].map(|n| type_name(&mut env, n));
        assert!(env.is_module_decl(foo));
        assert!(env.is_class_decl(bar));
        assert!(env.class_entry(bar).is_some());
        assert!(env.module_entry(bar).is_none());
        let names: Vec<_> = env
            .context_names(env.context_of(env.class_entry(bar).unwrap().primary_decl(&env)))
            .collect();
        assert_eq!(names, [foo]);
    }
}

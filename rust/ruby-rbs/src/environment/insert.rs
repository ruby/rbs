use crate::ast::{ClassMember, Declaration, ModuleMember};
use crate::ids::{Id, IdIndexMap, SymbolId, TypeName};
use crate::interners::Interners;

use super::decl::{Context, DeclNode};
use super::entry::{AliasEntry, ClassDeclEntry, ClassDeclKind, ConstantLookup, SingleEntry};
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
            Constant(TypeName),
            Alias(TypeName, fn(SingleEntry) -> AliasEntry),
            Global(SymbolId),
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
            Declaration::Constant(d) => Kind::Constant(d.name),
            Declaration::Global(d) => Kind::Global(d.name),
            Declaration::ModuleAlias(d) => Kind::Alias(d.new_name, AliasEntry::Module),
            Declaration::ClassAlias(d) => Kind::Alias(d.new_name, AliasEntry::Class),
        };

        match kind {
            Kind::ClassOrModule {
                kind,
                name,
                decl_members,
            } => {
                let name = self.interners.type_names.concat(namespace, name);
                if let Some((first, rest)) = self.constant_clash(name, Some(kind)) {
                    return Err(self.duplicated_type_name(name, &node, first, rest));
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
            Kind::Constant(name) => self.insert_constant_like(namespace, name, node, |env, e| {
                env.constant_decls.insert(e.name, e);
            }),
            Kind::Alias(name, wrap) => {
                self.insert_constant_like(namespace, name, node, |env, e| {
                    env.class_alias_decls.insert(e.name, wrap(e));
                })
            }
            Kind::Global(name) => self.insert_single(
                |env| &mut env.global_decls,
                name,
                node,
                |i, n| i.strings.resolve(n).to_owned(),
            ),
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

    fn insert_constant_like(
        &mut self,
        namespace: TypeName,
        name: TypeName,
        node: DeclNode,
        store: impl FnOnce(&mut Self, SingleEntry),
    ) -> Result<(), DuplicatedDeclarationError> {
        let name = self.interners.type_names.concat(namespace, name);
        if let Some((first, rest)) = self.constant_clash(name, None) {
            return Err(self.duplicated_type_name(name, &node, first, rest));
        }
        let decl = self.push_node(node);
        store(self, SingleEntry { name, decl });
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
            return Err(self.duplicated_declaration(name, &node, existing, []));
        }
        self.register_single(table, name, node);
        Ok(())
    }

    fn register_single<T>(
        &mut self,
        table: fn(&mut Self) -> &mut SingleTable<T>,
        name: Id<T>,
        node: DeclNode,
    ) {
        let decl = self.push_node(node);
        table(self).insert(name, SingleEntry { name, decl });
    }

    fn duplicated_type_name(
        &self,
        name: TypeName,
        inserted: &DeclNode,
        first: DeclId,
        rest: impl IntoIterator<Item = DeclId>,
    ) -> DuplicatedDeclarationError {
        let name = self
            .interners
            .type_names
            .display(name, &self.interners.strings);
        self.duplicated_declaration(name, inserted, first, rest)
    }

    fn duplicated_declaration(
        &self,
        name: String,
        inserted: &DeclNode,
        first: DeclId,
        rest: impl IntoIterator<Item = DeclId>,
    ) -> DuplicatedDeclarationError {
        DuplicatedDeclarationError::new(
            name,
            self.duplicated_decl(inserted),
            self.duplicated_decl(self.node(first)),
            rest.into_iter()
                .map(|id| self.duplicated_decl(self.node(id))),
        )
    }

    /// The declarations a new constant-namespace entry would clash with.
    /// `class_kind` is the kind of the class/module being inserted, `None`
    /// for a constant declaration. Same-kind reopening is not a clash, and
    /// a class/module kind mismatch reports only the primary decl.
    fn constant_clash(
        &self,
        name: TypeName,
        class_kind: Option<ClassDeclKind>,
    ) -> Option<(DeclId, Vec<DeclId>)> {
        match (self.constant_entry(name)?, class_kind) {
            (ConstantLookup::ClassDecl(e), Some(kind)) => {
                (e.kind() != kind).then(|| (e.primary_decl(self), Vec::new()))
            }
            (entry, _) => {
                let mut ids = entry.each_decl();
                let first = ids.next()?;
                Some((first, ids.collect()))
            }
        }
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
        ClassDeclEntry, ClassLookup, ConstantLookup, Context, DuplicatedDeclarationError,
        Environment, ModuleClassLookup, ModuleLookup, Source, SourceKind,
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
        existing: &[(&str, &Declaration)],
    ) {
        let (got_inserted, got_existing) = err.decls().split_first().expect("decls is not empty");
        assert_eq!(got_inserted.path, PathBuf::from(inserted.0));
        assert_eq!(got_inserted.location, inserted.1.location_range());
        assert_eq!(got_existing.len(), existing.len(), "{:?}", err.decls());
        for (got, want) in got_existing.iter().zip(existing) {
            assert_eq!(got.path, PathBuf::from(want.0));
            assert_eq!(got.location, want.1.location_range());
        }
    }

    // environment_test.rb:169
    #[test]
    fn interface_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "interface _I\nend\ninterface _I\nend\n");

        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(err.name(), "::_I");
        assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);
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

        assert_duplicate(&err, ("a.rbs", &decls[2]), &[("a.rbs", &decls[1])]);

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
        assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);

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
        assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);

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
        let ModuleLookup::Module(entry) = env.module_entry(foo).unwrap() else {
            panic!("expected a module entry");
        };
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
            &[("a.rbs", nested_decl(&decls[0], 0))],
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
        let ModuleLookup::Module(entry) = env.module_entry(bar).unwrap() else {
            panic!("expected a module entry");
        };
        let names: Vec<_> = env
            .context_names(env.context_of(entry.primary_decl()))
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
        assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);
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

        assert_duplicate(&err, ("b.rbs", &decls[2]), &[("a.rbs", &decls[1])]);
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
            &[("a.rbs", nested_decl(&decls[0], 0))],
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

    #[test]
    fn insert_const_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\nend\nBar: ::Integer\nFoo: String\nclass Bar\nend\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();

        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();
        assert_eq!(err.name(), "::Foo");
        assert_duplicate(&err, ("b.rbs", &decls[2]), &[("a.rbs", &decls[0])]);

        let err = add_rbs_source(&mut env, "c.rbs", vec![decls[3].clone()]).unwrap_err();
        assert_eq!(err.name(), "::Bar");
        assert_duplicate(&err, ("c.rbs", &decls[3]), &[("a.rbs", &decls[1])]);
    }

    #[test]
    fn const_twice_duplication_error() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "Foo: String\nFoo: String\n");

        let err = add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap_err();

        assert_eq!(err.name(), "::Foo");
        assert_duplicate(&err, ("a.rbs", &decls[1]), &[("a.rbs", &decls[0])]);
    }

    #[test]
    fn const_clashing_with_a_reopened_class_reports_every_declaration() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "class Foo\nend\nclass Foo\nend\nFoo: String\n");

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();

        assert_duplicate(
            &err,
            ("b.rbs", &decls[2]),
            &[("a.rbs", &decls[0]), ("a.rbs", &decls[1])],
        );
    }

    #[test]
    fn const_clashing_with_a_reopened_module_reports_every_declaration() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo\nend\nmodule Foo\nend\nFoo: String\n");

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();

        assert_duplicate(
            &err,
            ("b.rbs", &decls[2]),
            &[("a.rbs", &decls[0]), ("a.rbs", &decls[1])],
        );
    }

    #[test]
    fn nested_class_clashing_with_a_const_reports_the_qualified_name() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module M\n  X: Integer\n  class X\n  end\nend\n");

        let err = add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap_err();

        assert_eq!(err.name(), "::M::X");
        assert_duplicate(
            &err,
            ("a.rbs", nested_decl(&decls[0], 1)),
            &[("a.rbs", nested_decl(&decls[0], 0))],
        );
    }

    #[test]
    fn clash_between_const_and_class_leaves_the_environment_unchanged() {
        for (first, second) in [
            ("Foo: String\n", "class Foo\nend\n"),
            ("class Foo\nend\n", "Foo: String\n"),
        ] {
            let mut env = Environment::new();
            let decls = parse_decls(&mut env, &format!("{first}{second}"));
            add_rbs_source(&mut env, "a.rbs", decls[..1].to_vec()).unwrap();
            let nodes = env.decl_nodes.len();
            let consts = env.constant_decls.len();
            let classes = env.class_decls.len();

            add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

            assert_eq!(env.decl_nodes.len(), nodes);
            assert_eq!(env.constant_decls.len(), consts);
            assert_eq!(env.class_decls.len(), classes);
        }
    }

    #[test]
    fn constant_entry_finds_class_module_and_constant() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "class A\nend\nmodule B\nend\nC: String\n");
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [a, b, c, d] = ["::A", "::B", "::C", "::D"].map(|n| type_name(&mut env, n));
        assert!(matches!(
            env.constant_entry(a),
            Some(ConstantLookup::ClassDecl(ClassDeclEntry::Class(_)))
        ));
        assert!(matches!(
            env.constant_entry(b),
            Some(ConstantLookup::ClassDecl(ClassDeclEntry::Module(_)))
        ));
        let Some(ConstantLookup::Constant(entry)) = env.constant_entry(c) else {
            panic!("expected a constant entry");
        };
        assert_eq!(env.decl(entry.decl), &decls[2]);
        assert!(env.constant_entry(d).is_none());

        assert!(env.is_constant_decl(c));
        assert!(!env.is_constant_decl(a));
        assert!(env.is_constant_name(a));
        assert!(env.is_constant_name(b));
        assert!(env.is_constant_name(c));
        assert!(!env.is_constant_name(d));
    }

    #[test]
    fn constants_are_registered_in_order_with_their_namespace() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module M\n  X: Integer\nend\nB: String\nA: String\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let [x, b, a] = ["::M::X", "::B", "::A"].map(|n| type_name(&mut env, n));
        let names: Vec<_> = env.constant_entries().map(|e| e.name).collect();
        assert_eq!(names, [x, b, a]);
    }

    #[test]
    fn clash_with_a_module_alias_is_rejected_in_both_directions() {
        for (first, second) in [
            ("module Foo = Kernel\n", "Foo: String\n"),
            ("module Foo = Kernel\n", "module Foo\nend\n"),
            ("module Foo = Kernel\n", "class Foo\nend\n"),
            ("Foo: String\n", "module Foo = Kernel\n"),
            ("module Foo = Kernel\n", "module Foo = Comparable\n"),
            ("module Foo\nend\n", "module Foo = Kernel\n"),
            ("class Foo\nend\n", "module Foo = Kernel\n"),
        ] {
            let mut env = Environment::new();
            let decls = parse_decls(&mut env, &format!("{first}{second}"));
            add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();

            let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

            assert_eq!(err.name(), "::Foo", "{first}{second}");
            assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);
        }
    }

    #[test]
    fn module_alias_clashing_with_a_reopened_module_reports_every_declaration() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module Foo\nend\nmodule Foo\nend\nmodule Foo = Kernel\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();

        assert_duplicate(
            &err,
            ("b.rbs", &decls[2]),
            &[("a.rbs", &decls[0]), ("a.rbs", &decls[1])],
        );
    }

    #[test]
    fn nested_module_alias_uses_the_namespace() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module M\n  module A = Kernel\nend\n");
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [a, top_a] = ["::M::A", "::A"].map(|n| type_name(&mut env, n));
        let Some(ModuleLookup::ModuleAlias(entry)) = env.module_entry(a) else {
            panic!("expected a module alias entry");
        };
        assert_eq!(entry.name, a);
        assert_eq!(env.decl(entry.decl), nested_decl(&decls[0], 0));
        assert!(env.module_entry(top_a).is_none());
    }

    #[test]
    fn module_entry_finds_module_and_module_alias_but_not_constant() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module A\nend\nmodule B = Kernel\nC: String\nclass D\nend\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [a, b, c, d, e] = ["::A", "::B", "::C", "::D", "::E"].map(|n| type_name(&mut env, n));
        assert!(matches!(env.module_entry(a), Some(ModuleLookup::Module(_))));
        let Some(ModuleLookup::ModuleAlias(entry)) = env.module_entry(b) else {
            panic!("expected a module alias entry");
        };
        assert_eq!(env.decl(entry.decl), &decls[1]);
        assert!(env.module_entry(c).is_none());
        assert!(env.module_entry(d).is_none());
        assert!(env.module_entry(e).is_none());

        let alias = env.module_entry(b).unwrap();
        assert_eq!(alias.name(), b);
        assert_eq!(alias.primary_decl(), entry.decl);
        assert_eq!(alias.each_decl().collect::<Vec<_>>(), [entry.decl]);

        let module = env.module_entry(a).unwrap();
        assert_eq!(module.name(), a);
        assert_eq!(env.decl(module.primary_decl()), &decls[0]);
    }

    #[test]
    fn constant_entry_finds_module_alias() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo = Kernel\n");
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let foo = type_name(&mut env, "::Foo");
        let Some(ConstantLookup::ModuleAlias(entry)) = env.constant_entry(foo) else {
            panic!("expected a module alias entry");
        };
        assert_eq!(env.decl(entry.decl), &decls[0]);
        assert!(env.is_constant_name(foo));
        assert!(!env.is_constant_decl(foo));
    }

    #[test]
    fn module_alias_predicates() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module A = Kernel\nmodule B\nend\ninterface _I\nend\ntype t = Integer\nC: String\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let [a, b, i, t, c, d] =
            ["::A", "::B", "::_I", "::t", "::C", "::D"].map(|n| type_name(&mut env, n));
        assert!(env.is_module_alias(a));
        assert!(!env.is_module_alias(b));
        assert!(env.is_module_name(a));
        assert!(env.is_module_name(b));
        assert!(!env.is_module_decl(a));
        for name in [a, b, i, t] {
            assert!(env.is_type_name(name));
        }
        assert!(!env.is_type_name(c));
        assert!(!env.is_type_name(d));
    }

    #[test]
    fn clash_with_a_module_alias_leaves_the_environment_unchanged() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "module Foo = Kernel\nFoo: String\n");
        add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();
        let nodes = env.decl_nodes.len();
        let aliases = env.class_alias_decls.len();
        let consts = env.constant_decls.len();

        add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

        assert_eq!(env.decl_nodes.len(), nodes);
        assert_eq!(env.class_alias_decls.len(), aliases);
        assert_eq!(env.constant_decls.len(), consts);
    }

    #[test]
    fn insert_class_module_alias() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "module RBS\n  module Kernel = ::Kernel\n\n  class RbObject = Object\nend\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [kernel, object] = ["::RBS::Kernel", "::RBS::RbObject"].map(|n| type_name(&mut env, n));
        assert!(env.is_module_alias(kernel));
        assert!(!env.is_class_alias(kernel));
        assert!(env.is_class_alias(object));
        assert!(!env.is_module_alias(object));
        assert!(env.is_module_name(object));
        assert!(env.is_type_name(object));
        assert!(env.is_constant_name(object));
        assert!(!env.is_class_decl(object));
        let Some(ConstantLookup::ClassAlias(entry)) = env.constant_entry(object) else {
            panic!("expected a class alias entry");
        };
        assert_eq!(env.decl(entry.decl), nested_decl(&decls[0], 1));
    }

    #[test]
    fn clash_with_a_class_alias_is_rejected_in_both_directions() {
        for (first, second) in [
            ("class Foo = Object\n", "Foo: String\n"),
            ("class Foo = Object\n", "class Foo\nend\n"),
            ("class Foo = Object\n", "module Foo\nend\n"),
            ("class Foo = Object\n", "module Foo = Kernel\n"),
            ("class Foo = Object\n", "class Foo = String\n"),
            ("Foo: String\n", "class Foo = Object\n"),
            ("class Foo\nend\n", "class Foo = Object\n"),
            ("module Foo\nend\n", "class Foo = Object\n"),
            ("module Foo = Kernel\n", "class Foo = Object\n"),
        ] {
            let mut env = Environment::new();
            let decls = parse_decls(&mut env, &format!("{first}{second}"));
            add_rbs_source(&mut env, "a.rbs", vec![decls[0].clone()]).unwrap();

            let err = add_rbs_source(&mut env, "b.rbs", vec![decls[1].clone()]).unwrap_err();

            assert_eq!(err.name(), "::Foo", "{first}{second}");
            assert_duplicate(&err, ("b.rbs", &decls[1]), &[("a.rbs", &decls[0])]);
        }
    }

    #[test]
    fn class_entry_finds_class_and_class_alias_only() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class A\nend\nclass B = Object\nmodule C\nend\nmodule D = Kernel\nE: String\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [a, b, c, d, e, f] =
            ["::A", "::B", "::C", "::D", "::E", "::F"].map(|n| type_name(&mut env, n));
        let class = env.class_entry(a).unwrap();
        assert!(matches!(class, ClassLookup::Class(_)));
        assert_eq!(class.name(), a);
        assert_eq!(env.decl(class.primary_decl(&env)), &decls[0]);
        let alias = env.class_entry(b).unwrap();
        assert!(matches!(alias, ClassLookup::ClassAlias(_)));
        assert_eq!(alias.name(), b);
        assert_eq!(env.decl(alias.primary_decl(&env)), &decls[1]);
        assert_eq!(alias.each_decl().count(), 1);
        for name in [c, d, e, f] {
            assert!(env.class_entry(name).is_none());
        }
    }

    #[test]
    fn module_entry_does_not_find_a_class_alias() {
        let mut env = Environment::new();
        let decls = parse_decls(&mut env, "class A = Object\n");
        add_rbs_source(&mut env, "a.rbs", decls).unwrap();

        let a = type_name(&mut env, "::A");
        assert!(env.module_entry(a).is_none());
    }

    #[test]
    fn module_class_entry_finds_everything_but_constants() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class A\nend\nmodule B\nend\nclass C = Object\nmodule D = Kernel\nE: String\n",
        );
        add_rbs_source(&mut env, "a.rbs", decls.clone()).unwrap();

        let [a, b, c, d, e, f] =
            ["::A", "::B", "::C", "::D", "::E", "::F"].map(|n| type_name(&mut env, n));
        assert!(matches!(
            env.module_class_entry(a),
            Some(ModuleClassLookup::ClassDecl(ClassDeclEntry::Class(_)))
        ));
        assert!(matches!(
            env.module_class_entry(b),
            Some(ModuleClassLookup::ClassDecl(ClassDeclEntry::Module(_)))
        ));
        assert!(matches!(
            env.module_class_entry(c),
            Some(ModuleClassLookup::ClassAlias(_))
        ));
        assert!(matches!(
            env.module_class_entry(d),
            Some(ModuleClassLookup::ModuleAlias(_))
        ));
        for (idx, name) in [a, b, c, d].into_iter().enumerate() {
            let found = env.module_class_entry(name).unwrap();
            assert_eq!(found.name(), name);
            assert_eq!(found.each_decl().count(), 1);
            assert_eq!(env.decl(found.primary_decl(&env)), &decls[idx]);
        }
        assert!(env.module_class_entry(e).is_none());
        assert!(env.module_class_entry(f).is_none());
    }

    #[test]
    fn class_alias_clashing_with_a_reopened_class_reports_every_declaration() {
        let mut env = Environment::new();
        let decls = parse_decls(
            &mut env,
            "class Foo\nend\nclass Foo\nend\nclass Foo = Object\n",
        );

        add_rbs_source(&mut env, "a.rbs", decls[..2].to_vec()).unwrap();
        let err = add_rbs_source(&mut env, "b.rbs", vec![decls[2].clone()]).unwrap_err();

        assert_duplicate(
            &err,
            ("b.rbs", &decls[2]),
            &[("a.rbs", &decls[0]), ("a.rbs", &decls[1])],
        );
    }
}

//! Owned pure-Rust AST data structures.
//!
//! The [`node`] module exposes borrowed wrappers over the C parser AST. This
//! module is the Rust-owned representation that can be built from parser nodes,
//! generated directly, or transformed without keeping the parser allocation
//! alive.
//!
//! [`node`]: crate::node

pub mod annotation;
pub mod comment;
pub mod convert;
pub mod declarations;
pub mod location;
pub mod members;
pub mod method_type;
pub mod type_param;
pub mod types;

pub use annotation::Annotation;
pub use comment::Comment;
pub use convert::AstConverter;
pub use declarations::{
    ClassAliasDeclaration, ClassDeclaration, ClassMember, ClassSuper, ConstantDeclaration,
    Declaration, GlobalDeclaration, InterfaceDeclaration, ModuleAliasDeclaration,
    ModuleDeclaration, ModuleMember, ModuleSelf, TypeAliasDeclaration,
};
pub use location::{
    AliasDeclarationLocation, AliasLocation, AliasMemberLocation, AttributeMemberLocation,
    ClassDeclarationLocation, ClassInstanceLocation, ClassSingletonLocation, ClassSuperLocation,
    ConstantDeclarationLocation, FunctionParamLocation, GlobalDeclarationLocation,
    InterfaceDeclarationLocation, InterfaceLocation, LocationRange, MethodDefinitionLocation,
    MethodTypeLocation, MixinMemberLocation, ModuleDeclarationLocation, ModuleSelfLocation,
    TypeAliasDeclarationLocation, TypeParamLocation, VariableMemberLocation,
};
pub use members::{
    AliasKind, AliasMember, AttrAccessorMember, AttrReaderMember, AttrWriterMember, AttributeKind,
    ClassInstanceVariableMember, ClassVariableMember, ExtendMember, IncludeMember,
    InstanceVariableMember, IvarName, Member, MethodDefinitionMember, MethodDefinitionOverload,
    MethodKind, PrependMember, PrivateMember, PublicMember, Visibility,
};
pub use method_type::MethodType;
pub use type_param::{TypeParam, Variance};
pub use types::{
    AliasType, BaseType, BaseTypeKind, BlockType, ClassInstanceType, ClassSingletonType, Function,
    FunctionParam, FunctionType, InterfaceType, IntersectionType, KeywordParam, Literal,
    LiteralType, OptionalType, ProcType, RecordField, RecordKey, RecordType, TupleType, Type,
    UnionType, UntypedFunctionType, VariableType,
};

#[cfg(test)]
mod tests {
    use crate::ast::{
        AstConverter, BaseType, BaseTypeKind, ClassMember, Declaration, IvarName, Literal, Member,
        MethodKind, ModuleMember, RecordKey, Type,
    };
    use crate::interner::StringInterner;
    use crate::node::{Node, parse};
    use crate::type_name::TypeNameInterner;

    #[test]
    fn builds_owned_type_ast() {
        let ty = Type::Base(BaseType {
            kind: BaseTypeKind::Any { todo: false },
            location: None,
        });

        assert_eq!(
            ty,
            Type::Base(BaseType {
                kind: BaseTypeKind::Any { todo: false },
                location: None,
            })
        );
    }

    #[test]
    fn converts_type_node_to_owned_ast() {
        let signature = parse(
            r#"type foo = {
                name: String,
                ?age: Integer,
                active: true,
                tags: Array[String | Symbol]
            }"#,
        )
        .unwrap();

        let Node::TypeAlias(alias) = signature.declarations().iter().next().unwrap() else {
            panic!("expected type alias");
        };

        let mut strings = StringInterner::new();
        let mut type_names = TypeNameInterner::new();
        let mut converter = AstConverter::new(&mut strings, &mut type_names);
        let ty = converter.convert_type(&alias.type_());

        let Type::Record(record) = ty else {
            panic!("expected record type");
        };

        assert_eq!(record.fields.len(), 4);
        assert_eq!(
            record.fields[0].key,
            RecordKey::Symbol(strings.intern("name"))
        );
        assert!(record.fields[0].required);
        assert_eq!(
            record.fields[1].key,
            RecordKey::Symbol(strings.intern("age"))
        );
        assert!(!record.fields[1].required);

        let Type::Literal(literal) = &record.fields[2].ty else {
            panic!("expected literal type");
        };
        assert_eq!(literal.literal, Literal::Bool(true));

        let Type::ClassInstance(array) = &record.fields[3].ty else {
            panic!("expected Array class instance");
        };
        assert_eq!(type_names.display(array.name, &strings), "Array");
        assert_eq!(array.args.len(), 1);
    }

    #[test]
    fn converts_declarations_and_members_to_owned_ast() {
        let signature = parse(
            r#"
                class Foo[T] < Bar[String]
                  public
                  include Enumerable[String]
                  attr_reader name: String
                  attr_writer email(@email): String
                  def self.process: (String) -> void
                  @ivar: Integer
                  class Nested
                  end
                end

                module M : _Each[String]
                  extend Kernel
                end

                interface _I
                  def foo: () -> void
                end

                type pair[T] = [T, T]
                VERSION: String
                $global: Integer
                class Old = New
                module OldM = NewM
            "#,
        )
        .unwrap();

        let mut strings = StringInterner::new();
        let mut type_names = TypeNameInterner::new();
        let mut converter = AstConverter::new(&mut strings, &mut type_names);
        let declarations = signature
            .declarations()
            .iter()
            .map(|node| converter.convert_declaration(&node))
            .collect::<Vec<_>>();

        assert_eq!(declarations.len(), 8);

        let Declaration::Class(class_decl) = &declarations[0] else {
            panic!("expected class declaration");
        };
        assert_eq!(type_names.display(class_decl.name, &strings), "Foo");
        assert_eq!(class_decl.type_params.len(), 1);
        assert_eq!(
            type_names.display(class_decl.super_class.as_ref().unwrap().name, &strings),
            "Bar"
        );
        assert_eq!(class_decl.members.len(), 7);

        let ClassMember::Member(Member::Public(public_member)) = &class_decl.members[0] else {
            panic!("expected public member");
        };
        assert!(public_member.location.is_some());

        let ClassMember::Member(Member::Include(include_member)) = &class_decl.members[1] else {
            panic!("expected include member");
        };
        assert_eq!(
            type_names.display(include_member.name, &strings),
            "Enumerable"
        );
        assert_eq!(include_member.args.len(), 1);

        let ClassMember::Member(Member::AttrReader(attr_reader)) = &class_decl.members[2] else {
            panic!("expected attr_reader member");
        };
        assert_eq!(attr_reader.name, strings.intern("name"));
        assert_eq!(attr_reader.visibility, None);

        let ClassMember::Member(Member::AttrWriter(attr_writer)) = &class_decl.members[3] else {
            panic!("expected attr_writer member");
        };
        assert_eq!(
            attr_writer.ivar_name,
            IvarName::Name(strings.intern("@email"))
        );

        let ClassMember::Member(Member::MethodDefinition(method)) = &class_decl.members[4] else {
            panic!("expected method definition member");
        };
        assert_eq!(method.name, strings.intern("process"));
        assert_eq!(method.kind, MethodKind::Singleton);
        assert_eq!(method.visibility, None);
        assert_eq!(method.overloads.len(), 1);

        let ClassMember::Member(Member::InstanceVariable(ivar)) = &class_decl.members[5] else {
            panic!("expected instance variable member");
        };
        assert_eq!(ivar.name, strings.intern("@ivar"));

        let ClassMember::Declaration(Declaration::Class(nested)) = &class_decl.members[6] else {
            panic!("expected nested class declaration");
        };
        assert_eq!(type_names.display(nested.name, &strings), "Nested");

        let Declaration::Module(module_decl) = &declarations[1] else {
            panic!("expected module declaration");
        };
        assert_eq!(type_names.display(module_decl.name, &strings), "M");
        assert_eq!(module_decl.self_types.len(), 1);
        let ModuleMember::Member(Member::Extend(extend_member)) = &module_decl.members[0] else {
            panic!("expected extend member");
        };
        assert_eq!(type_names.display(extend_member.name, &strings), "Kernel");

        let Declaration::Interface(interface_decl) = &declarations[2] else {
            panic!("expected interface declaration");
        };
        assert_eq!(type_names.display(interface_decl.name, &strings), "_I");
        let Member::MethodDefinition(interface_method) = &interface_decl.members[0] else {
            panic!("expected interface method definition");
        };
        assert_eq!(interface_method.kind, MethodKind::Instance);

        let Declaration::TypeAlias(type_alias) = &declarations[3] else {
            panic!("expected type alias declaration");
        };
        assert_eq!(type_names.display(type_alias.name, &strings), "pair");

        let Declaration::Constant(constant) = &declarations[4] else {
            panic!("expected constant declaration");
        };
        assert_eq!(type_names.display(constant.name, &strings), "VERSION");

        let Declaration::Global(global) = &declarations[5] else {
            panic!("expected global declaration");
        };
        assert_eq!(global.name, strings.intern("$global"));

        let Declaration::ClassAlias(class_alias) = &declarations[6] else {
            panic!("expected class alias declaration");
        };
        assert_eq!(type_names.display(class_alias.new_name, &strings), "Old");

        let Declaration::ModuleAlias(module_alias) = &declarations[7] else {
            panic!("expected module alias declaration");
        };
        assert_eq!(type_names.display(module_alias.old_name, &strings), "NewM");
    }
}

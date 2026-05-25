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
pub mod location;
pub mod method_type;
pub mod type_param;
pub mod types;

pub use annotation::Annotation;
pub use comment::Comment;
pub use convert::AstConverter;
pub use location::{
    AliasLocation, ClassInstanceLocation, ClassSingletonLocation, FunctionParamLocation,
    InterfaceLocation, LocationRange, MethodTypeLocation, TypeParamLocation,
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
    use crate::ast::{AstConverter, BaseType, BaseTypeKind, Literal, RecordKey, Type};
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
}

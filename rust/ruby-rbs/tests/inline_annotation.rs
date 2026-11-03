#[macro_use]
mod common;

use common::slice;
use ruby_rbs::node::{
    Node, ParsedNode, parse_inline_leading_annotation, parse_inline_trailing_annotation,
};

fn leading(source: &str) -> ParsedNode<'_> {
    parse_inline_leading_annotation(source, 0..source.len(), &[])
        .unwrap()
        .expect("expected a leading annotation")
}

fn trailing(source: &str) -> ParsedNode<'_> {
    parse_inline_trailing_annotation(source, 0..source.len(), &[])
        .unwrap()
        .expect("expected a trailing annotation")
}

#[test]
fn every_annotation_kind_has_a_node() {
    expect_variant!(
        leading(": (Integer) -> void").node(),
        ColonMethodTypeAnnotation
    );
    expect_variant!(
        leading("@rbs (String) -> void | (Integer) -> void").node(),
        MethodTypesAnnotation
    );
    expect_variant!(leading("@rbs skip").node(), SkipAnnotation);
    expect_variant!(leading("@rbs return: String").node(), ReturnTypeAnnotation);
    expect_variant!(
        leading("@rbs @name: String").node(),
        InstanceVariableAnnotation
    );
    expect_variant!(
        leading("@rbs module-self: _Each[String]").node(),
        ModuleSelfAnnotation
    );
    expect_variant!(leading("@rbs value: Integer").node(), ParamTypeAnnotation);
    expect_variant!(
        leading("@rbs *rest: String").node(),
        SplatParamTypeAnnotation
    );
    expect_variant!(
        leading("@rbs **opts: bool").node(),
        DoubleSplatParamTypeAnnotation
    );
    expect_variant!(
        leading("@rbs &block: () -> void").node(),
        BlockParamTypeAnnotation
    );
    expect_variant!(trailing(": String").node(), NodeTypeAssertion);
    expect_variant!(
        trailing("[String, Integer]").node(),
        TypeApplicationAnnotation
    );
    expect_variant!(trailing(": class-alias Foo").node(), ClassAliasAnnotation);
    expect_variant!(trailing(": module-alias Bar").node(), ModuleAliasAnnotation);
}

#[test]
fn annotation_children_are_readable() {
    let source = "@rbs module-self: _Hash[String, Integer]";
    let annotation = leading(source);
    let module_self = expect_variant!(annotation.node(), ModuleSelfAnnotation);

    assert_eq!(module_self.name().name().as_str(), "_Hash");
    let args: Vec<&str> = module_self
        .args()
        .iter()
        .map(|arg| slice(source, arg.location()))
        .collect();
    assert_eq!(args, ["String", "Integer"]);
    let commas: Vec<&str> = module_self
        .args_comma_locations()
        .iter()
        .map(|location| slice(source, location))
        .collect();
    assert_eq!(commas, [","]);
    assert_eq!(
        module_self
            .open_bracket_location()
            .map(|l| slice(source, l)),
        Some("[")
    );
    assert!(module_self.comment_location().is_none());
}

#[test]
fn malformed_annotations_return_located_errors() {
    // The parser also produces an annotation here; the error must win.
    let source = ": String is a ";
    let error = parse_inline_trailing_annotation(source, 0..source.len(), &[])
        .err()
        .expect("expected a parse error");
    assert_eq!(&source[error.range], "is");

    let source = "@rbs &block: () { () -> void } -> void";
    let error = parse_inline_leading_annotation(source, 0..source.len(), &[])
        .err()
        .expect("expected a parse error");
    assert_eq!(&source[error.range], "{");
}

#[test]
fn type_variables_reach_the_annotation_parser() {
    let source = ": Array[T]";
    let annotation = parse_inline_trailing_annotation(source, 0..source.len(), &["T"])
        .unwrap()
        .unwrap();
    let assertion = expect_variant!(annotation.node(), NodeTypeAssertion);
    let array = expect_variant!(assertion.type_(), ClassInstanceType);
    assert!(matches!(
        array.args().iter().next(),
        Some(Node::VariableType(_))
    ));
}

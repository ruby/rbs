#[macro_use]
mod common;

use common::slice;
use ruby_rbs::node::{
    MethodTypeOptions, Node, ParseError, ParsedNode, TypeOptions, parse_method_type, parse_type,
};
use std::ops::Range;

fn ty<'a>(source: &'a str, variables: &[&'a str], options: TypeOptions) -> ParsedNode<'a> {
    parse_type(source, 0..source.len(), variables, options)
        .unwrap()
        .expect("expected a type")
}

fn type_error(source: &str, options: TypeOptions) -> ParseError {
    parse_type(source, 0..source.len(), &[], options)
        .err()
        .expect("expected a parse error")
}

fn range_error(source: &str, range: Range<usize>) -> ParseError {
    parse_type(source, range, &[], TypeOptions::default())
        .err()
        .expect("expected an invalid range")
}

fn method_type<'a>(
    source: &'a str,
    variables: &[&'a str],
    options: MethodTypeOptions,
) -> ParsedNode<'a> {
    parse_method_type(source, 0..source.len(), variables, options)
        .unwrap()
        .expect("expected a method type")
}

fn method_type_error(source: &str, options: MethodTypeOptions) -> ParseError {
    parse_method_type(source, 0..source.len(), &[], options)
        .err()
        .expect("expected a parse error")
}

#[test]
fn locations_are_byte_offsets_into_the_source() {
    let source = "日本語\nArray[String]? Integer";
    let start = source.find('A').unwrap();
    let end = source.find(" Integer").unwrap();
    let options = TypeOptions {
        require_eof: true,
        ..TypeOptions::default()
    };
    let parsed = parse_type(source, start..end, &[], options)
        .unwrap()
        .unwrap();

    let optional = expect_variant!(parsed.node(), OptionalType);
    assert_eq!(slice(source, optional.location()), "Array[String]?");
    let array = expect_variant!(optional.type_(), ClassInstanceType);
    let arg = array.args().iter().next().unwrap();
    assert_eq!(slice(source, arg.location()), "String");
}

#[test]
fn empty_range_is_none() {
    for source in ["", "   \n  "] {
        assert!(matches!(
            parse_type(source, 0..source.len(), &[], TypeOptions::default()),
            Ok(None)
        ));
        assert!(matches!(
            parse_method_type(source, 0..source.len(), &[], MethodTypeOptions::default()),
            Ok(None)
        ));
    }
}

#[test]
fn require_eof_rejects_trailing_tokens() {
    let source = "String Integer";
    let parsed = ty(source, &[], TypeOptions::default());
    assert_eq!(slice(source, parsed.node().location()), "String");
    let options = TypeOptions {
        require_eof: true,
        ..TypeOptions::default()
    };
    assert_eq!(&source[type_error(source, options).range], "Integer");

    let source = "() -> void | () -> String";
    let parsed = method_type(source, &[], MethodTypeOptions::default());
    assert_eq!(slice(source, parsed.node().location()), "() -> void");
    let error = method_type_error(source, MethodTypeOptions { require_eof: true });
    assert_eq!(&source[error.range], "|");
}

#[test]
fn options_reach_the_parser() {
    let defaults = TypeOptions::default();
    for (source, options) in [
        (
            "void",
            TypeOptions {
                void_allowed: false,
                ..defaults
            },
        ),
        (
            "self",
            TypeOptions {
                self_allowed: false,
                ..defaults
            },
        ),
        (
            "instance",
            TypeOptions {
                classish_allowed: false,
                ..defaults
            },
        ),
    ] {
        ty(source, &[], defaults);
        let error = type_error(source, options);
        assert_eq!(&source[error.range], source, "{}", error.message);
    }

    let source = "(class) -> instance";
    let parsed = method_type(source, &[], MethodTypeOptions::default());
    let function = expect_variant!(
        expect_variant!(parsed.node(), MethodType).type_(),
        FunctionType
    );
    assert!(matches!(function.return_type(), Node::InstanceType(_)));
}

#[test]
fn type_variables_are_declared() {
    let source = "Hash[K, String]";
    let parsed = ty(source, &["K"], TypeOptions::default());
    let hash = expect_variant!(parsed.node(), ClassInstanceType);
    let key = hash.args().iter().next().unwrap();
    assert_eq!(expect_variant!(key, VariableType).name().as_str(), "K");

    let parsed = ty(source, &[], TypeOptions::default());
    let hash = expect_variant!(parsed.node(), ClassInstanceType);
    assert!(matches!(
        hash.args().iter().next().unwrap(),
        Node::ClassInstanceType(_)
    ));

    let source = "(Elem) -> Elem";
    let parsed = method_type(source, &["Elem"], MethodTypeOptions::default());
    let function = expect_variant!(
        expect_variant!(parsed.node(), MethodType).type_(),
        FunctionType
    );
    assert!(matches!(function.return_type(), Node::VariableType(_)));
}

#[test]
fn syntax_errors_carry_the_token_range() {
    let source = "Array[String";
    let error = type_error(source, TypeOptions::default());
    assert_eq!(error.range, source.len()..source.len());
}

#[test]
fn invalid_ranges_are_errors() {
    let source = "String";
    let len = source.len();
    #[allow(clippy::reversed_empty_ranges)]
    let cases = [5..3, 0..len + 1, len + 1..len + 1];
    for range in cases {
        let error = range_error(source, range.clone());
        assert_eq!(error.range, range, "{}", error.message);
    }

    let source = "日本語\nString";
    for range in [4..12, 0..4, 7..source.len()] {
        let start_ok = source.is_char_boundary(range.start);
        let end_ok = source.is_char_boundary(range.end);
        assert!(!(start_ok && end_ok), "{range:?} is a valid range");
        let error = range_error(source, range.clone());
        assert_eq!(error.range, range, "{}", error.message);
    }
}

#[test]
fn nul_is_rejected_only_before_the_range_start() {
    let source = "\0String";
    let error = range_error(source, 1..source.len());
    assert_eq!(error.range, 1..source.len());

    let source = "String\0";
    let parsed = ty(source, &[], TypeOptions::default());
    let class = expect_variant!(parsed.node(), ClassInstanceType);
    assert_eq!(class.name().name().as_str(), "String");
}

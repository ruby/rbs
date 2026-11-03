//! Safe parsing of RBS types and method types.

use super::Node;
use super::parser::{OwnedParser, ParseError};
use ruby_rbs_sys::bindings::*;
use std::ops::Range;

/// Owns a parser and the node it produced.
pub struct ParsedNode<'a> {
    parser: OwnedParser<'a>,
    pointer: *mut rbs_node_t,
}

impl ParsedNode<'_> {
    /// Returns the parsed node.
    #[must_use]
    pub fn node(&self) -> Node<'_> {
        Node::new(self.parser.raw(), self.pointer)
    }
}

/// Options for [`parse_type`], matching the keywords of the Ruby `RBS::Parser.parse_type`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TypeOptions {
    /// Fail unless the type ends the range. Off by default.
    pub require_eof: bool,
    /// Accept `void`. On by default.
    pub void_allowed: bool,
    /// Accept `self`. On by default.
    pub self_allowed: bool,
    /// Accept `instance` and `class`. On by default.
    pub classish_allowed: bool,
}

impl Default for TypeOptions {
    fn default() -> Self {
        Self {
            require_eof: false,
            void_allowed: true,
            self_allowed: true,
            classish_allowed: true,
        }
    }
}

/// Options for [`parse_method_type`], matching Ruby's `RBS::Parser.parse_method_type`.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct MethodTypeOptions {
    /// Fail unless the method type ends the range. Off by default.
    pub require_eof: bool,
}

/// Parses one type, such as `Array[String]`, from `source[range]`.
///
/// `type_variables` names the type variables in scope. Locations are byte offsets into
/// `source`. Returns `Ok(None)` if the range has no tokens.
///
/// # Errors
///
/// Returns [`ParseError`] for malformed input, or for a range that is out of bounds, not on
/// UTF-8 character boundaries, past `i32::MAX`, or starting after a NUL byte.
///
/// # Example
///
/// ```
/// use ruby_rbs::node::{Node, TypeOptions, parse_type};
/// let source = "Array[String]";
/// let parsed = parse_type(source, 0..source.len(), &[], TypeOptions::default())?.unwrap();
/// assert!(matches!(parsed.node(), Node::ClassInstanceType(_)));
/// # Ok::<(), ruby_rbs::node::ParseError>(())
/// ```
pub fn parse_type<'a>(
    source: &'a str,
    range: Range<usize>,
    type_variables: &[&'a str],
    options: TypeOptions,
) -> Result<Option<ParsedNode<'a>>, ParseError> {
    let parsed = parse_fragment(source, range, type_variables, |parser, node| unsafe {
        rbs_parse_type(
            parser,
            node,
            options.void_allowed,
            options.self_allowed,
            options.classish_allowed,
        )
    })?;
    if options.require_eof
        && let Some(parsed) = &parsed
    {
        parsed.parser.expect_eof()?;
    }
    Ok(parsed)
}

/// Parses one method type, such as `[T] (T) -> T`, from `source[range]` as a
/// [`Node::MethodType`].
///
/// Behaves like [`parse_type`]. The method type's own type parameters need not be listed in
/// `type_variables`.
pub fn parse_method_type<'a>(
    source: &'a str,
    range: Range<usize>,
    type_variables: &[&'a str],
    options: MethodTypeOptions,
) -> Result<Option<ParsedNode<'a>>, ParseError> {
    // The Ruby extension always allows `instance` and `class` in method types.
    parse_fragment(source, range, type_variables, |parser, node| unsafe {
        rbs_parse_method_type(parser, node, options.require_eof, true)
    })
}

/// Runs `parse`, which stores the node it produces, on a parser over `source[range]`.
fn parse_fragment<'a, T>(
    source: &'a str,
    range: Range<usize>,
    type_variables: &[&'a str],
    parse: impl FnOnce(*mut rbs_parser_t, *mut *mut T) -> bool,
) -> Result<Option<ParsedNode<'a>>, ParseError> {
    let parser = OwnedParser::new(source, range, type_variables)?;
    if parser.at_eof() {
        return Ok(None);
    }

    let mut node: *mut T = std::ptr::null_mut();
    let success = parse(parser.raw().as_ptr(), &mut node);

    // The parser can produce a node and still fail on trailing tokens; the error wins.
    if let Some(error) = parser.error() {
        return Err(error);
    }
    if !success || node.is_null() {
        return Ok(None);
    }
    Ok(Some(ParsedNode {
        parser,
        pointer: node.cast(),
    }))
}

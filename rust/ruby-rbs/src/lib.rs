include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
use rbs_encoding_type_t::RBS_ENCODING_UTF_8;
use ruby_rbs_sys::bindings::*;
use std::sync::Once;

static INIT: Once = Once::new();

/// Parse RBS code into an AST.
///
/// ```rust
/// use ruby_rbs::parse;
/// let rbs_code = r#"type foo = "hello""#;
/// let signature = parse(rbs_code.as_bytes());
/// assert!(signature.is_ok(), "Failed to parse RBS signature");
/// ```
pub fn parse(rbs_code: &[u8]) -> Result<*mut rbs_signature_t, String> {
    unsafe {
        INIT.call_once(|| {
            rbs_constant_pool_init(RBS_GLOBAL_CONSTANT_POOL, 26);
        });

        let start_ptr = rbs_code.as_ptr() as *const i8;
        let end_ptr = start_ptr.add(rbs_code.len());

        let raw_rbs_string_value = rbs_string_new(start_ptr, end_ptr);

        let encoding_ptr = &rbs_encodings[RBS_ENCODING_UTF_8 as usize] as *const rbs_encoding_t;
        let parser = rbs_parser_new(raw_rbs_string_value, encoding_ptr, 0, rbs_code.len() as i32);

        let mut signature: *mut rbs_signature_t = std::ptr::null_mut();
        let result = rbs_parse_signature(parser, &mut signature);

        rbs_parser_free(parser);

        if result {
            Ok(signature)
        } else {
            Err(String::from("Failed to parse RBS signature"))
        }
    }
}

pub struct NodeListIter {
    parser: *mut rbs_parser_t,
    current: *mut rbs_node_list_node_t,
}

impl Iterator for NodeListIter {
    type Item = Node;

    fn next(&mut self) -> Option<Self::Item> {
        if self.current.is_null() {
            None
        } else {
            let pointer_data = unsafe { *self.current };
            let node = unsafe { Node::new(self.parser, pointer_data.node) };
            self.current = pointer_data.next;
            Some(node)
        }
    }
}

pub struct NodeList {
    parser: *mut rbs_parser_t,
    pointer: *mut rbs_node_list_t,
}

impl NodeList {
    /// Returns an iterator over the nodes.
    #[must_use]
    pub fn iter(&self) -> NodeListIter {
        NodeListIter {
            parser: self.parser,
            current: unsafe { (*self.pointer).head },
        }
    }
}

pub struct RBSString {
    pointer: *const rbs_string_t,
}

impl RBSString {
    pub fn new(pointer: *const rbs_string_t) -> Self {
        Self { pointer }
    }

    pub fn as_bytes(&self) -> &[u8] {
        unsafe {
            let s = *self.pointer;
            std::slice::from_raw_parts(s.start as *const u8, s.end.offset_from(s.start) as usize)
        }
    }
}

pub struct RBSSymbol {
    pointer: *const rbs_ast_symbol_t,
    parser: *mut rbs_parser_t,
}

impl RBSSymbol {
    pub fn new(pointer: *const rbs_ast_symbol_t, parser: *mut rbs_parser_t) -> Self {
        Self { pointer, parser }
    }

    pub fn name(&self) -> &[u8] {
        unsafe {
            let constant_ptr = rbs_constant_pool_id_to_constant(
                &(*self.parser).constant_pool,
                (*self.pointer).constant_id,
            );
            if constant_ptr.is_null() {
                panic!("Constant ID for symbol is not present in the pool");
            }

            let constant = &*constant_ptr;
            std::slice::from_raw_parts(constant.start, constant.length)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse() {
        let rbs_code = r#"type foo = "hello""#;
        let signature = parse(rbs_code.as_bytes());
        assert!(signature.is_ok(), "Failed to parse RBS signature");

        let rbs_code2 = r#"class Foo end"#;
        let signature2 = parse(rbs_code2.as_bytes());
        assert!(signature2.is_ok(), "Failed to parse RBS signature");
    }
}

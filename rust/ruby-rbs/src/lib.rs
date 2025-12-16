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
pub fn parse(rbs_code: &[u8]) -> Result<SignatureNode, String> {
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

        let signature_node = SignatureNode {
            parser,
            pointer: signature,
        };

        if result {
            Ok(signature_node)
        } else {
            Err(String::from("Failed to parse RBS signature"))
        }
    }
}

impl Drop for SignatureNode {
    fn drop(&mut self) {
        unsafe {
            rbs_parser_free(self.parser);
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
            let node = Node::new(self.parser, pointer_data.node);
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
    pub fn new(parser: *mut rbs_parser_t, pointer: *mut rbs_node_list_t) -> Self {
        Self { parser, pointer }
    }

    /// Returns an iterator over the nodes.
    #[must_use]
    pub fn iter(&self) -> NodeListIter {
        NodeListIter {
            parser: self.parser,
            current: unsafe { (*self.pointer).head },
        }
    }
}

pub struct RBSHash {
    parser: *mut rbs_parser_t,
    pointer: *mut rbs_hash,
}

impl RBSHash {
    pub fn new(parser: *mut rbs_parser_t, pointer: *mut rbs_hash) -> Self {
        Self { parser, pointer }
    }

    /// Returns an iterator over the key-value pairs.
    #[must_use]
    pub fn iter(&self) -> RBSHashIter {
        RBSHashIter {
            parser: self.parser,
            current: unsafe { (*self.pointer).head },
        }
    }
}

pub struct RBSHashIter {
    parser: *mut rbs_parser_t,
    current: *mut rbs_hash_node_t,
}

impl Iterator for RBSHashIter {
    type Item = (Node, Node);

    fn next(&mut self) -> Option<Self::Item> {
        if self.current.is_null() {
            None
        } else {
            let pointer_data = unsafe { *self.current };
            let key = Node::new(self.parser, pointer_data.key);
            let value = Node::new(self.parser, pointer_data.value);
            self.current = pointer_data.next;
            Some((key, value))
        }
    }
}

pub struct RBSLocation {
    pointer: *const rbs_location_t,
    #[allow(dead_code)]
    parser: *mut rbs_parser_t,
}

impl RBSLocation {
    pub fn new(pointer: *const rbs_location_t, parser: *mut rbs_parser_t) -> Self {
        Self { pointer, parser }
    }

    pub fn start_loc(&self) -> i32 {
        unsafe { (*self.pointer).rg.start.byte_pos }
    }

    pub fn end_loc(&self) -> i32 {
        unsafe { (*self.pointer).rg.end.byte_pos }
    }
}

pub struct RBSLocationListIter {
    current: *mut rbs_location_list_node_t,
    parser: *mut rbs_parser_t,
}

impl Iterator for RBSLocationListIter {
    type Item = RBSLocation;

    fn next(&mut self) -> Option<Self::Item> {
        if self.current.is_null() {
            None
        } else {
            let pointer_data = unsafe { *self.current };
            let loc = RBSLocation::new(pointer_data.loc, self.parser);
            self.current = pointer_data.next;
            Some(loc)
        }
    }
}

pub struct RBSLocationList {
    pointer: *mut rbs_location_list,
    parser: *mut rbs_parser_t,
}

impl RBSLocationList {
    pub fn new(pointer: *mut rbs_location_list, parser: *mut rbs_parser_t) -> Self {
        Self { pointer, parser }
    }

    /// Returns an iterator over the locations.
    #[must_use]
    pub fn iter(&self) -> RBSLocationListIter {
        RBSLocationListIter {
            current: unsafe { (*self.pointer).head },
            parser: self.parser,
        }
    }
}

#[derive(Debug)]
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

impl SymbolNode {
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

impl KeywordNode {
    pub fn name(&self) -> &[u8] {
        unsafe {
            let constant_ptr = rbs_constant_pool_id_to_constant(
                &(*self.parser).constant_pool,
                (*self.pointer).constant_id,
            );
            if constant_ptr.is_null() {
                panic!("Constant ID for keyword is not present in the pool");
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

    #[test]
    fn test_parse_integer() {
        let rbs_code = r#"type foo = 1"#;
        let signature = parse(rbs_code.as_bytes());
        assert!(signature.is_ok(), "Failed to parse RBS signature");

        let signature_node = signature.unwrap();
        if let Node::TypeAlias(node) = signature_node.declarations().iter().next().unwrap()
            && let Node::LiteralType(literal) = node.type_()
            && let Node::Integer(integer) = literal.literal()
        {
            assert_eq!(
                "1".to_string(),
                String::from_utf8(integer.string_representation().as_bytes().to_vec()).unwrap()
            );
        } else {
            panic!("No literal type node found");
        }
    }

    #[test]
    fn test_rbs_hash_via_record_type() {
        // RecordType stores its fields in an RBSHash via all_fields()
        let rbs_code = r#"type foo = { name: String, age: Integer }"#;
        let signature = parse(rbs_code.as_bytes());
        assert!(signature.is_ok(), "Failed to parse RBS signature");

        let signature_node = signature.unwrap();
        if let Node::TypeAlias(type_alias) = signature_node.declarations().iter().next().unwrap()
            && let Node::RecordType(record) = type_alias.type_()
        {
            let hash = record.all_fields();
            let fields: Vec<_> = hash.iter().collect();
            assert_eq!(fields.len(), 2, "Expected 2 fields in record");

            // Build a map of field names to type names
            let mut field_types: Vec<(String, String)> = Vec::new();
            for (key, value) in &fields {
                let Node::Symbol(sym) = key else {
                    panic!("Expected Symbol key");
                };
                let Node::RecordFieldType(field_type) = value else {
                    panic!("Expected RecordFieldType value");
                };
                let Node::ClassInstanceType(class_type) = field_type.type_() else {
                    panic!("Expected ClassInstanceType");
                };

                let key_name = String::from_utf8(sym.name().to_vec()).unwrap();
                let type_name_node = class_type.name();
                let type_name_sym = type_name_node.name();
                let type_name = String::from_utf8(type_name_sym.name().to_vec()).unwrap();
                field_types.push((key_name, type_name));
            }

            assert!(
                field_types.contains(&("name".to_string(), "String".to_string())),
                "Expected 'name: String'"
            );
            assert!(
                field_types.contains(&("age".to_string(), "Integer".to_string())),
                "Expected 'age: Integer'"
            );
        } else {
            panic!("Expected TypeAlias with RecordType");
        }
    }
}

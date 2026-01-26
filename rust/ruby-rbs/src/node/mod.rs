include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
use rbs_encoding_type_t::RBS_ENCODING_UTF_8;
use ruby_rbs_sys::bindings::*;
use std::marker::PhantomData;
use std::ptr::NonNull;
use std::sync::Once;

static INIT: Once = Once::new();

/// Parse RBS code into an AST.
///
/// ```rust
/// use ruby_rbs::node::parse;
/// let rbs_code = r#"type foo = "hello""#;
/// let signature = parse(rbs_code.as_bytes());
/// assert!(signature.is_ok(), "Failed to parse RBS signature");
/// ```
pub fn parse(rbs_code: &[u8]) -> Result<SignatureNode<'_>, String> {
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
            parser: NonNull::new_unchecked(parser),
            pointer: signature,
            marker: PhantomData,
        };

        if result {
            Ok(signature_node)
        } else {
            Err(String::from("Failed to parse RBS signature"))
        }
    }
}

impl Drop for SignatureNode<'_> {
    fn drop(&mut self) {
        unsafe {
            rbs_parser_free(self.parser.as_ptr());
        }
    }
}

impl KeywordNode<'_> {
    #[must_use]
    pub fn name(&self) -> &[u8] {
        unsafe {
            let constant_ptr = rbs_constant_pool_id_to_constant(
                &(*self.parser.as_ptr()).constant_pool,
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

pub struct NodeList<'a> {
    parser: NonNull<rbs_parser_t>,
    pointer: *mut rbs_node_list_t,
    marker: PhantomData<&'a mut rbs_node_list_t>,
}

impl<'a> NodeList<'a> {
    #[must_use]
    pub fn new(parser: NonNull<rbs_parser_t>, pointer: *mut rbs_node_list_t) -> Self {
        Self {
            parser,
            pointer,
            marker: PhantomData,
        }
    }

    /// Returns an iterator over the nodes.
    #[must_use]
    pub fn iter(&self) -> NodeListIter<'a> {
        NodeListIter {
            parser: self.parser,
            current: unsafe { (*self.pointer).head },
            marker: PhantomData,
        }
    }
}

pub struct NodeListIter<'a> {
    parser: NonNull<rbs_parser_t>,
    current: *mut rbs_node_list_node_t,
    marker: PhantomData<&'a mut rbs_node_list_node_t>,
}

impl<'a> Iterator for NodeListIter<'a> {
    type Item = Node<'a>;

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

pub struct RBSHash<'a> {
    parser: NonNull<rbs_parser_t>,
    pointer: *mut rbs_hash,
    marker: PhantomData<&'a mut rbs_hash>,
}

impl<'a> RBSHash<'a> {
    #[must_use]
    pub fn new(parser: NonNull<rbs_parser_t>, pointer: *mut rbs_hash) -> Self {
        Self {
            parser,
            pointer,
            marker: PhantomData,
        }
    }

    /// Returns an iterator over the key-value pairs.
    #[must_use]
    pub fn iter(&self) -> RBSHashIter<'a> {
        RBSHashIter {
            parser: self.parser,
            current: unsafe { (*self.pointer).head },
            marker: PhantomData,
        }
    }
}

pub struct RBSHashIter<'a> {
    parser: NonNull<rbs_parser_t>,
    current: *mut rbs_hash_node_t,
    marker: PhantomData<&'a mut rbs_hash_node_t>,
}

impl<'a> Iterator for RBSHashIter<'a> {
    type Item = (Node<'a>, Node<'a>);

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
}

impl RBSLocation {
    #[must_use]
    pub fn new(pointer: *const rbs_location_t) -> Self {
        Self { pointer }
    }

    #[must_use]
    pub fn start(&self) -> i32 {
        unsafe { (*self.pointer).rg.start.byte_pos }
    }

    #[must_use]
    pub fn end(&self) -> i32 {
        unsafe { (*self.pointer).rg.end.byte_pos }
    }
}

pub struct RBSLocationList {
    pointer: *mut rbs_location_list,
}

impl RBSLocationList {
    #[must_use]
    pub fn new(pointer: *mut rbs_location_list) -> Self {
        Self { pointer }
    }

    /// Returns an iterator over the locations.
    #[must_use]
    pub fn iter(&self) -> RBSLocationListIter {
        RBSLocationListIter {
            current: unsafe { (*self.pointer).head },
        }
    }
}

pub struct RBSLocationListIter {
    current: *mut rbs_location_list_node_t,
}

impl Iterator for RBSLocationListIter {
    type Item = RBSLocation;

    fn next(&mut self) -> Option<Self::Item> {
        if self.current.is_null() {
            None
        } else {
            let pointer_data = unsafe { *self.current };
            let loc = RBSLocation::new(pointer_data.loc);
            self.current = pointer_data.next;
            Some(loc)
        }
    }
}

#[derive(Debug)]
pub struct RBSString {
    pointer: *const rbs_string_t,
}

impl RBSString {
    #[must_use]
    pub fn new(pointer: *const rbs_string_t) -> Self {
        Self { pointer }
    }

    #[must_use]
    pub fn as_bytes(&self) -> &[u8] {
        unsafe {
            let s = *self.pointer;
            std::slice::from_raw_parts(s.start as *const u8, s.end.offset_from(s.start) as usize)
        }
    }
}

impl SymbolNode<'_> {
    #[must_use]
    pub fn name(&self) -> &[u8] {
        unsafe {
            let constant_ptr = rbs_constant_pool_id_to_constant(
                &(*self.parser.as_ptr()).constant_pool,
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

    #[test]
    fn visitor_test() {
        struct Visitor {
            visited: Vec<String>,
        }

        impl Visit for Visitor {
            fn visit_bool_type_node(&mut self, node: &BoolTypeNode) {
                self.visited.push("type:bool".to_string());

                crate::node::visit_bool_type_node(self, node);
            }

            fn visit_class_node(&mut self, node: &ClassNode) {
                self.visited.push(format!(
                    "class:{}",
                    String::from_utf8(node.name().name().name().to_vec()).unwrap()
                ));

                crate::node::visit_class_node(self, node);
            }

            fn visit_class_instance_type_node(&mut self, node: &ClassInstanceTypeNode) {
                self.visited.push(format!(
                    "type:{}",
                    String::from_utf8(node.name().name().name().to_vec()).unwrap()
                ));

                crate::node::visit_class_instance_type_node(self, node);
            }

            fn visit_class_super_node(&mut self, node: &ClassSuperNode) {
                self.visited.push(format!(
                    "super:{}",
                    String::from_utf8(node.name().name().name().to_vec()).unwrap()
                ));

                crate::node::visit_class_super_node(self, node);
            }

            fn visit_function_type_node(&mut self, node: &FunctionTypeNode) {
                let count = node.required_positionals().iter().count();
                self.visited
                    .push(format!("function:required_positionals:{count}"));

                crate::node::visit_function_type_node(self, node);
            }

            fn visit_method_definition_node(&mut self, node: &MethodDefinitionNode) {
                self.visited.push(format!(
                    "method:{}",
                    String::from_utf8(node.name().name().to_vec()).unwrap()
                ));

                crate::node::visit_method_definition_node(self, node);
            }

            fn visit_record_type_node(&mut self, node: &RecordTypeNode) {
                self.visited.push("record".to_string());

                crate::node::visit_record_type_node(self, node);
            }

            fn visit_symbol_node(&mut self, node: &SymbolNode) {
                self.visited.push(format!(
                    "symbol:{}",
                    String::from_utf8(node.name().to_vec()).unwrap()
                ));

                crate::node::visit_symbol_node(self, node);
            }
        }

        let rbs_code = r#"
            class Foo < Bar
                def process: ({ name: String, age: Integer }, bool) -> void
            end
        "#;

        let signature = parse(rbs_code.as_bytes()).unwrap();

        let mut visitor = Visitor {
            visited: Vec::new(),
        };

        visitor.visit(&signature.as_node());

        assert_eq!(
            vec![
                "class:Foo",
                "symbol:Foo",
                "super:Bar",
                "symbol:Bar",
                "method:process",
                "symbol:process",
                "function:required_positionals:2",
                "record",
                "symbol:name",
                "type:String",
                "symbol:String",
                "symbol:age",
                "type:Integer",
                "symbol:Integer",
                "type:bool",
            ],
            visitor.visited
        );
    }

    #[test]
    fn test_node_location_ranges() {
        let rbs_code = r#"type foo = 1"#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let declaration = signature.declarations().iter().next().unwrap();
        let Node::TypeAlias(type_alias) = declaration else {
            panic!("Expected TypeAlias");
        };

        // TypeAlias spans the entire declaration
        let loc = type_alias.location();
        assert_eq!(0, loc.start());
        assert_eq!(12, loc.end());

        // The literal "1" is at position 11-12
        let Node::LiteralType(literal) = type_alias.type_() else {
            panic!("Expected LiteralType");
        };
        let Node::Integer(integer) = literal.literal() else {
            panic!("Expected Integer");
        };

        let int_loc = integer.location();
        assert_eq!(11, int_loc.start());
        assert_eq!(12, int_loc.end());
    }
}

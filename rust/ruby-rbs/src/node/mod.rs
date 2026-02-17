include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
use rbs_encoding_type_t::RBS_ENCODING_UTF_8;
use ruby_rbs_sys::bindings::*;
use std::marker::PhantomData;
use std::ptr::NonNull;

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

/// Instance variable name specification for attributes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AttrIvarName {
    /// The attribute has inferred instance variable (nil)
    Unspecified,
    /// The attribute has no instance variable (false)
    Empty,
    /// The attribute has instance variable with the given name
    Name(rbs_constant_id_t),
}

impl AttrIvarName {
    /// Converts the raw C struct to the Rust enum.
    #[must_use]
    pub fn from_raw(raw: rbs_attr_ivar_name_t) -> Self {
        match raw.tag {
            rbs_attr_ivar_name_tag::RBS_ATTR_IVAR_NAME_TAG_UNSPECIFIED => Self::Unspecified,
            rbs_attr_ivar_name_tag::RBS_ATTR_IVAR_NAME_TAG_EMPTY => Self::Empty,
            rbs_attr_ivar_name_tag::RBS_ATTR_IVAR_NAME_TAG_NAME => Self::Name(raw.name),
            _ => panic!("Unknown ivar_name_tag: {}", raw.tag),
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

pub struct RBSLocationRange {
    range: rbs_location_range,
}

impl RBSLocationRange {
    #[must_use]
    pub fn new(range: rbs_location_range) -> Self {
        Self { range }
    }

    #[must_use]
    pub fn start(&self) -> i32 {
        self.range.start_byte
    }

    #[must_use]
    pub fn end(&self) -> i32 {
        self.range.end_byte
    }
}

pub struct RBSLocationRangeList<'a> {
    #[allow(dead_code)]
    parser: NonNull<rbs_parser_t>,
    pointer: *mut rbs_location_range_list_t,
    marker: PhantomData<&'a mut rbs_location_range_list_t>,
}

impl<'a> RBSLocationRangeList<'a> {
    /// Returns an iterator over the location ranges.
    #[must_use]
    pub fn iter(&self) -> RBSLocationRangeListIter {
        RBSLocationRangeListIter {
            current: unsafe { (*self.pointer).head },
        }
    }
}

pub struct RBSLocationRangeListIter {
    current: *mut rbs_location_range_list_node_t,
}

impl Iterator for RBSLocationRangeListIter {
    type Item = RBSLocationRange;

    fn next(&mut self) -> Option<Self::Item> {
        if self.current.is_null() {
            None
        } else {
            let pointer_data = unsafe { *self.current };
            let range = RBSLocationRange::new(pointer_data.range);
            self.current = pointer_data.next;
            Some(range)
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

    #[test]
    fn test_sub_locations() {
        let rbs_code = r#"class Foo < Bar end"#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let declaration = signature.declarations().iter().next().unwrap();
        let Node::Class(class) = declaration else {
            panic!("Expected Class");
        };

        // Test required sub-locations
        let keyword_loc = class.keyword_location();
        assert_eq!(0, keyword_loc.start());
        assert_eq!(5, keyword_loc.end());

        let name_loc = class.name_location();
        assert_eq!(6, name_loc.start());
        assert_eq!(9, name_loc.end());

        let end_loc = class.end_location();
        assert_eq!(16, end_loc.start());
        assert_eq!(19, end_loc.end());

        // Test optional sub-location that's present
        let lt_loc = class.lt_location();
        assert!(lt_loc.is_some());
        let lt = lt_loc.unwrap();
        assert_eq!(10, lt.start());
        assert_eq!(11, lt.end());

        // Test optional sub-location that's not present (no type params in this class)
        let type_params_loc = class.type_params_location();
        assert!(type_params_loc.is_none());
    }

    #[test]
    fn test_type_alias_sub_locations() {
        let rbs_code = r#"type foo = String"#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let declaration = signature.declarations().iter().next().unwrap();
        let Node::TypeAlias(type_alias) = declaration else {
            panic!("Expected TypeAlias");
        };

        // Test required sub-locations
        let keyword_loc = type_alias.keyword_location();
        assert_eq!(0, keyword_loc.start());
        assert_eq!(4, keyword_loc.end());

        let name_loc = type_alias.name_location();
        assert_eq!(5, name_loc.start());
        assert_eq!(8, name_loc.end());

        let eq_loc = type_alias.eq_location();
        assert_eq!(9, eq_loc.start());
        assert_eq!(10, eq_loc.end());

        // Test optional sub-location that's not present (no type params)
        let type_params_loc = type_alias.type_params_location();
        assert!(type_params_loc.is_none());
    }

    #[test]
    fn test_module_sub_locations() {
        let rbs_code = r#"module Foo[T] : Bar end"#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let declaration = signature.declarations().iter().next().unwrap();
        let Node::Module(module) = declaration else {
            panic!("Expected Module");
        };

        // Test required sub-locations
        let keyword_loc = module.keyword_location();
        assert_eq!(0, keyword_loc.start());
        assert_eq!(6, keyword_loc.end());

        let name_loc = module.name_location();
        assert_eq!(7, name_loc.start());
        assert_eq!(10, name_loc.end());

        let end_loc = module.end_location();
        assert_eq!(20, end_loc.start());
        assert_eq!(23, end_loc.end());

        // Test optional sub-locations that are present
        let type_params_loc = module.type_params_location();
        assert!(type_params_loc.is_some());
        let tp = type_params_loc.unwrap();
        assert_eq!(10, tp.start());
        assert_eq!(13, tp.end());

        let colon_loc = module.colon_location();
        assert!(colon_loc.is_some());
        let colon = colon_loc.unwrap();
        assert_eq!(14, colon.start());
        assert_eq!(15, colon.end());

        let self_types_loc = module.self_types_location();
        assert!(self_types_loc.is_some());
        let st = self_types_loc.unwrap();
        assert_eq!(16, st.start());
        assert_eq!(19, st.end());
    }

    #[test]
    fn test_enum_types() {
        let rbs_code = r#"
            class Foo
                attr_reader name: String
                def self.process: () -> void
                alias instance_method target_method
                alias self.singleton_method self.target_method
            end

            class Bar[out T, in U, V]
            end
        "#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let declarations: Vec<_> = signature.declarations().iter().collect();

        // Test class Foo
        let Node::Class(class_foo) = &declarations[0] else {
            panic!("Expected Class");
        };

        let members: Vec<_> = class_foo.members().iter().collect();

        // attr_reader - should be instance with unspecified visibility (default)
        if let Node::AttrReader(attr) = &members[0] {
            assert_eq!(attr.kind(), AttributeKind::Instance);
            assert_eq!(attr.visibility(), AttributeVisibility::Unspecified);
        } else {
            panic!("Expected AttrReader");
        }

        // def self.process - should be singleton method with unspecified visibility (default)
        if let Node::MethodDefinition(method) = &members[1] {
            assert_eq!(method.kind(), MethodDefinitionKind::Singleton);
            assert_eq!(method.visibility(), MethodDefinitionVisibility::Unspecified);
        } else {
            panic!("Expected MethodDefinition");
        }

        // alias instance_method
        if let Node::Alias(alias) = &members[2] {
            assert_eq!(alias.kind(), AliasKind::Instance);
        } else {
            panic!("Expected Alias");
        }

        // alias self.singleton_method
        if let Node::Alias(alias) = &members[3] {
            assert_eq!(alias.kind(), AliasKind::Singleton);
        } else {
            panic!("Expected Alias");
        }

        // Test class Bar with type params
        let Node::Class(class_bar) = &declarations[1] else {
            panic!("Expected Class");
        };

        let type_params: Vec<_> = class_bar.type_params().iter().collect();
        assert_eq!(type_params.len(), 3);

        // out T - covariant
        if let Node::TypeParam(param) = &type_params[0] {
            assert_eq!(param.variance(), TypeParamVariance::Covariant);
        } else {
            panic!("Expected TypeParam");
        }

        // in U - contravariant
        if let Node::TypeParam(param) = &type_params[1] {
            assert_eq!(param.variance(), TypeParamVariance::Contravariant);
        } else {
            panic!("Expected TypeParam");
        }

        // V - invariant (default)
        if let Node::TypeParam(param) = &type_params[2] {
            assert_eq!(param.variance(), TypeParamVariance::Invariant);
        } else {
            panic!("Expected TypeParam");
        }
    }

    #[test]
    fn test_ivar_name_enum() {
        let rbs_code = r#"
            class Foo
                attr_reader name: String
                attr_accessor age(): Integer
                attr_writer email(@email): String
            end
        "#;
        let signature = parse(rbs_code.as_bytes()).unwrap();

        let Node::Class(class) = signature.declarations().iter().next().unwrap() else {
            panic!("Expected Class");
        };

        let members: Vec<_> = class.members().iter().collect();

        // attr_reader name: String - should be Unspecified (inferred as @name)
        if let Node::AttrReader(attr) = &members[0] {
            let ivar = attr.ivar_name();
            assert_eq!(ivar, AttrIvarName::Unspecified);
        } else {
            panic!("Expected AttrReader");
        }

        // attr_accessor age(): Integer - should be Empty (no ivar)
        if let Node::AttrAccessor(attr) = &members[1] {
            let ivar = attr.ivar_name();
            assert_eq!(ivar, AttrIvarName::Empty);
        } else {
            panic!("Expected AttrAccessor");
        }

        // attr_writer email(@email): String - should be Name with constant ID
        if let Node::AttrWriter(attr) = &members[2] {
            let ivar = attr.ivar_name();
            match ivar {
                AttrIvarName::Name(id) => {
                    assert!(id > 0, "Expected valid constant ID");
                }
                _ => panic!("Expected AttrIvarName::Name, got {:?}", ivar),
            }
        } else {
            panic!("Expected AttrWriter");
        }
    }
}

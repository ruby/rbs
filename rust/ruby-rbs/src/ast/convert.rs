use crate::ast::location::{
    AliasLocation, ClassInstanceLocation, ClassSingletonLocation, FunctionParamLocation,
    InterfaceLocation, LocationRange, MethodTypeLocation, TypeParamLocation,
};
use crate::ast::method_type::MethodType;
use crate::ast::type_param::{TypeParam, Variance};
use crate::ast::types::{
    AliasType, BaseType, BaseTypeKind, BlockType, ClassInstanceType, ClassSingletonType, Function,
    FunctionParam, FunctionType, InterfaceType, IntersectionType, KeywordParam, Literal,
    LiteralType, OptionalType, ProcType, RecordField, RecordKey, RecordType, TupleType, Type,
    UnionType, UntypedFunctionType, VariableType,
};
use crate::ids::{SymbolId, TypeName};
use crate::interner::StringInterner;
use crate::node::{
    AliasTypeNode, BlockTypeNode, ClassInstanceTypeNode, ClassSingletonTypeNode, FunctionParamNode,
    FunctionTypeNode, InterfaceTypeNode, MethodTypeNode, Node, RBSLocationRange, SymbolNode,
    TypeNameNode, TypeParamNode, TypeParamVariance, UntypedFunctionTypeNode,
};
use crate::type_name::TypeNameInterner;

pub struct AstConverter<'a> {
    strings: &'a mut StringInterner,
    type_names: &'a mut TypeNameInterner,
}

impl<'a> AstConverter<'a> {
    pub fn new(strings: &'a mut StringInterner, type_names: &'a mut TypeNameInterner) -> Self {
        Self {
            strings,
            type_names,
        }
    }

    pub fn convert_type(&mut self, node: &Node<'_>) -> Type {
        match node {
            Node::AliasType(node) => Type::Alias(self.convert_alias_type(node)),
            Node::AnyType(node) => Type::Base(BaseType {
                kind: BaseTypeKind::Any { todo: node.todo() },
                location: Some(convert_range(node.location())),
            }),
            Node::BoolType(node) => self.base(BaseTypeKind::Bool, node.location()),
            Node::BottomType(node) => self.base(BaseTypeKind::Bottom, node.location()),
            Node::ClassType(node) => self.base(BaseTypeKind::Class, node.location()),
            Node::InstanceType(node) => self.base(BaseTypeKind::Instance, node.location()),
            Node::NilType(node) => self.base(BaseTypeKind::Nil, node.location()),
            Node::SelfType(node) => self.base(BaseTypeKind::SelfType, node.location()),
            Node::TopType(node) => self.base(BaseTypeKind::Top, node.location()),
            Node::VoidType(node) => self.base(BaseTypeKind::Void, node.location()),
            Node::ClassInstanceType(node) => {
                Type::ClassInstance(self.convert_class_instance_type(node))
            }
            Node::ClassSingletonType(node) => {
                Type::ClassSingleton(self.convert_class_singleton_type(node))
            }
            Node::InterfaceType(node) => Type::Interface(self.convert_interface_type(node)),
            Node::IntersectionType(node) => Type::Intersection(IntersectionType {
                types: self.convert_type_list(node.types()),
                location: Some(convert_range(node.location())),
            }),
            Node::LiteralType(node) => Type::Literal(LiteralType {
                literal: self.convert_literal(&node.literal()),
                location: Some(convert_range(node.location())),
            }),
            Node::OptionalType(node) => Type::Optional(OptionalType {
                ty: Box::new(self.convert_type(&node.type_())),
                location: Some(convert_range(node.location())),
            }),
            Node::ProcType(node) => Type::Proc(ProcType {
                function: self.convert_function_type(&node.type_()),
                block: node.block().map(|block| self.convert_block_type(&block)),
                self_type: node.self_type().map(|ty| Box::new(self.convert_type(&ty))),
                location: Some(convert_range(node.location())),
            }),
            Node::RecordType(node) => {
                let mut fields = Vec::new();
                for (key, value) in node.all_fields().iter() {
                    let key = self.convert_record_key(&key);
                    let Node::RecordFieldType(field) = value else {
                        panic_expected("record field value while converting record type", &value);
                    };
                    fields.push(RecordField {
                        key,
                        ty: self.convert_type(&field.type_()),
                        required: field.required(),
                    });
                }
                Type::Record(RecordType {
                    fields,
                    location: Some(convert_range(node.location())),
                })
            }
            Node::TupleType(node) => Type::Tuple(TupleType {
                types: self.convert_type_list(node.types()),
                location: Some(convert_range(node.location())),
            }),
            Node::UnionType(node) => Type::Union(UnionType {
                types: self.convert_type_list(node.types()),
                location: Some(convert_range(node.location())),
            }),
            Node::VariableType(node) => Type::Variable(VariableType {
                name: self.intern_symbol(&node.name()),
                location: Some(convert_range(node.location())),
            }),
            _ => panic_expected("type node while converting type", node),
        }
    }

    pub fn convert_function_type(&mut self, node: &Node<'_>) -> Function {
        match node {
            Node::FunctionType(node) => Function::Typed(self.convert_function(node)),
            Node::UntypedFunctionType(node) => {
                Function::Untyped(self.convert_untyped_function(node))
            }
            _ => panic_expected("function type node while converting function type", node),
        }
    }

    pub fn convert_method_type(&mut self, node: &MethodTypeNode<'_>) -> MethodType {
        MethodType {
            type_params: self.convert_type_params(node.type_params()),
            function: self.convert_function_type(&node.type_()),
            block: node.block().map(|block| self.convert_block_type(&block)),
            location: Some(MethodTypeLocation {
                range: convert_range(node.location()),
                type_range: convert_range(node.type_location()),
                type_params_range: convert_optional_range(node.type_params_location()),
            }),
        }
    }

    fn base(&self, kind: BaseTypeKind, location: RBSLocationRange) -> Type {
        Type::Base(BaseType {
            kind,
            location: Some(convert_range(location)),
        })
    }

    fn convert_alias_type(&mut self, node: &AliasTypeNode<'_>) -> AliasType {
        AliasType {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(AliasLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_class_instance_type(
        &mut self,
        node: &ClassInstanceTypeNode<'_>,
    ) -> ClassInstanceType {
        ClassInstanceType {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(ClassInstanceLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_class_singleton_type(
        &mut self,
        node: &ClassSingletonTypeNode<'_>,
    ) -> ClassSingletonType {
        ClassSingletonType {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(ClassSingletonLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_interface_type(&mut self, node: &InterfaceTypeNode<'_>) -> InterfaceType {
        InterfaceType {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(InterfaceLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_function(&mut self, node: &FunctionTypeNode<'_>) -> FunctionType {
        FunctionType {
            required_positionals: self.convert_function_params(node.required_positionals()),
            optional_positionals: self.convert_function_params(node.optional_positionals()),
            rest_positionals: node
                .rest_positionals()
                .map(|param| Box::new(self.convert_function_param_node(&param))),
            trailing_positionals: self.convert_function_params(node.trailing_positionals()),
            required_keywords: self.convert_keyword_params(node.required_keywords()),
            optional_keywords: self.convert_keyword_params(node.optional_keywords()),
            rest_keywords: node
                .rest_keywords()
                .map(|param| Box::new(self.convert_function_param_node(&param))),
            return_type: Box::new(self.convert_type(&node.return_type())),
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_untyped_function(
        &mut self,
        node: &UntypedFunctionTypeNode<'_>,
    ) -> UntypedFunctionType {
        UntypedFunctionType {
            return_type: Box::new(self.convert_type(&node.return_type())),
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_block_type(&mut self, node: &BlockTypeNode<'_>) -> BlockType {
        BlockType {
            function: self.convert_function_type(&node.type_()),
            required: node.required(),
            self_type: node.self_type().map(|ty| Box::new(self.convert_type(&ty))),
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_function_param_node(&mut self, node: &Node<'_>) -> FunctionParam {
        let Node::FunctionParam(node) = node else {
            panic_expected(
                "function parameter node while converting function type",
                node,
            );
        };
        self.convert_function_param(node)
    }

    fn convert_function_param(&mut self, node: &FunctionParamNode<'_>) -> FunctionParam {
        FunctionParam {
            ty: Box::new(self.convert_type(&node.type_())),
            name: node.name().map(|name| self.intern_symbol(&name)),
            location: Some(FunctionParamLocation {
                range: convert_range(node.location()),
                name_range: convert_optional_range(node.name_location()),
            }),
        }
    }

    fn convert_type_param_node(&mut self, node: &Node<'_>) -> TypeParam {
        let Node::TypeParam(node) = node else {
            panic_expected("type parameter node while converting type parameters", node);
        };
        self.convert_type_param(node)
    }

    fn convert_type_param(&mut self, node: &TypeParamNode<'_>) -> TypeParam {
        TypeParam {
            name: self.intern_symbol(&node.name()),
            variance: convert_variance(node.variance()),
            upper_bound: node.upper_bound().map(|ty| self.convert_type(&ty)),
            lower_bound: node.lower_bound().map(|ty| self.convert_type(&ty)),
            default_type: node.default_type().map(|ty| self.convert_type(&ty)),
            unchecked: node.unchecked(),
            location: Some(TypeParamLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                variance_range: convert_optional_range(node.variance_location()),
                unchecked_range: convert_optional_range(node.unchecked_location()),
                upper_bound_range: convert_optional_range(node.upper_bound_location()),
                lower_bound_range: convert_optional_range(node.lower_bound_location()),
                default_range: convert_optional_range(node.default_location()),
            }),
        }
    }

    fn convert_type_list(&mut self, list: crate::node::NodeList<'_>) -> Vec<Type> {
        list.iter().map(|node| self.convert_type(&node)).collect()
    }

    fn convert_function_params(&mut self, list: crate::node::NodeList<'_>) -> Vec<FunctionParam> {
        list.iter()
            .map(|node| self.convert_function_param_node(&node))
            .collect()
    }

    fn convert_type_params(&mut self, list: crate::node::NodeList<'_>) -> Vec<TypeParam> {
        list.iter()
            .map(|node| self.convert_type_param_node(&node))
            .collect()
    }

    fn convert_keyword_params(&mut self, hash: crate::node::RBSHash<'_>) -> Vec<KeywordParam> {
        hash.iter()
            .map(|(key, value)| {
                let Node::Symbol(symbol) = key else {
                    panic_expected(
                        "symbol keyword name while converting keyword parameter",
                        &key,
                    );
                };
                KeywordParam {
                    name: self.intern_symbol(&symbol),
                    param: self.convert_function_param_node(&value),
                }
            })
            .collect()
    }

    fn convert_record_key(&mut self, node: &Node<'_>) -> RecordKey {
        match node {
            Node::Symbol(symbol) => RecordKey::Symbol(self.intern_symbol(symbol)),
            Node::String(string) => RecordKey::String(string.string().as_str().to_owned()),
            Node::Integer(integer) => {
                RecordKey::Integer(integer.string_representation().as_str().to_owned())
            }
            Node::Bool(boolean) => RecordKey::Bool(boolean.value()),
            _ => panic_expected("record key while converting record type", node),
        }
    }

    fn convert_literal(&mut self, node: &Node<'_>) -> Literal {
        match node {
            Node::String(string) => Literal::String(string.string().as_str().to_owned()),
            Node::Integer(integer) => {
                Literal::Integer(integer.string_representation().as_str().to_owned())
            }
            Node::Symbol(symbol) => Literal::Symbol(self.intern_symbol(symbol)),
            Node::Bool(boolean) => Literal::Bool(boolean.value()),
            _ => panic_expected("literal value while converting literal type", node),
        }
    }

    fn convert_type_name(&mut self, node: &TypeNameNode<'_>) -> TypeName {
        let namespace = node.namespace();
        let mut name = self.type_names.root(namespace.absolute());
        for segment_node in namespace.path().iter() {
            match segment_node {
                Node::Symbol(segment) => {
                    let segment = self.intern_symbol(&segment);
                    name = self.type_names.append(name, segment);
                }
                _ => panic_expected(
                    "symbol in type name namespace path while converting type name",
                    &segment_node,
                ),
            }
        }
        let final_segment = self.intern_symbol(&node.name());
        self.type_names.append(name, final_segment)
    }

    fn intern_symbol(&mut self, node: &SymbolNode<'_>) -> SymbolId {
        self.strings.intern(node.as_str())
    }
}

fn convert_range(range: RBSLocationRange) -> LocationRange {
    let start_char = range.start_char();
    let start_byte = range.start_byte();
    let end_char = range.end_char();
    let end_byte = range.end_byte();

    LocationRange {
        start_char: convert_range_component("start_char", start_char, &range),
        start_byte: convert_range_component("start_byte", start_byte, &range),
        end_char: convert_range_component("end_char", end_char, &range),
        end_byte: convert_range_component("end_byte", end_byte, &range),
    }
}

fn convert_range_component(name: &str, value: i32, range: &RBSLocationRange) -> u32 {
    u32::try_from(value).unwrap_or_else(|_| {
        panic!(
            "invalid RBS location range while converting to owned AST: {name} must be non-negative and fit in u32, got {value}; full range is start_char={}, start_byte={}, end_char={}, end_byte={}",
            range.start_char(),
            range.start_byte(),
            range.end_char(),
            range.end_byte()
        )
    })
}

fn convert_optional_range(range: Option<RBSLocationRange>) -> Option<LocationRange> {
    range.map(convert_range)
}

fn convert_variance(variance: TypeParamVariance) -> Variance {
    match variance {
        TypeParamVariance::Invariant => Variance::Invariant,
        TypeParamVariance::Covariant => Variance::Covariant,
        TypeParamVariance::Contravariant => Variance::Contravariant,
    }
}

fn panic_expected(expected: &str, actual: &Node<'_>) -> ! {
    panic!(
        "invalid RBS AST while converting to owned AST: expected {expected}, got {}",
        node_kind(actual)
    )
}

fn node_kind(node: &Node<'_>) -> &'static str {
    match node {
        Node::Annotation(_) => "Annotation",
        Node::Bool(_) => "Bool",
        Node::Comment(_) => "Comment",
        Node::Class(_) => "Class",
        Node::ClassSuper(_) => "ClassSuper",
        Node::ClassAlias(_) => "ClassAlias",
        Node::Constant(_) => "Constant",
        Node::Global(_) => "Global",
        Node::Interface(_) => "Interface",
        Node::Module(_) => "Module",
        Node::ModuleSelf(_) => "ModuleSelf",
        Node::ModuleAlias(_) => "ModuleAlias",
        Node::TypeAlias(_) => "TypeAlias",
        Node::Use(_) => "Use",
        Node::UseSingleClause(_) => "UseSingleClause",
        Node::UseWildcardClause(_) => "UseWildcardClause",
        Node::Integer(_) => "Integer",
        Node::Alias(_) => "Alias",
        Node::AttrAccessor(_) => "AttrAccessor",
        Node::AttrReader(_) => "AttrReader",
        Node::AttrWriter(_) => "AttrWriter",
        Node::ClassInstanceVariable(_) => "ClassInstanceVariable",
        Node::ClassVariable(_) => "ClassVariable",
        Node::Extend(_) => "Extend",
        Node::Include(_) => "Include",
        Node::InstanceVariable(_) => "InstanceVariable",
        Node::MethodDefinition(_) => "MethodDefinition",
        Node::MethodDefinitionOverload(_) => "MethodDefinitionOverload",
        Node::Prepend(_) => "Prepend",
        Node::Private(_) => "Private",
        Node::Public(_) => "Public",
        Node::BlockParamTypeAnnotation(_) => "BlockParamTypeAnnotation",
        Node::ClassAliasAnnotation(_) => "ClassAliasAnnotation",
        Node::ColonMethodTypeAnnotation(_) => "ColonMethodTypeAnnotation",
        Node::DoubleSplatParamTypeAnnotation(_) => "DoubleSplatParamTypeAnnotation",
        Node::InstanceVariableAnnotation(_) => "InstanceVariableAnnotation",
        Node::MethodTypesAnnotation(_) => "MethodTypesAnnotation",
        Node::ModuleAliasAnnotation(_) => "ModuleAliasAnnotation",
        Node::ModuleSelfAnnotation(_) => "ModuleSelfAnnotation",
        Node::NodeTypeAssertion(_) => "NodeTypeAssertion",
        Node::ParamTypeAnnotation(_) => "ParamTypeAnnotation",
        Node::ReturnTypeAnnotation(_) => "ReturnTypeAnnotation",
        Node::SkipAnnotation(_) => "SkipAnnotation",
        Node::SplatParamTypeAnnotation(_) => "SplatParamTypeAnnotation",
        Node::TypeApplicationAnnotation(_) => "TypeApplicationAnnotation",
        Node::String(_) => "String",
        Node::Symbol(_) => "Symbol",
        Node::TypeParam(_) => "TypeParam",
        Node::MethodType(_) => "MethodType",
        Node::Namespace(_) => "Namespace",
        Node::Signature(_) => "Signature",
        Node::TypeName(_) => "TypeName",
        Node::AliasType(_) => "AliasType",
        Node::AnyType(_) => "AnyType",
        Node::BoolType(_) => "BoolType",
        Node::BottomType(_) => "BottomType",
        Node::ClassType(_) => "ClassType",
        Node::InstanceType(_) => "InstanceType",
        Node::NilType(_) => "NilType",
        Node::SelfType(_) => "SelfType",
        Node::TopType(_) => "TopType",
        Node::VoidType(_) => "VoidType",
        Node::BlockType(_) => "BlockType",
        Node::ClassInstanceType(_) => "ClassInstanceType",
        Node::ClassSingletonType(_) => "ClassSingletonType",
        Node::FunctionType(_) => "FunctionType",
        Node::FunctionParam(_) => "FunctionParam",
        Node::InterfaceType(_) => "InterfaceType",
        Node::IntersectionType(_) => "IntersectionType",
        Node::LiteralType(_) => "LiteralType",
        Node::OptionalType(_) => "OptionalType",
        Node::ProcType(_) => "ProcType",
        Node::RecordType(_) => "RecordType",
        Node::RecordFieldType(_) => "RecordFieldType",
        Node::TupleType(_) => "TupleType",
        Node::UnionType(_) => "UnionType",
        Node::UntypedFunctionType(_) => "UntypedFunctionType",
        Node::VariableType(_) => "VariableType",
    }
}

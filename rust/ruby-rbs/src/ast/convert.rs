use crate::ast::annotation::Annotation;
use crate::ast::comment::Comment;
use crate::ast::declarations::{
    ClassAliasDeclaration, ClassDeclaration, ClassMember, ClassSuper, ConstantDeclaration,
    Declaration, GlobalDeclaration, InterfaceDeclaration, ModuleAliasDeclaration,
    ModuleDeclaration, ModuleMember, ModuleSelf, TypeAliasDeclaration,
};
use crate::ast::directives::{
    Directive, UseClause, UseDirective, UseSingleClause, UseWildcardClause,
};
use crate::ast::location::{
    AliasDeclarationLocation, AliasLocation, AliasMemberLocation, AttributeMemberLocation,
    ClassDeclarationLocation, ClassInstanceLocation, ClassSingletonLocation, ClassSuperLocation,
    ConstantDeclarationLocation, FunctionParamLocation, GlobalDeclarationLocation,
    InterfaceDeclarationLocation, InterfaceLocation, LocationRange, MethodDefinitionLocation,
    MethodTypeLocation, MixinMemberLocation, ModuleDeclarationLocation, ModuleSelfLocation,
    TypeAliasDeclarationLocation, TypeParamLocation, UseDirectiveLocation, UseSingleClauseLocation,
    UseWildcardClauseLocation, VariableMemberLocation,
};
use crate::ast::members::{
    AliasKind, AliasMember, AttrAccessorMember, AttrReaderMember, AttrWriterMember, AttributeKind,
    ClassInstanceVariableMember, ClassVariableMember, ExtendMember, IncludeMember,
    InstanceVariableMember, IvarName, Member, MethodDefinitionMember, MethodDefinitionOverload,
    MethodKind, PrependMember, PrivateMember, PublicMember, Visibility,
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
    AliasKind as NodeAliasKind, AliasNode, AliasTypeNode, AnnotationNode, AttrAccessorNode,
    AttrIvarName, AttrReaderNode, AttrWriterNode, AttributeKind as NodeAttributeKind,
    AttributeVisibility as NodeAttributeVisibility, BlockTypeNode, ClassAliasNode,
    ClassInstanceTypeNode, ClassInstanceVariableNode, ClassNode, ClassSingletonTypeNode,
    ClassSuperNode, ClassVariableNode, CommentNode, ConstantNode, ExtendNode, FunctionParamNode,
    FunctionTypeNode, GlobalNode, IncludeNode, InstanceVariableNode, InterfaceNode,
    InterfaceTypeNode, MethodDefinitionKind as NodeMethodDefinitionKind, MethodDefinitionNode,
    MethodDefinitionOverloadNode, MethodDefinitionVisibility as NodeMethodDefinitionVisibility,
    MethodTypeNode, ModuleAliasNode, ModuleNode, ModuleSelfNode, NamespaceNode, Node, PrependNode,
    PrivateNode, PublicNode, RBSLocationRange, SymbolNode, TypeAliasNode, TypeNameNode,
    TypeParamNode, TypeParamVariance, UntypedFunctionTypeNode, UseNode, UseSingleClauseNode,
    UseWildcardClauseNode,
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

    pub fn convert_declaration(&mut self, node: &Node<'_>) -> Declaration {
        match node {
            Node::Class(node) => Declaration::Class(self.convert_class_declaration(node)),
            Node::Module(node) => Declaration::Module(self.convert_module_declaration(node)),
            Node::Interface(node) => {
                Declaration::Interface(self.convert_interface_declaration(node))
            }
            Node::Constant(node) => Declaration::Constant(self.convert_constant_declaration(node)),
            Node::Global(node) => Declaration::Global(self.convert_global_declaration(node)),
            Node::TypeAlias(node) => {
                Declaration::TypeAlias(self.convert_type_alias_declaration(node))
            }
            Node::ClassAlias(node) => {
                Declaration::ClassAlias(self.convert_class_alias_declaration(node))
            }
            Node::ModuleAlias(node) => {
                Declaration::ModuleAlias(self.convert_module_alias_declaration(node))
            }
            _ => panic_expected("declaration node while converting declaration", node),
        }
    }

    pub fn convert_member(&mut self, node: &Node<'_>) -> Member {
        match node {
            Node::MethodDefinition(node) => {
                Member::MethodDefinition(self.convert_method_definition_member(node))
            }
            Node::InstanceVariable(node) => {
                Member::InstanceVariable(self.convert_instance_variable_member(node))
            }
            Node::ClassInstanceVariable(node) => {
                Member::ClassInstanceVariable(self.convert_class_instance_variable_member(node))
            }
            Node::ClassVariable(node) => {
                Member::ClassVariable(self.convert_class_variable_member(node))
            }
            Node::Include(node) => Member::Include(self.convert_include_member(node)),
            Node::Extend(node) => Member::Extend(self.convert_extend_member(node)),
            Node::Prepend(node) => Member::Prepend(self.convert_prepend_member(node)),
            Node::AttrReader(node) => Member::AttrReader(self.convert_attr_reader_member(node)),
            Node::AttrWriter(node) => Member::AttrWriter(self.convert_attr_writer_member(node)),
            Node::AttrAccessor(node) => {
                Member::AttrAccessor(self.convert_attr_accessor_member(node))
            }
            Node::Public(node) => Member::Public(self.convert_public_member(node)),
            Node::Private(node) => Member::Private(self.convert_private_member(node)),
            Node::Alias(node) => Member::Alias(self.convert_alias_member(node)),
            _ => panic_expected("member node while converting member", node),
        }
    }

    pub fn convert_directive(&mut self, node: &Node<'_>) -> Directive {
        match node {
            Node::Use(node) => Directive::Use(self.convert_use_directive(node)),
            _ => panic_expected("directive node while converting directive", node),
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

    fn convert_class_declaration(&mut self, node: &ClassNode<'_>) -> ClassDeclaration {
        ClassDeclaration {
            name: self.convert_type_name(&node.name()),
            type_params: self.convert_type_params(node.type_params()),
            members: self.convert_class_members(node.members()),
            super_class: node
                .super_class()
                .map(|super_class| self.convert_class_super(&super_class)),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(ClassDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                name_range: convert_range(node.name_location()),
                end_range: convert_range(node.end_location()),
                type_params_range: convert_optional_range(node.type_params_location()),
                lt_range: convert_optional_range(node.lt_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_class_super(&mut self, node: &ClassSuperNode<'_>) -> ClassSuper {
        ClassSuper {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(ClassSuperLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_use_directive(&mut self, node: &UseNode<'_>) -> UseDirective {
        UseDirective {
            clauses: self.convert_use_clauses(node.clauses()),
            location: Some(UseDirectiveLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
            }),
        }
    }

    fn convert_use_clause(&mut self, node: &Node<'_>) -> UseClause {
        match node {
            Node::UseSingleClause(node) => UseClause::Single(self.convert_use_single_clause(node)),
            Node::UseWildcardClause(node) => {
                UseClause::Wildcard(self.convert_use_wildcard_clause(node))
            }
            _ => panic_expected("use clause node while converting use directive", node),
        }
    }

    fn convert_use_single_clause(&mut self, node: &UseSingleClauseNode<'_>) -> UseSingleClause {
        UseSingleClause {
            type_name: self.convert_type_name(&node.type_name()),
            new_name: node.new_name().map(|name| self.intern_symbol(&name)),
            location: Some(UseSingleClauseLocation {
                range: convert_range(node.location()),
                type_name_range: convert_range(node.type_name_location()),
                keyword_range: convert_optional_range(node.keyword_location()),
                new_name_range: convert_optional_range(node.new_name_location()),
            }),
        }
    }

    fn convert_use_wildcard_clause(
        &mut self,
        node: &UseWildcardClauseNode<'_>,
    ) -> UseWildcardClause {
        UseWildcardClause {
            namespace: self.convert_namespace(&node.namespace()),
            location: Some(UseWildcardClauseLocation {
                range: convert_range(node.location()),
                namespace_range: convert_range(node.namespace_location()),
                star_range: convert_range(node.star_location()),
            }),
        }
    }

    fn convert_module_declaration(&mut self, node: &ModuleNode<'_>) -> ModuleDeclaration {
        ModuleDeclaration {
            name: self.convert_type_name(&node.name()),
            type_params: self.convert_type_params(node.type_params()),
            members: self.convert_module_members(node.members()),
            location: Some(ModuleDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                name_range: convert_range(node.name_location()),
                end_range: convert_range(node.end_location()),
                type_params_range: convert_optional_range(node.type_params_location()),
                colon_range: convert_optional_range(node.colon_location()),
                self_types_range: convert_optional_range(node.self_types_location()),
            }),
            annotations: self.convert_annotations(node.annotations()),
            self_types: self.convert_module_selfs(node.self_types()),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_module_self(&mut self, node: &ModuleSelfNode<'_>) -> ModuleSelf {
        ModuleSelf {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            location: Some(ModuleSelfLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                args_range: convert_optional_range(node.args_location()),
            }),
        }
    }

    fn convert_interface_declaration(&mut self, node: &InterfaceNode<'_>) -> InterfaceDeclaration {
        InterfaceDeclaration {
            name: self.convert_type_name(&node.name()),
            type_params: self.convert_type_params(node.type_params()),
            members: self.convert_members(node.members()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(InterfaceDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                name_range: convert_range(node.name_location()),
                end_range: convert_range(node.end_location()),
                type_params_range: convert_optional_range(node.type_params_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_type_alias_declaration(&mut self, node: &TypeAliasNode<'_>) -> TypeAliasDeclaration {
        TypeAliasDeclaration {
            name: self.convert_type_name(&node.name()),
            type_params: self.convert_type_params(node.type_params()),
            ty: self.convert_type(&node.type_()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(TypeAliasDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                name_range: convert_range(node.name_location()),
                eq_range: convert_range(node.eq_location()),
                type_params_range: convert_optional_range(node.type_params_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_constant_declaration(&mut self, node: &ConstantNode<'_>) -> ConstantDeclaration {
        ConstantDeclaration {
            name: self.convert_type_name(&node.name()),
            ty: self.convert_type(&node.type_()),
            location: Some(ConstantDeclarationLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                colon_range: convert_range(node.colon_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
            annotations: self.convert_annotations(node.annotations()),
        }
    }

    fn convert_global_declaration(&mut self, node: &GlobalNode<'_>) -> GlobalDeclaration {
        GlobalDeclaration {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            location: Some(GlobalDeclarationLocation {
                range: convert_range(node.location()),
                name_range: convert_range(node.name_location()),
                colon_range: convert_range(node.colon_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
            annotations: self.convert_annotations(node.annotations()),
        }
    }

    fn convert_class_alias_declaration(
        &mut self,
        node: &ClassAliasNode<'_>,
    ) -> ClassAliasDeclaration {
        ClassAliasDeclaration {
            new_name: self.convert_type_name(&node.new_name()),
            old_name: self.convert_type_name(&node.old_name()),
            location: Some(AliasDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                new_name_range: convert_range(node.new_name_location()),
                eq_range: convert_range(node.eq_location()),
                old_name_range: convert_range(node.old_name_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
            annotations: self.convert_annotations(node.annotations()),
        }
    }

    fn convert_module_alias_declaration(
        &mut self,
        node: &ModuleAliasNode<'_>,
    ) -> ModuleAliasDeclaration {
        ModuleAliasDeclaration {
            new_name: self.convert_type_name(&node.new_name()),
            old_name: self.convert_type_name(&node.old_name()),
            location: Some(AliasDeclarationLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                new_name_range: convert_range(node.new_name_location()),
                eq_range: convert_range(node.eq_location()),
                old_name_range: convert_range(node.old_name_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
            annotations: self.convert_annotations(node.annotations()),
        }
    }

    fn convert_method_definition_member(
        &mut self,
        node: &MethodDefinitionNode<'_>,
    ) -> MethodDefinitionMember {
        MethodDefinitionMember {
            name: self.intern_symbol(&node.name()),
            kind: convert_method_kind(node.kind()),
            overloads: self.convert_method_definition_overloads(node.overloads()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(MethodDefinitionLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                name_range: convert_range(node.name_location()),
                kind_range: convert_optional_range(node.kind_location()),
                overloading_range: convert_optional_range(node.overloading_location()),
                visibility_range: convert_optional_range(node.visibility_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
            overloading: node.overloading(),
            visibility: convert_method_visibility(node.visibility()),
        }
    }

    fn convert_method_definition_overload(
        &mut self,
        node: &MethodDefinitionOverloadNode<'_>,
    ) -> MethodDefinitionOverload {
        MethodDefinitionOverload {
            method_type: self.convert_method_type_node(&node.method_type()),
            annotations: self.convert_annotations(node.annotations()),
        }
    }

    fn convert_instance_variable_member(
        &mut self,
        node: &InstanceVariableNode<'_>,
    ) -> InstanceVariableMember {
        InstanceVariableMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            location: Some(variable_member_location(
                node.location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_class_instance_variable_member(
        &mut self,
        node: &ClassInstanceVariableNode<'_>,
    ) -> ClassInstanceVariableMember {
        ClassInstanceVariableMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            location: Some(variable_member_location(
                node.location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_class_variable_member(
        &mut self,
        node: &ClassVariableNode<'_>,
    ) -> ClassVariableMember {
        ClassVariableMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            location: Some(variable_member_location(
                node.location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_include_member(&mut self, node: &IncludeNode<'_>) -> IncludeMember {
        IncludeMember {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(mixin_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.args_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_extend_member(&mut self, node: &ExtendNode<'_>) -> ExtendMember {
        ExtendMember {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(mixin_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.args_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_prepend_member(&mut self, node: &PrependNode<'_>) -> PrependMember {
        PrependMember {
            name: self.convert_type_name(&node.name()),
            args: self.convert_type_list(node.args()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(mixin_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.args_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
        }
    }

    fn convert_attr_reader_member(&mut self, node: &AttrReaderNode<'_>) -> AttrReaderMember {
        AttrReaderMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            ivar_name: self.convert_ivar_name(node.ivar_name(), node.ivar_name_string()),
            kind: convert_attribute_kind(node.kind()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(attribute_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
                node.ivar_location(),
                node.ivar_name_location(),
                node.visibility_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
            visibility: convert_attribute_visibility(node.visibility()),
        }
    }

    fn convert_attr_accessor_member(&mut self, node: &AttrAccessorNode<'_>) -> AttrAccessorMember {
        AttrAccessorMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            ivar_name: self.convert_ivar_name(node.ivar_name(), node.ivar_name_string()),
            kind: convert_attribute_kind(node.kind()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(attribute_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
                node.ivar_location(),
                node.ivar_name_location(),
                node.visibility_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
            visibility: convert_attribute_visibility(node.visibility()),
        }
    }

    fn convert_attr_writer_member(&mut self, node: &AttrWriterNode<'_>) -> AttrWriterMember {
        AttrWriterMember {
            name: self.intern_symbol(&node.name()),
            ty: self.convert_type(&node.type_()),
            ivar_name: self.convert_ivar_name(node.ivar_name(), node.ivar_name_string()),
            kind: convert_attribute_kind(node.kind()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(attribute_member_location(
                node.location(),
                node.keyword_location(),
                node.name_location(),
                node.colon_location(),
                node.kind_location(),
                node.ivar_location(),
                node.ivar_name_location(),
                node.visibility_location(),
            )),
            comment: self.convert_optional_comment(node.comment()),
            visibility: convert_attribute_visibility(node.visibility()),
        }
    }

    fn convert_public_member(&mut self, node: &PublicNode<'_>) -> PublicMember {
        PublicMember {
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_private_member(&mut self, node: &PrivateNode<'_>) -> PrivateMember {
        PrivateMember {
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_alias_member(&mut self, node: &AliasNode<'_>) -> AliasMember {
        AliasMember {
            new_name: self.intern_symbol(&node.new_name()),
            old_name: self.intern_symbol(&node.old_name()),
            kind: convert_alias_kind(node.kind()),
            annotations: self.convert_annotations(node.annotations()),
            location: Some(AliasMemberLocation {
                range: convert_range(node.location()),
                keyword_range: convert_range(node.keyword_location()),
                new_name_range: convert_range(node.new_name_location()),
                old_name_range: convert_range(node.old_name_location()),
                new_kind_range: convert_optional_range(node.new_kind_location()),
                old_kind_range: convert_optional_range(node.old_kind_location()),
            }),
            comment: self.convert_optional_comment(node.comment()),
        }
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

    fn convert_use_clauses(&mut self, list: crate::node::NodeList<'_>) -> Vec<UseClause> {
        list.iter()
            .map(|node| self.convert_use_clause(&node))
            .collect()
    }

    fn convert_class_members(&mut self, list: crate::node::NodeList<'_>) -> Vec<ClassMember> {
        list.iter()
            .map(|node| match node {
                Node::Class(_)
                | Node::Module(_)
                | Node::Interface(_)
                | Node::Constant(_)
                | Node::Global(_)
                | Node::TypeAlias(_)
                | Node::ClassAlias(_)
                | Node::ModuleAlias(_) => ClassMember::Declaration(self.convert_declaration(&node)),
                Node::Alias(_)
                | Node::AttrAccessor(_)
                | Node::AttrReader(_)
                | Node::AttrWriter(_)
                | Node::ClassInstanceVariable(_)
                | Node::ClassVariable(_)
                | Node::Extend(_)
                | Node::Include(_)
                | Node::InstanceVariable(_)
                | Node::MethodDefinition(_)
                | Node::Prepend(_)
                | Node::Private(_)
                | Node::Public(_) => ClassMember::Member(self.convert_member(&node)),
                _ => panic_expected("class member while converting class declaration", &node),
            })
            .collect()
    }

    fn convert_module_members(&mut self, list: crate::node::NodeList<'_>) -> Vec<ModuleMember> {
        list.iter()
            .map(|node| match node {
                Node::Class(_)
                | Node::Module(_)
                | Node::Interface(_)
                | Node::Constant(_)
                | Node::Global(_)
                | Node::TypeAlias(_)
                | Node::ClassAlias(_)
                | Node::ModuleAlias(_) => {
                    ModuleMember::Declaration(self.convert_declaration(&node))
                }
                Node::Alias(_)
                | Node::AttrAccessor(_)
                | Node::AttrReader(_)
                | Node::AttrWriter(_)
                | Node::ClassInstanceVariable(_)
                | Node::ClassVariable(_)
                | Node::Extend(_)
                | Node::Include(_)
                | Node::InstanceVariable(_)
                | Node::MethodDefinition(_)
                | Node::Prepend(_)
                | Node::Private(_)
                | Node::Public(_) => ModuleMember::Member(self.convert_member(&node)),
                _ => panic_expected("module member while converting module declaration", &node),
            })
            .collect()
    }

    fn convert_members(&mut self, list: crate::node::NodeList<'_>) -> Vec<Member> {
        list.iter().map(|node| self.convert_member(&node)).collect()
    }

    fn convert_module_selfs(&mut self, list: crate::node::NodeList<'_>) -> Vec<ModuleSelf> {
        list.iter()
            .map(|node| {
                let Node::ModuleSelf(node) = node else {
                    panic_expected(
                        "module self type while converting module declaration",
                        &node,
                    );
                };
                self.convert_module_self(&node)
            })
            .collect()
    }

    fn convert_method_definition_overloads(
        &mut self,
        list: crate::node::NodeList<'_>,
    ) -> Vec<MethodDefinitionOverload> {
        list.iter()
            .map(|node| {
                let Node::MethodDefinitionOverload(node) = node else {
                    panic_expected(
                        "method definition overload while converting method definition",
                        &node,
                    );
                };
                self.convert_method_definition_overload(&node)
            })
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

    fn convert_method_type_node(&mut self, node: &Node<'_>) -> MethodType {
        let Node::MethodType(node) = node else {
            panic_expected(
                "method type node while converting method definition overload",
                node,
            );
        };
        self.convert_method_type(node)
    }

    fn convert_annotations(&mut self, list: crate::node::NodeList<'_>) -> Vec<Annotation> {
        list.iter()
            .map(|node| {
                let Node::Annotation(node) = node else {
                    panic_expected("annotation node while converting annotations", &node);
                };
                self.convert_annotation(&node)
            })
            .collect()
    }

    fn convert_annotation(&mut self, node: &AnnotationNode<'_>) -> Annotation {
        Annotation {
            string: self.strings.intern(node.string().as_str()),
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_optional_comment(&mut self, node: Option<CommentNode<'_>>) -> Option<Comment> {
        node.map(|node| self.convert_comment(&node))
    }

    fn convert_comment(&mut self, node: &CommentNode<'_>) -> Comment {
        Comment {
            string: self.strings.intern(node.string().as_str()),
            location: Some(convert_range(node.location())),
        }
    }

    fn convert_ivar_name(&mut self, ivar_name: AttrIvarName, name: Option<String>) -> IvarName {
        match ivar_name {
            AttrIvarName::Unspecified => IvarName::Unspecified,
            AttrIvarName::Empty => IvarName::Empty,
            AttrIvarName::Name(_) => {
                let name = name.unwrap_or_else(|| {
                    panic!("invalid RBS AST while converting to owned AST: explicit ivar name is missing from the constant pool")
                });
                IvarName::Name(self.strings.intern(&name))
            }
        }
    }

    fn convert_type_name(&mut self, node: &TypeNameNode<'_>) -> TypeName {
        let name = self.convert_namespace(&node.namespace());
        let final_segment = self.intern_symbol(&node.name());
        self.type_names.append(name, final_segment)
    }

    fn convert_namespace(&mut self, node: &NamespaceNode<'_>) -> TypeName {
        let mut name = self.type_names.root(node.absolute());
        for segment_node in node.path().iter() {
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
        name
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

fn variable_member_location(
    range: RBSLocationRange,
    name_range: RBSLocationRange,
    colon_range: RBSLocationRange,
    kind_range: Option<RBSLocationRange>,
) -> VariableMemberLocation {
    VariableMemberLocation {
        range: convert_range(range),
        name_range: convert_range(name_range),
        colon_range: convert_range(colon_range),
        kind_range: convert_optional_range(kind_range),
    }
}

fn mixin_member_location(
    range: RBSLocationRange,
    keyword_range: RBSLocationRange,
    name_range: RBSLocationRange,
    args_range: Option<RBSLocationRange>,
) -> MixinMemberLocation {
    MixinMemberLocation {
        range: convert_range(range),
        keyword_range: convert_range(keyword_range),
        name_range: convert_range(name_range),
        args_range: convert_optional_range(args_range),
    }
}

#[allow(clippy::too_many_arguments)]
fn attribute_member_location(
    range: RBSLocationRange,
    keyword_range: RBSLocationRange,
    name_range: RBSLocationRange,
    colon_range: RBSLocationRange,
    kind_range: Option<RBSLocationRange>,
    ivar_range: Option<RBSLocationRange>,
    ivar_name_range: Option<RBSLocationRange>,
    visibility_range: Option<RBSLocationRange>,
) -> AttributeMemberLocation {
    AttributeMemberLocation {
        range: convert_range(range),
        keyword_range: convert_range(keyword_range),
        name_range: convert_range(name_range),
        colon_range: convert_range(colon_range),
        kind_range: convert_optional_range(kind_range),
        ivar_range: convert_optional_range(ivar_range),
        ivar_name_range: convert_optional_range(ivar_name_range),
        visibility_range: convert_optional_range(visibility_range),
    }
}

fn convert_variance(variance: TypeParamVariance) -> Variance {
    match variance {
        TypeParamVariance::Invariant => Variance::Invariant,
        TypeParamVariance::Covariant => Variance::Covariant,
        TypeParamVariance::Contravariant => Variance::Contravariant,
    }
}

fn convert_method_kind(kind: NodeMethodDefinitionKind) -> MethodKind {
    match kind {
        NodeMethodDefinitionKind::Instance => MethodKind::Instance,
        NodeMethodDefinitionKind::Singleton => MethodKind::Singleton,
        NodeMethodDefinitionKind::SingletonInstance => MethodKind::SingletonInstance,
    }
}

fn convert_method_visibility(visibility: NodeMethodDefinitionVisibility) -> Option<Visibility> {
    match visibility {
        NodeMethodDefinitionVisibility::Unspecified => None,
        NodeMethodDefinitionVisibility::Public => Some(Visibility::Public),
        NodeMethodDefinitionVisibility::Private => Some(Visibility::Private),
    }
}

fn convert_attribute_kind(kind: NodeAttributeKind) -> AttributeKind {
    match kind {
        NodeAttributeKind::Instance => AttributeKind::Instance,
        NodeAttributeKind::Singleton => AttributeKind::Singleton,
    }
}

fn convert_attribute_visibility(visibility: NodeAttributeVisibility) -> Option<Visibility> {
    match visibility {
        NodeAttributeVisibility::Unspecified => None,
        NodeAttributeVisibility::Public => Some(Visibility::Public),
        NodeAttributeVisibility::Private => Some(Visibility::Private),
    }
}

fn convert_alias_kind(kind: NodeAliasKind) -> AliasKind {
    match kind {
        NodeAliasKind::Instance => AliasKind::Instance,
        NodeAliasKind::Singleton => AliasKind::Singleton,
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

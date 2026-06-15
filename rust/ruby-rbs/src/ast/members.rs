use crate::ast::annotation::Annotation;
use crate::ast::comment::Comment;
use crate::ast::location::{
    AliasMemberLocation, AttributeMemberLocation, MethodDefinitionLocation, MixinMemberLocation,
    VariableMemberLocation,
};
use crate::ast::method_type::MethodType;
use crate::ast::types::Type;
use crate::ids::{SymbolId, TypeName};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Member {
    MethodDefinition(MethodDefinitionMember),
    InstanceVariable(InstanceVariableMember),
    ClassInstanceVariable(ClassInstanceVariableMember),
    ClassVariable(ClassVariableMember),
    Include(IncludeMember),
    Extend(ExtendMember),
    Prepend(PrependMember),
    AttrReader(AttrReaderMember),
    AttrWriter(AttrWriterMember),
    AttrAccessor(AttrAccessorMember),
    Public(PublicMember),
    Private(PrivateMember),
    Alias(AliasMember),
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum Visibility {
    Public,
    Private,
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum MethodKind {
    Instance,
    Singleton,
    SingletonInstance,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MethodDefinitionMember {
    pub name: SymbolId,
    pub kind: MethodKind,
    pub overloads: Vec<MethodDefinitionOverload>,
    pub annotations: Vec<Annotation>,
    pub location: Option<MethodDefinitionLocation>,
    pub comment: Option<Comment>,
    pub overloading: bool,
    pub visibility: Option<Visibility>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MethodDefinitionOverload {
    pub method_type: MethodType,
    pub annotations: Vec<Annotation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct InstanceVariableMember {
    pub name: SymbolId,
    pub ty: Type,
    pub location: Option<VariableMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassInstanceVariableMember {
    pub name: SymbolId,
    pub ty: Type,
    pub location: Option<VariableMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassVariableMember {
    pub name: SymbolId,
    pub ty: Type,
    pub location: Option<VariableMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IncludeMember {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub annotations: Vec<Annotation>,
    pub location: Option<MixinMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ExtendMember {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub annotations: Vec<Annotation>,
    pub location: Option<MixinMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct PrependMember {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub annotations: Vec<Annotation>,
    pub location: Option<MixinMemberLocation>,
    pub comment: Option<Comment>,
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum AttributeKind {
    Instance,
    Singleton,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum IvarName {
    Unspecified,
    Empty,
    Name(SymbolId),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AttrReaderMember {
    pub name: SymbolId,
    pub ty: Type,
    pub ivar_name: IvarName,
    pub kind: AttributeKind,
    pub annotations: Vec<Annotation>,
    pub location: Option<AttributeMemberLocation>,
    pub comment: Option<Comment>,
    pub visibility: Option<Visibility>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AttrAccessorMember {
    pub name: SymbolId,
    pub ty: Type,
    pub ivar_name: IvarName,
    pub kind: AttributeKind,
    pub annotations: Vec<Annotation>,
    pub location: Option<AttributeMemberLocation>,
    pub comment: Option<Comment>,
    pub visibility: Option<Visibility>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AttrWriterMember {
    pub name: SymbolId,
    pub ty: Type,
    pub ivar_name: IvarName,
    pub kind: AttributeKind,
    pub annotations: Vec<Annotation>,
    pub location: Option<AttributeMemberLocation>,
    pub comment: Option<Comment>,
    pub visibility: Option<Visibility>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct PublicMember {
    pub location: Option<crate::ast::location::LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct PrivateMember {
    pub location: Option<crate::ast::location::LocationRange>,
}

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum AliasKind {
    Instance,
    Singleton,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AliasMember {
    pub new_name: SymbolId,
    pub old_name: SymbolId,
    pub kind: AliasKind,
    pub annotations: Vec<Annotation>,
    pub location: Option<AliasMemberLocation>,
    pub comment: Option<Comment>,
}

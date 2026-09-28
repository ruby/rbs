use crate::ast::annotation::Annotation;
use crate::ast::comment::Comment;
use crate::ast::location::{
    AliasDeclarationLocation, ClassDeclarationLocation, ClassSuperLocation,
    ConstantDeclarationLocation, GlobalDeclarationLocation, InterfaceDeclarationLocation,
    ModuleDeclarationLocation, ModuleSelfLocation, TypeAliasDeclarationLocation,
};
use crate::ast::members::Member;
use crate::ast::type_param::TypeParam;
use crate::ast::types::Type;
use crate::ids::{SymbolId, TypeName};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Declaration {
    Class(ClassDeclaration),
    Module(ModuleDeclaration),
    Interface(InterfaceDeclaration),
    Constant(ConstantDeclaration),
    Global(GlobalDeclaration),
    TypeAlias(TypeAliasDeclaration),
    ClassAlias(ClassAliasDeclaration),
    ModuleAlias(ModuleAliasDeclaration),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum ClassMember {
    Member(Member),
    Declaration(Declaration),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum ModuleMember {
    Member(Member),
    Declaration(Declaration),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassSuper {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<ClassSuperLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassDeclaration {
    pub name: TypeName,
    pub type_params: Vec<TypeParam>,
    pub members: Vec<ClassMember>,
    pub super_class: Option<ClassSuper>,
    pub annotations: Vec<Annotation>,
    pub location: Option<ClassDeclarationLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ModuleSelf {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<ModuleSelfLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ModuleDeclaration {
    pub name: TypeName,
    pub type_params: Vec<TypeParam>,
    pub members: Vec<ModuleMember>,
    pub location: Option<ModuleDeclarationLocation>,
    pub annotations: Vec<Annotation>,
    pub self_types: Vec<ModuleSelf>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct InterfaceDeclaration {
    pub name: TypeName,
    pub type_params: Vec<TypeParam>,
    pub members: Vec<Member>,
    pub annotations: Vec<Annotation>,
    pub location: Option<InterfaceDeclarationLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct TypeAliasDeclaration {
    pub name: TypeName,
    pub type_params: Vec<TypeParam>,
    pub ty: Type,
    pub annotations: Vec<Annotation>,
    pub location: Option<TypeAliasDeclarationLocation>,
    pub comment: Option<Comment>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ConstantDeclaration {
    pub name: TypeName,
    pub ty: Type,
    pub location: Option<ConstantDeclarationLocation>,
    pub comment: Option<Comment>,
    pub annotations: Vec<Annotation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct GlobalDeclaration {
    pub name: SymbolId,
    pub ty: Type,
    pub location: Option<GlobalDeclarationLocation>,
    pub comment: Option<Comment>,
    pub annotations: Vec<Annotation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassAliasDeclaration {
    pub new_name: TypeName,
    pub old_name: TypeName,
    pub location: Option<AliasDeclarationLocation>,
    pub comment: Option<Comment>,
    pub annotations: Vec<Annotation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ModuleAliasDeclaration {
    pub new_name: TypeName,
    pub old_name: TypeName,
    pub location: Option<AliasDeclarationLocation>,
    pub comment: Option<Comment>,
    pub annotations: Vec<Annotation>,
}

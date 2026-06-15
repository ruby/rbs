use crate::ast::location::{
    AliasLocation, ClassInstanceLocation, ClassSingletonLocation, FunctionParamLocation,
    InterfaceLocation, LocationRange,
};
use crate::ids::{SymbolId, TypeName};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Type {
    Base(BaseType),
    Variable(VariableType),
    ClassSingleton(ClassSingletonType),
    Interface(InterfaceType),
    ClassInstance(ClassInstanceType),
    Alias(AliasType),
    Tuple(TupleType),
    Record(RecordType),
    Optional(OptionalType),
    Union(UnionType),
    Intersection(IntersectionType),
    Proc(Box<ProcType>),
    Literal(LiteralType),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct BaseType {
    pub kind: BaseTypeKind,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum BaseTypeKind {
    Bool,
    Void,
    Any { todo: bool },
    Nil,
    Top,
    Bottom,
    SelfType,
    Instance,
    Class,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct VariableType {
    pub name: SymbolId,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassSingletonType {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<ClassSingletonLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct InterfaceType {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<InterfaceLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ClassInstanceType {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<ClassInstanceLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct AliasType {
    pub name: TypeName,
    pub args: Vec<Type>,
    pub location: Option<AliasLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct TupleType {
    pub types: Vec<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct RecordType {
    pub fields: Vec<RecordField>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash, Ord, PartialOrd)]
pub enum RecordKey {
    Symbol(SymbolId),
    String(String),
    Integer(String),
    Bool(bool),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct RecordField {
    pub key: RecordKey,
    pub ty: Type,
    pub required: bool,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct OptionalType {
    pub ty: Box<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct UnionType {
    pub types: Vec<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct IntersectionType {
    pub types: Vec<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionType {
    pub required_positionals: Vec<FunctionParam>,
    pub optional_positionals: Vec<FunctionParam>,
    pub rest_positionals: Option<Box<FunctionParam>>,
    pub trailing_positionals: Vec<FunctionParam>,
    pub required_keywords: Vec<KeywordParam>,
    pub optional_keywords: Vec<KeywordParam>,
    pub rest_keywords: Option<Box<FunctionParam>>,
    pub return_type: Box<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct KeywordParam {
    pub name: SymbolId,
    pub param: FunctionParam,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct FunctionParam {
    pub ty: Box<Type>,
    pub name: Option<SymbolId>,
    pub location: Option<FunctionParamLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct UntypedFunctionType {
    pub return_type: Box<Type>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Function {
    Typed(FunctionType),
    Untyped(UntypedFunctionType),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct BlockType {
    pub function: Function,
    pub required: bool,
    pub self_type: Option<Box<Type>>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ProcType {
    pub function: Function,
    pub block: Option<BlockType>,
    pub self_type: Option<Box<Type>>,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct LiteralType {
    pub literal: Literal,
    pub location: Option<LocationRange>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Literal {
    String(String),
    Integer(String),
    Symbol(SymbolId),
    Bool(bool),
}

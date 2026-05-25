use crate::ast::location::TypeParamLocation;
use crate::ast::types::Type;
use crate::ids::SymbolId;

#[derive(Copy, Clone, Debug, Eq, PartialEq, Hash)]
pub enum Variance {
    Invariant,
    Covariant,
    Contravariant,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct TypeParam {
    pub name: SymbolId,
    pub variance: Variance,
    pub upper_bound: Option<Type>,
    pub lower_bound: Option<Type>,
    pub default_type: Option<Type>,
    pub unchecked: bool,
    pub location: Option<TypeParamLocation>,
}

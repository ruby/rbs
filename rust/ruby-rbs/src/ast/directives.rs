use crate::ast::location::{
    ResolveTypeNamesDirectiveLocation, UseDirectiveLocation, UseSingleClauseLocation,
    UseWildcardClauseLocation,
};
use crate::ids::{SymbolId, TypeName};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum Directive {
    Use(UseDirective),
    ResolveTypeNames(ResolveTypeNamesDirective),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct UseDirective {
    pub clauses: Vec<UseClause>,
    pub location: Option<UseDirectiveLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub enum UseClause {
    Single(UseSingleClause),
    Wildcard(UseWildcardClause),
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct UseSingleClause {
    pub type_name: TypeName,
    pub new_name: Option<SymbolId>,
    pub location: Option<UseSingleClauseLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct UseWildcardClause {
    pub namespace: TypeName,
    pub location: Option<UseWildcardClauseLocation>,
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct ResolveTypeNamesDirective {
    pub value: bool,
    pub location: Option<ResolveTypeNamesDirectiveLocation>,
}

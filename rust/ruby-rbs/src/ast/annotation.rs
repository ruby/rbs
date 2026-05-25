use crate::ast::location::LocationRange;
use crate::ids::SymbolId;

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct Annotation {
    pub string: SymbolId,
    pub location: Option<LocationRange>,
}

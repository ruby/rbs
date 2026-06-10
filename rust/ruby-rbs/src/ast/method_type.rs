use crate::ast::location::MethodTypeLocation;
use crate::ast::type_param::TypeParam;
use crate::ast::types::{BlockType, Function};

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
pub struct MethodType {
    pub type_params: Vec<TypeParam>,
    pub function: Function,
    pub block: Option<BlockType>,
    pub location: Option<MethodTypeLocation>,
}

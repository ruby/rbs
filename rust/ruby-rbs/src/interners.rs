use crate::interner::StringInterner;
use crate::type_name::TypeNameInterner;

#[derive(Default)]
pub struct Interners {
    pub strings: StringInterner,
    pub type_names: TypeNameInterner,
}

impl Interners {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }
}

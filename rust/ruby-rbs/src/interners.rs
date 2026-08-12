use crate::interner::StringInterner;
use crate::type_name::TypeNameInterner;

/// The pair of interners that an owned AST's ids refer to.
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

    pub fn merge(&mut self, other: Interners) {
        self.strings.merge(other.strings);
        self.type_names.merge(other.type_names);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn merge_makes_worker_local_ids_resolvable() {
        let mut local = Interners::new();
        let foo = local.strings.intern("Foo");
        let root = local.type_names.absolute_root();
        let name = local.type_names.append(root, foo);

        let mut global = Interners::new();
        global.merge(local);

        assert_eq!(global.type_names.display(name, &global.strings), "::Foo");
    }
}

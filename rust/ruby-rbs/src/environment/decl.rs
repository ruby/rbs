use crate::ast::Declaration;
use crate::ids::TypeName;

use super::Environment;

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub struct DeclId(u32);

#[derive(Copy, Clone, Debug)]
pub(super) struct DeclNode {
    pub(super) source: u32,
    pub(super) parent: Option<DeclId>,
    pub(super) index: u32,
    pub(super) context: Context,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub struct Context(Option<u32>);

impl Context {
    #[must_use]
    pub const fn root() -> Self {
        Self(None)
    }
}

#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash)]
pub(super) struct ContextNode {
    parent: Context,
    name: TypeName,
}

impl Environment {
    #[must_use]
    pub fn decl(&self, id: DeclId) -> &Declaration {
        self.member_decl(self.node(id))
    }

    #[must_use]
    pub fn context_of(&self, id: DeclId) -> Context {
        self.node(id).context
    }

    pub fn context_names(&self, context: Context) -> impl Iterator<Item = TypeName> + '_ {
        let node = move |i: u32| &self.contexts[i as usize];
        std::iter::successors(context.0, move |&i| node(i).parent.0).map(move |i| node(i).name)
    }

    pub(super) fn intern_context(&mut self, parent: Context, name: TypeName) -> Context {
        let (index, _) = self.contexts.insert_full(ContextNode { parent, name });
        Context(Some(u32::try_from(index).expect("too many contexts")))
    }

    pub(super) fn node(&self, id: DeclId) -> &DeclNode {
        &self.decl_nodes[id.0 as usize]
    }

    pub(super) fn push_node(&mut self, node: DeclNode) -> DeclId {
        let id = DeclId(u32::try_from(self.decl_nodes.len()).expect("too many declarations"));
        self.decl_nodes.push(node);
        id
    }

    pub(super) fn member_decl(&self, node: &DeclNode) -> &Declaration {
        let index = node.index as usize;
        let Some(parent) = node.parent else {
            return &self.sources[node.source as usize].declarations[index];
        };
        let member = match self.decl(parent) {
            Declaration::Class(c) => c.members[index].as_declaration(),
            Declaration::Module(m) => m.members[index].as_declaration(),
            _ => unreachable!("only class/module declarations have child declarations"),
        };
        member.expect("DeclNode must point at a Declaration")
    }
}

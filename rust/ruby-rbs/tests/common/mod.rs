use ruby_rbs::node::RBSLocationRange;

macro_rules! expect_variant {
    ($node:expr, $variant:ident) => {
        match $node {
            Node::$variant(node) => node,
            _ => panic!(concat!("expected Node::", stringify!($variant))),
        }
    };
}

pub fn slice(source: &str, location: RBSLocationRange) -> &str {
    &source[location.start() as usize..location.end() as usize]
}

use serde::Deserialize;
use std::{env, error::Error, fs::File, io::Write, path::Path};

#[derive(Debug, Deserialize)]
struct Config {
    nodes: Vec<Node>,
}

#[derive(Debug, Deserialize)]
struct NodeField {
    name: String,
    c_type: String,
    c_name: Option<String>,
    #[serde(default)]
    optional: bool,
}

impl NodeField {
    fn c_name(&self) -> &str {
        let name = self.c_name.as_ref().unwrap_or(&self.name);
        if name == "type" { "type_" } else { name }
    }
}

#[derive(Debug, Deserialize)]
struct Node {
    name: String,
    rust_name: String,
    fields: Option<Vec<NodeField>>,
}

impl Node {
    fn variant_name(&self) -> &str {
        self.rust_name
            .strip_suffix("Node")
            .unwrap_or(&self.rust_name)
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let config_path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../config.yml")
        .canonicalize()?;

    println!("cargo:rerun-if-changed={}", config_path.display());

    let config_file = File::open(&config_path)?;
    let mut config: Config = serde_yaml::from_reader(config_file)?;

    // Keyword and Symbol represent identifiers (interned strings), not traditional AST nodes.
    // However, the C parser defines them in `rbs_node_type` (RBS_KEYWORD, RBS_AST_SYMBOL) and
    // treats them as nodes (rbs_node_t*) in many contexts (lists, hashes).
    // We inject them into the config so they are generated as structs matching the Node pattern,
    // allowing them to be wrapped in the Node enum and handled uniformly in Rust.
    config.nodes.push(Node {
        name: "RBS::Keyword".to_string(),
        rust_name: "KeywordNode".to_string(),
        fields: None,
    });
    config.nodes.push(Node {
        name: "RBS::AST::Symbol".to_string(),
        rust_name: "SymbolNode".to_string(),
        fields: None,
    });

    config.nodes.sort_by(|a, b| a.name.cmp(&b.name));
    generate(&config)?;

    Ok(())
}

enum CIdentifier {
    Type,     // foo_bar_t
    Constant, // FOO_BAR
    Method,   // visit_foo_bar
}

fn convert_name(name: &str, identifier: CIdentifier) -> String {
    let type_name = name.replace("::", "_");
    let lowercase = matches!(identifier, CIdentifier::Type | CIdentifier::Method);
    let mut out = String::new();
    let mut prev_is_lower = false;

    for ch in type_name.chars() {
        if ch.is_ascii_uppercase() {
            if prev_is_lower {
                out.push('_');
            }
            out.push(if lowercase {
                ch.to_ascii_lowercase()
            } else {
                ch
            });
            prev_is_lower = false;
        } else if ch == '_' {
            out.push(ch);
            prev_is_lower = false;
        } else {
            out.push(if lowercase {
                ch
            } else {
                ch.to_ascii_uppercase()
            });
            prev_is_lower = ch.is_ascii_lowercase() || ch.is_ascii_digit();
        }
    }

    if matches!(identifier, CIdentifier::Type) {
        out.push_str("_t");
    }
    out
}

fn write_node_field_accessor(
    file: &mut File,
    field: &NodeField,
    rust_type: &str,
) -> std::io::Result<()> {
    if field.optional {
        writeln!(file, "    #[must_use]")?;
        writeln!(
            file,
            "    pub fn {}(&self) -> Option<{rust_type}<'a>> {{",
            field.name,
        )?;
        writeln!(
            file,
            "        let ptr = unsafe {{ (*self.pointer).{} }};",
            field.c_name()
        )?;
        writeln!(file, "        if ptr.is_null() {{")?;
        writeln!(file, "            None")?;
        writeln!(file, "        }} else {{")?;
        writeln!(
            file,
            "            Some({rust_type} {{ parser: self.parser, pointer: ptr, marker: PhantomData }})"
        )?;
        writeln!(file, "        }}")?;
    } else {
        writeln!(file, "    #[must_use]")?;
        writeln!(
            file,
            "    pub fn {}(&self) -> {rust_type}<'a> {{",
            field.name
        )?;
        writeln!(
            file,
            "        {rust_type} {{ parser: self.parser, pointer: unsafe {{ (*self.pointer).{} }}, marker: PhantomData }}",
            field.c_name()
        )?;
    }
    writeln!(file, "    }}")?;
    writeln!(file)?;
    Ok(())
}

fn write_visit_trait(file: &mut File, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    writeln!(file, "/// A trait for traversing the AST using a visitor")?;
    writeln!(file, "pub trait Visit {{")?;
    writeln!(
        file,
        "   /// Visit any node of the AST. Generally used to continue traversal"
    )?;
    writeln!(file, "   fn visit(&mut self, node: &Node) {{")?;
    writeln!(file, "       match node {{")?;

    for node in &config.nodes {
        let node_variant_name = node.variant_name();
        let method_name = convert_name(node_variant_name, CIdentifier::Method);

        writeln!(file, "           Node::{node_variant_name}(it) => {{")?;
        writeln!(file, "               self.visit_{method_name}_node(it);")?;
        writeln!(file, "           }}")?;
    }

    writeln!(file, "       }}")?;
    writeln!(file, "   }}")?;

    for node in &config.nodes {
        let node_variant_name = node.variant_name();
        let method_name = convert_name(node_variant_name, CIdentifier::Method);

        writeln!(file)?;
        writeln!(
            file,
            "    fn visit_{method_name}_node(&mut self, node: &{node_variant_name}Node) {{"
        )?;
        writeln!(file, "        visit_{method_name}_node(self, node);")?;
        writeln!(file, "    }}")?;
    }
    writeln!(file, "}}")?;
    writeln!(file)?;

    // Map C field types (e.g. `rbs_type_name`) to the corresponding
    // visitor method name (e.g. `type_name` -> `visit_type_name_node`).
    let visitor_method_names: std::collections::HashMap<String, String> = config
        .nodes
        .iter()
        .map(|node| {
            let c_type = convert_name(&node.name, CIdentifier::Type);
            let c_type = c_type.strip_suffix("_t").unwrap_or(&c_type).to_string();
            let method = convert_name(node.variant_name(), CIdentifier::Method);
            (c_type, method)
        })
        .collect();

    let is_visitable = |c_type: &str| -> bool {
        matches!(c_type, "rbs_node" | "rbs_node_list" | "rbs_hash")
            || visitor_method_names.contains_key(c_type)
    };

    for node in &config.nodes {
        let node_variant_name = node.variant_name();
        let method_name = convert_name(node_variant_name, CIdentifier::Method);

        let has_visitable_fields = node
            .fields
            .iter()
            .flatten()
            .any(|field| is_visitable(&field.c_type));

        if !has_visitable_fields {
            // If there's nothing to visit in this node, write the empty method with
            // underscored parameters, and skip to the next iteration
            writeln!(
                file,
                "pub fn visit_{method_name}_node<V: Visit + ?Sized>(_visitor: &mut V, _node: &{node_variant_name}Node) {{}}"
            )?;

            continue;
        }

        writeln!(
            file,
            "pub fn visit_{method_name}_node<V: Visit + ?Sized>(visitor: &mut V, node: &{node_variant_name}Node) {{"
        )?;

        if let Some(fields) = &node.fields {
            for field in fields {
                let field_method_name = if field.name == "type" {
                    "type_"
                } else {
                    field.name.as_str()
                };

                match field.c_type.as_str() {
                    "rbs_node" => {
                        if field.optional {
                            writeln!(
                                file,
                                "    if let Some(item) = node.{field_method_name}() {{"
                            )?;
                            writeln!(file, "        visitor.visit(&item);")?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(file, "    visitor.visit(&node.{field_method_name}());")?;
                        }
                    }

                    "rbs_node_list" => {
                        if field.optional {
                            writeln!(
                                file,
                                "    if let Some(list) = node.{field_method_name}() {{"
                            )?;
                            writeln!(file, "        for item in list.iter() {{")?;
                            writeln!(file, "            visitor.visit(&item);")?;
                            writeln!(file, "        }}")?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(file, "    for item in node.{field_method_name}().iter() {{")?;
                            writeln!(file, "        visitor.visit(&item);")?;
                            writeln!(file, "    }}")?;
                        }
                    }

                    "rbs_hash" => {
                        if field.optional {
                            writeln!(
                                file,
                                "    if let Some(hash) = node.{field_method_name}() {{"
                            )?;
                            writeln!(file, "        for (key, value) in hash.iter() {{")?;
                            writeln!(file, "            visitor.visit(&key);")?;
                            writeln!(file, "            visitor.visit(&value);")?;
                            writeln!(file, "        }}")?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(
                                file,
                                "    for (key, value) in node.{field_method_name}().iter() {{"
                            )?;
                            writeln!(file, "        visitor.visit(&key);")?;
                            writeln!(file, "        visitor.visit(&value);")?;
                            writeln!(file, "    }}")?;
                        }
                    }

                    _ => {
                        if let Some(visit_method_name) = visitor_method_names.get(&field.c_type) {
                            if field.optional {
                                writeln!(
                                    file,
                                    "    if let Some(item) = node.{field_method_name}() {{"
                                )?;
                                writeln!(
                                    file,
                                    "        visitor.visit_{visit_method_name}_node(&item);"
                                )?;
                                writeln!(file, "    }}")?;
                            } else {
                                writeln!(
                                    file,
                                    "    visitor.visit_{visit_method_name}_node(&node.{field_method_name}());"
                                )?;
                            }
                        }
                    }
                }
            }
        }
        writeln!(file, "}}")?;
        writeln!(file)?;
    }

    Ok(())
}

fn generate(config: &Config) -> Result<(), Box<dyn Error>> {
    let out_dir = env::var("OUT_DIR")?;
    let dest_path = Path::new(&out_dir).join("bindings.rs");

    let mut file = File::create(&dest_path)?;

    writeln!(file, "// Generated by build.rs from config.yml")?;
    writeln!(file)?;

    for node in &config.nodes {
        writeln!(file, "#[derive(Debug)]")?;
        writeln!(file, "pub struct {}<'a> {{", node.rust_name)?;
        writeln!(file, "    #[allow(dead_code)]")?;
        writeln!(file, "    parser: NonNull<rbs_parser_t>,")?;
        writeln!(
            file,
            "    pointer: *mut {},",
            convert_name(&node.name, CIdentifier::Type)
        )?;
        writeln!(
            file,
            "    marker: PhantomData<&'a mut {}>",
            convert_name(&node.name, CIdentifier::Type)
        )?;
        writeln!(file, "}}\n")?;

        writeln!(file, "impl<'a> {}<'a> {{", node.rust_name)?;
        writeln!(file, "    /// Converts this node to a generic node.")?;
        writeln!(file, "    #[must_use]")?;
        writeln!(file, "    pub fn as_node(self) -> Node<'a> {{")?;
        writeln!(file, "        Node::{}(self)", node.variant_name())?;
        writeln!(file, "    }}")?;
        writeln!(file)?;
        writeln!(file, "    /// Returns the location of this node.")?;
        writeln!(file, "    #[must_use]")?;
        writeln!(file, "    pub fn location(&self) -> RBSLocation {{")?;
        writeln!(
            file,
            "        RBSLocation::new(unsafe {{ (*self.pointer).base.location }})"
        )?;
        writeln!(file, "    }}")?;
        writeln!(file)?;

        if let Some(fields) = &node.fields {
            for field in fields {
                match field.c_type.as_str() {
                    "rbs_string" => {
                        writeln!(file, "    #[must_use]")?;
                        writeln!(file, "    pub fn {}(&self) -> RBSString {{", field.name)?;
                        writeln!(
                            file,
                            "        RBSString::new(unsafe {{ &(*self.pointer).{} }})",
                            field.c_name()
                        )?;
                        writeln!(file, "    }}")?;
                        writeln!(file)?;
                    }
                    "bool" => {
                        writeln!(file, "    #[must_use]")?;
                        writeln!(file, "    pub fn {}(&self) -> bool {{", field.name)?;
                        writeln!(file, "        unsafe {{ (*self.pointer).{} }}", field.name)?;
                        writeln!(file, "    }}")?;
                        writeln!(file)?;
                    }
                    "rbs_ast_comment" => {
                        write_node_field_accessor(&mut file, field, "CommentNode")?
                    }
                    "rbs_ast_declarations_class_super" => {
                        write_node_field_accessor(&mut file, field, "ClassSuperNode")?
                    }
                    "rbs_ast_symbol" => write_node_field_accessor(&mut file, field, "SymbolNode")?,
                    "rbs_hash" => {
                        write_node_field_accessor(&mut file, field, "RBSHash")?;
                    }
                    "rbs_location" => {
                        if field.optional {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(
                                file,
                                "    pub fn {}(&self) -> Option<RBSLocation> {{",
                                field.name
                            )?;
                            writeln!(
                                file,
                                "        let ptr = unsafe {{ (*self.pointer).{} }};",
                                field.c_name()
                            )?;
                            writeln!(file, "        if ptr.is_null() {{")?;
                            writeln!(file, "            None")?;
                            writeln!(file, "        }} else {{")?;
                            writeln!(file, "            Some(RBSLocation {{ pointer: ptr }})")?;
                            writeln!(file, "        }}")?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(file, "    pub fn {}(&self) -> RBSLocation {{", field.name)?;
                            writeln!(
                                file,
                                "        RBSLocation {{ pointer: unsafe {{ (*self.pointer).{} }} }}",
                                field.c_name()
                            )?;
                            writeln!(file, "    }}")?;
                        }
                        writeln!(file)?;
                    }
                    "rbs_location_list" => {
                        if field.optional {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(
                                file,
                                "    pub fn {}(&self) -> Option<RBSLocationList> {{",
                                field.name
                            )?;
                            writeln!(
                                file,
                                "        let ptr = unsafe {{ (*self.pointer).{} }};",
                                field.c_name()
                            )?;
                            writeln!(file, "        if ptr.is_null() {{")?;
                            writeln!(file, "            None")?;
                            writeln!(file, "        }} else {{")?;
                            writeln!(file, "            Some(RBSLocationList {{ pointer: ptr }})")?;
                            writeln!(file, "        }}")?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(
                                file,
                                "    pub fn {}(&self) -> RBSLocationList {{",
                                field.name
                            )?;
                            writeln!(
                                file,
                                "        RBSLocationList {{ pointer: unsafe {{ (*self.pointer).{} }} }}",
                                field.c_name()
                            )?;
                            writeln!(file, "    }}")?;
                        }
                        writeln!(file)?;
                    }
                    "rbs_namespace" => {
                        write_node_field_accessor(&mut file, field, "NamespaceNode")?;
                    }
                    "rbs_node" => {
                        let name = if field.name == "type" {
                            "type_"
                        } else {
                            field.name.as_str()
                        };
                        if field.optional {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(file, "    pub fn {name}(&self) -> Option<Node<'a>> {{")?;
                            writeln!(
                                file,
                                "        let ptr = unsafe {{ (*self.pointer).{} }};",
                                field.c_name()
                            )?;
                            writeln!(
                                file,
                                "        if ptr.is_null() {{ None }} else {{ Some(Node::new(self.parser, ptr)) }}"
                            )?;
                        } else {
                            writeln!(file, "    #[must_use]")?;
                            writeln!(file, "    pub fn {name}(&self) -> Node<'a> {{")?;
                            writeln!(
                                file,
                                "        unsafe {{ Node::new(self.parser, (*self.pointer).{}) }}",
                                field.c_name()
                            )?;
                        }
                        writeln!(file, "    }}")?;
                        writeln!(file)?;
                    }
                    "rbs_node_list" => {
                        write_node_field_accessor(&mut file, field, "NodeList")?;
                    }
                    "rbs_keyword" => write_node_field_accessor(&mut file, field, "KeywordNode")?,
                    "rbs_type_name" => {
                        write_node_field_accessor(&mut file, field, "TypeNameNode")?;
                    }
                    "rbs_types_block" => {
                        write_node_field_accessor(&mut file, field, "BlockTypeNode")?
                    }
                    _ => panic!("Unknown field type: {}", field.c_type),
                }
            }
        }
        writeln!(file, "}}\n")?;
    }

    // Generate the Node enum to wrap all of the structs
    writeln!(file, "#[derive(Debug)]")?;
    writeln!(file, "pub enum Node<'a> {{")?;
    for node in &config.nodes {
        let variant_name = node
            .rust_name
            .strip_suffix("Node")
            .unwrap_or(&node.rust_name);

        writeln!(file, "    {variant_name}({}<'a>),", node.rust_name)?;
    }
    writeln!(file, "}}")?;

    writeln!(file, "impl Node<'_> {{")?;
    writeln!(file, "    #[allow(clippy::missing_safety_doc)]")?;
    writeln!(
        file,
        "    fn new(parser: NonNull<rbs_parser_t>, node: *mut rbs_node_t) -> Self {{"
    )?;
    writeln!(file, "        match unsafe {{ (*node).type_ }} {{")?;
    for node in &config.nodes {
        let enum_name = convert_name(&node.name, CIdentifier::Constant);
        let c_type = convert_name(&node.name, CIdentifier::Type);

        writeln!(
            file,
            "            rbs_node_type::{enum_name} => Self::{}({} {{ parser, pointer: node.cast::<{c_type}>(), marker: PhantomData }}),",
            node.variant_name(),
            node.rust_name,
        )?;
    }
    writeln!(
        file,
        "            _ => panic!(\"Unknown node type: {{}}\", unsafe {{ (*node).type_ }})"
    )?;
    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file)?;
    writeln!(file, "    /// Returns the location of the entire node.")?;
    writeln!(file, "    #[must_use]")?;
    writeln!(file, "    pub fn location(&self) -> RBSLocation {{")?;
    writeln!(file, "        match self {{")?;
    for node in &config.nodes {
        writeln!(
            file,
            "            Node::{}(node) => node.location(),",
            node.variant_name()
        )?;
    }
    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file, "}}")?;
    writeln!(file)?;

    write_visit_trait(&mut file, config)?;

    Ok(())
}

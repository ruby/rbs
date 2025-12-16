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
        writeln!(
            file,
            "    pub fn {}(&self) -> Option<{}> {{",
            field.name, rust_type
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
            "            Some({rust_type} {{ parser: self.parser, pointer: ptr }})"
        )?;
        writeln!(file, "        }}")?;
    } else {
        writeln!(file, "    pub fn {}(&self) -> {} {{", field.name, rust_type)?;
        writeln!(
            file,
            "        {} {{ parser: self.parser, pointer: unsafe {{ (*self.pointer).{} }} }}",
            rust_type,
            field.c_name()
        )?;
    }
    writeln!(file, "    }}")
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

        writeln!(file, "           Node::{}(it) => {{", node_variant_name)?;
        writeln!(file, "               self.visit_{}_node(it);", method_name,)?;
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
            "    fn visit_{}_node(&mut self, node: &{}Node) {{",
            method_name, node_variant_name
        )?;
        writeln!(file, "        visit_{}_node(self, node);", method_name)?;
        writeln!(file, "    }}")?;
    }
    writeln!(file, "}}")?;
    writeln!(file)?;

    for node in &config.nodes {
        let node_variant_name = node.variant_name();
        let method_name = convert_name(node_variant_name, CIdentifier::Method);

        writeln!(file, "#[allow(unused_variables)]")?; // TODO: Remove this once all nodes that need visitor are implemented
        writeln!(
            file,
            "pub fn visit_{}_node<V: Visit + ?Sized>(visitor: &mut V, node: &{}Node) {{",
            method_name, node_variant_name
        )?;
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
    writeln!(file, "// Nodes to generate: {}", config.nodes.len())?;
    writeln!(file)?;

    // TODO: Go through all of the nodes and generate the structs to back them up
    for node in &config.nodes {
        writeln!(file, "#[allow(dead_code)]")?; // TODO: Remove this once all nodes that need parser are implemented
        writeln!(file, "#[derive(Debug)]")?;
        writeln!(file, "pub struct {} {{", node.rust_name)?;
        writeln!(file, "    parser: *mut rbs_parser_t,")?;
        writeln!(
            file,
            "    pointer: *mut {},",
            convert_name(&node.name, CIdentifier::Type)
        )?;
        writeln!(file, "}}\n")?;

        writeln!(file, "impl {} {{", node.rust_name)?;
        if let Some(fields) = &node.fields {
            for field in fields {
                match field.c_type.as_str() {
                    "rbs_string" => {
                        writeln!(file, "    pub fn {}(&self) -> RBSString {{", field.name)?;
                        writeln!(
                            file,
                            "        RBSString::new(unsafe {{ &(*self.pointer).{} }})",
                            field.c_name()
                        )?;
                        writeln!(file, "    }}")?;
                    }
                    "bool" => {
                        writeln!(file, "    pub fn {}(&self) -> bool {{", field.name)?;
                        writeln!(file, "        unsafe {{ (*self.pointer).{} }}", field.name)?;
                        writeln!(file, "    }}")?;
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
                        write_node_field_accessor(&mut file, field, "RBSLocation")?;
                    }
                    "rbs_location_list" => {
                        write_node_field_accessor(&mut file, field, "RBSLocationList")?;
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
                            writeln!(file, "    pub fn {name}(&self) -> Option<Node> {{")?;
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
                            writeln!(file, "    pub fn {name}(&self) -> Node {{")?;
                            writeln!(
                                file,
                                "        unsafe {{ Node::new(self.parser, (*self.pointer).{}) }}",
                                field.c_name()
                            )?;
                        }
                        writeln!(file, "    }}")?;
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
    writeln!(file, "pub enum Node {{")?;
    for node in &config.nodes {
        let variant_name = node
            .rust_name
            .strip_suffix("Node")
            .unwrap_or(&node.rust_name);

        writeln!(file, "    {}({}),", variant_name, node.rust_name)?;
    }
    writeln!(file, "}}")?;

    writeln!(file, "impl Node {{")?;
    writeln!(file, "    #[allow(clippy::missing_safety_doc)]")?;
    writeln!(
        file,
        "    fn new(parser: *mut rbs_parser_t, node: *mut rbs_node_t) -> Self {{"
    )?;
    writeln!(file, "        match unsafe {{ (*node).type_ }} {{")?;
    for node in &config.nodes {
        let enum_name = convert_name(&node.name, CIdentifier::Constant);

        writeln!(
            file,
            "            rbs_node_type::{} => Self::{}({} {{ parser, pointer: node.cast::<{}>() }}),",
            enum_name,
            node.variant_name(),
            node.rust_name,
            convert_name(&node.name, CIdentifier::Type)
        )?;
    }
    writeln!(
        file,
        "            _ => panic!(\"Unknown node type: {{}}\", unsafe {{ (*node).type_ }})"
    )?;
    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file, "}}")?;
    writeln!(file)?;

    write_visit_trait(&mut file, config)?;

    Ok(())
}

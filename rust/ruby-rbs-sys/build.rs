use std::{
    env,
    error::Error,
    fs,
    path::{Path, PathBuf},
};

fn main() -> Result<(), Box<dyn Error>> {
    let root = root_dir()?;
    let include = root.join("include");
    let src = root.join("src");

    build(&include, &src)?;

    let bindings = generate_bindings(&include)?;
    write_bindings(&bindings)?;

    Ok(())
}

fn build(include_dir: &Path, src_dir: &Path) -> Result<(), Box<dyn Error>> {
    let mut build = cc::Build::new();

    build.include(include_dir);

    // Suppress unused parameter warnings from C code
    build.flag_if_supported("-Wno-unused-parameter");

    build.files(source_files(src_dir)?);
    build.try_compile("rbs")?;

    Ok(())
}

fn root_dir() -> Result<PathBuf, Box<dyn Error>> {
    Ok(Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(2)
        .ok_or("Failed to find project root directory")?
        .to_path_buf())
}

fn source_files<P: AsRef<Path>>(root_dir: P) -> Result<Vec<String>, Box<dyn Error>> {
    let mut files = Vec::new();

    for entry in fs::read_dir(root_dir.as_ref()).map_err(|e| {
        format!(
            "Failed to read source directory {:?}: {e}",
            root_dir.as_ref()
        )
    })? {
        let entry = entry.map_err(|e| format!("Failed to read directory entry: {e}"))?;
        let path = entry.path();

        if path.is_file() {
            let path_str = path
                .to_str()
                .ok_or_else(|| format!("Invalid UTF-8 in filename: {path:?}"))?;

            if Path::new(path_str)
                .extension()
                .is_some_and(|ext| ext.eq_ignore_ascii_case("c"))
            {
                files.push(path_str.to_string());
            }
        } else if path.is_dir() {
            files.extend(source_files(path)?);
        }
    }

    Ok(files)
}

fn generate_bindings(include_path: &Path) -> Result<bindgen::Bindings, Box<dyn Error>> {
    let bindings = bindgen::Builder::default()
        .header("wrapper.h")
        .clang_arg(format!("-I{}", include_path.display()))
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .generate_comments(true)
        // Core types
        .allowlist_type("rbs_ast_annotation_t")
        .allowlist_type("rbs_ast_bool_t")
        .allowlist_type("rbs_ast_comment_t")
        .allowlist_type("rbs_ast_declarations_class_alias_t")
        .allowlist_type("rbs_ast_declarations_class_super_t")
        .allowlist_type("rbs_ast_declarations_class_t")
        .allowlist_type("rbs_ast_declarations_constant_t")
        .allowlist_type("rbs_ast_declarations_global_t")
        .allowlist_type("rbs_ast_declarations_interface_t")
        .allowlist_type("rbs_ast_declarations_module_alias_t")
        .allowlist_type("rbs_ast_declarations_module_self_t")
        .allowlist_type("rbs_ast_declarations_module_t")
        .allowlist_type("rbs_ast_declarations_type_alias_t")
        .allowlist_type("rbs_ast_directives_use_single_clause_t")
        .allowlist_type("rbs_ast_directives_use_t")
        .allowlist_type("rbs_ast_directives_use_wildcard_clause_t")
        .allowlist_type("rbs_ast_integer_t")
        .allowlist_type("rbs_ast_members_alias_t")
        .allowlist_type("rbs_ast_members_attr_accessor_t")
        .allowlist_type("rbs_ast_members_attr_reader_t")
        .allowlist_type("rbs_ast_members_attr_writer_t")
        .allowlist_type("rbs_ast_members_class_instance_variable_t")
        .allowlist_type("rbs_ast_members_class_variable_t")
        .allowlist_type("rbs_ast_members_extend_t")
        .allowlist_type("rbs_ast_members_include_t")
        .allowlist_type("rbs_ast_members_instance_variable_t")
        .allowlist_type("rbs_ast_members_method_definition_overload_t")
        .allowlist_type("rbs_ast_members_method_definition_t")
        .allowlist_type("rbs_ast_members_prepend_t")
        .allowlist_type("rbs_ast_members_private_t")
        .allowlist_type("rbs_ast_members_public_t")
        .allowlist_type("rbs_ast_ruby_annotations_class_alias_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_colon_method_type_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_instance_variable_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_method_types_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_module_alias_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_node_type_assertion_t")
        .allowlist_type("rbs_ast_ruby_annotations_return_type_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_skip_annotation_t")
        .allowlist_type("rbs_ast_ruby_annotations_type_application_annotation_t")
        .allowlist_type("rbs_ast_string_t")
        .allowlist_type("rbs_ast_symbol_t")
        .allowlist_type("rbs_ast_type_param_t")
        .allowlist_type("rbs_encoding_t")
        .allowlist_type("rbs_encoding_type_t")
        .allowlist_type("rbs_keyword_t")
        .allowlist_type("rbs_method_type_t")
        .allowlist_type("rbs_namespace_t")
        .allowlist_type("rbs_node_list_t")
        .allowlist_type("rbs_signature_t")
        .allowlist_type("rbs_string_t")
        .allowlist_type("rbs_type_name_t")
        .allowlist_type("rbs_types_alias_t")
        .allowlist_type("rbs_types_bases_any_t")
        .allowlist_type("rbs_types_bases_bool_t")
        .allowlist_type("rbs_types_bases_bottom_t")
        .allowlist_type("rbs_types_bases_class_t")
        .allowlist_type("rbs_types_bases_instance_t")
        .allowlist_type("rbs_types_bases_nil_t")
        .allowlist_type("rbs_types_bases_self_t")
        .allowlist_type("rbs_types_bases_top_t")
        .allowlist_type("rbs_types_bases_void_t")
        .allowlist_type("rbs_types_block_t")
        .allowlist_type("rbs_types_class_instance_t")
        .allowlist_type("rbs_types_class_singleton_t")
        .allowlist_type("rbs_types_function_param_t")
        .allowlist_type("rbs_types_function_t")
        .allowlist_type("rbs_types_interface_t")
        .allowlist_type("rbs_types_intersection_t")
        .allowlist_type("rbs_types_literal_t")
        .allowlist_type("rbs_types_optional_t")
        .allowlist_type("rbs_types_proc_t")
        .allowlist_type("rbs_types_record_field_type_t")
        .allowlist_type("rbs_types_record_t")
        .allowlist_type("rbs_types_tuple_t")
        .allowlist_type("rbs_types_union_t")
        .allowlist_type("rbs_types_untyped_function_t")
        .allowlist_type("rbs_types_variable_t")
        .constified_enum_module("rbs_encoding_type_t")
        .constified_enum_module("rbs_node_type")
        // Encodings
        .allowlist_var("rbs_encodings")
        // Parser functions
        .allowlist_function("rbs_constant_pool_id_to_constant")
        .allowlist_function("rbs_parse_signature")
        .allowlist_function("rbs_parser_free")
        .allowlist_function("rbs_parser_new")
        // String functions
        .allowlist_function("rbs_string_new")
        // Global constant pool
        .allowlist_var("RBS_GLOBAL_CONSTANT_POOL")
        .allowlist_function("rbs_constant_pool_free")
        .allowlist_function("rbs_constant_pool_init")
        .generate()
        .map_err(|_| "Unable to generate rbs bindings")?;

    Ok(bindings)
}

fn write_bindings(bindings: &bindgen::Bindings) -> Result<(), Box<dyn Error>> {
    let out_path = PathBuf::from(
        env::var("OUT_DIR").map_err(|e| format!("OUT_DIR environment variable not set: {e}"))?,
    );

    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .map_err(|e| {
            format!(
                "Failed to write bindings to {:?}: {e}",
                out_path.join("bindings.rs")
            )
        })?;

    Ok(())
}

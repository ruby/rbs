use std::{
    env,
    error::Error,
    fs,
    path::{Path, PathBuf},
};

fn main() -> Result<(), Box<dyn Error>> {
    let manifest_dir = Path::new(env!("CARGO_MANIFEST_DIR"));
    let vendor_rbs = manifest_dir.join("vendor/rbs");
    let include = vendor_rbs.join("include");
    let c_src = vendor_rbs.join("src");

    let target = env::var("TARGET").unwrap_or_default();
    let is_wasm = target.contains("wasm32");

    build(&include, &c_src, is_wasm)?;

    let bindings = generate_bindings(&include, is_wasm)?;
    write_bindings(&bindings)?;

    Ok(())
}

fn build(include_dir: &Path, src_dir: &Path, is_wasm: bool) -> Result<(), Box<dyn Error>> {
    let mut build = cc::Build::new();

    build.include(include_dir);

    // Suppress unused parameter warnings from C code
    build.flag_if_supported("-Wno-unused-parameter");

    // Cross-compile the C parser to wasm with the WASI SDK's clang. Only the C
    // compile targets wasm; bindgen (below) still runs against the host, since
    // the resulting #[repr(C)] declarations are layout-portable.
    if is_wasm {
        let wasi_sdk = PathBuf::from(
            env::var("WASI_SDK_PATH").expect("WASI_SDK_PATH must be set for wasm builds"),
        );
        build.compiler(wasi_sdk.join("bin").join("clang"));

        let sysroot = wasi_sdk.join("share").join("wasi-sysroot");
        build.flag(&format!("--sysroot={}", sysroot.display()));
        build.include(sysroot.join("include"));

        println!(
            "cargo:rustc-link-search=native={}",
            sysroot.join("lib/wasm32-wasi").display()
        );
        build.define("_WASI_EMULATED_MMAN", "1");
        println!("cargo:rustc-link-lib=wasi-emulated-mman");
    }

    build.files(source_files(src_dir)?);
    build.try_compile("rbs")?;

    Ok(())
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

fn generate_bindings(
    include_path: &Path,
    is_wasm: bool,
) -> Result<bindgen::Bindings, Box<dyn Error>> {
    let mut builder = bindgen::Builder::default()
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
        .allowlist_type("rbs_attr_ivar_name_t")
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
        // Match every `rbs_ast_ruby_annotations_*` struct (and the union itself)
        // so newly added annotation kinds do not require edits here. This keeps the
        // Rust bindings in sync with `config.yml` automatically.
        .allowlist_type("rbs_ast_ruby_annotations_.*")
        .allowlist_type("rbs_ast_string_t")
        .allowlist_type("rbs_ast_symbol_t")
        .allowlist_type("rbs_ast_type_param_t")
        .allowlist_type("rbs_encoding_t")
        .allowlist_type("rbs_encoding_type_t")
        .allowlist_type("rbs_location_range")
        .allowlist_type("rbs_location_range_list_t")
        .allowlist_type("rbs_location_range_list_node_t")
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
        .constified_enum_module("rbs_alias_kind")
        .constified_enum_module("rbs_attribute_kind")
        .constified_enum_module("rbs_attribute_visibility")
        .constified_enum_module("rbs_encoding_type_t")
        .constified_enum_module("rbs_attr_ivar_name_tag")
        .constified_enum_module("rbs_method_definition_kind")
        .constified_enum_module("rbs_method_definition_visibility")
        .constified_enum_module("rbs_node_type")
        .constified_enum_module("rbs_type_param_variance")
        // Encodings
        .allowlist_var("rbs_encodings")
        // Parser functions
        .allowlist_function("rbs_parse_signature")
        .allowlist_function("rbs_parser_free")
        .allowlist_function("rbs_parser_new")
        // String functions
        .allowlist_function("rbs_string_new")
        // Location functions
        .allowlist_function("rbs_location_range_list_new")
        .allowlist_function("rbs_location_range_list_append")
        // Constant pool functions
        .allowlist_function("rbs_constant_pool_free")
        .allowlist_function("rbs_constant_pool_id_to_constant")
        .allowlist_function("rbs_constant_pool_init");

    if is_wasm {
        // Generate the FFI declarations for the HOST target rather than the wasm
        // target: host bindgen is reliable, whereas wasm-target bindgen is
        // libclang-fragile (drops functions / emits opaque structs). The emitted
        // #[repr(C)] structs are layout-portable, so they compile correctly for
        // wasm32. Drop the layout assertions, which would otherwise hardcode the
        // host sizes and fail when recompiled for wasm.
        let host = env::var("HOST").expect("HOST is not set");
        builder = builder
            .clang_arg(format!("--target={host}"))
            .layout_tests(false);
    }

    let bindings = builder
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

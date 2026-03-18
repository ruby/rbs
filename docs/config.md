# config.yml

`config.yml` is the definition of data structure for parser results -- AST.

It defines the data structure for the parser implementation in C and Rust `node` modules.

## C parser code

```sh
$ rake templates
```

Our C parser consists of two components:

1. Pure C Parser
2. Translator from the pure C AST to Ruby object

`config.yml` defines the AST for pure C parser in `ast.h`/`ast.c` and translator from the C AST to Ruby objects in `ast_translation.h`/`ast_translation.c`.

## `ruby-rbs` crate

```sh
$ cd rust; cargo build
```

The `build.rs` in `ruby-rbs` crate defines the data structure derived from `config.yml` definitions under `node` module.

## nodes

`nodes` defines *node* data types in C or Rust.

```yaml
nodes:
  - name: RBS::AST::Declarations::Class
    rust_name: ClassNode
    fields:
      - name: name
        c_type: rbs_type_name
      - name: type_params
        c_type: rbs_node_list
      - name: super_class
        c_type: rbs_ast_declarations_class_super
        optional: true  # NULL when no superclass (e.g., `class Foo end` vs `class Foo < Bar end`)
      - name: members
        c_type: rbs_node_list
      - name: annotations
        c_type: rbs_node_list
      - name: comment
        c_type: rbs_ast_comment
        optional: true  # NULL when no comment precedes the declaration
```

This defines `rbs_ast_declarations_class` struct so that the parser constructs the AST using the structs.

```c
typedef struct rbs_ast_declarations_class {
    rbs_node_t base;

    struct rbs_type_name *name;
    struct rbs_node_list *type_params;
    struct rbs_ast_declarations_class_super *super_class; /* Optional */
    struct rbs_node_list *members;
    struct rbs_node_list *annotations;
    struct rbs_ast_comment *comment; /* Optional */

    rbs_location_range keyword_range;     /* Required */
    rbs_location_range name_range;        /* Required */
    rbs_location_range end_range;         /* Required */
    rbs_location_range type_params_range; /* Optional */
    rbs_location_range lt_range;          /* Optional */
} rbs_ast_declarations_class_t;
```

The `rbs_ast_declarations_class` struct is a pure C AST, and `ast_translation.c` defines translation into a Ruby object of `RBS::AST::Declarations::Class` class.

```c
    case RBS_AST_DECLARATIONS_CLASS: {
        rbs_ast_declarations_class_t *node = (rbs_ast_declarations_class_t *) instance;

        VALUE h = rb_hash_new();
        VALUE location = rbs_location_range_to_ruby_location(ctx, node->base.location);
        rbs_loc *loc = rbs_check_location(location);
        rbs_loc_legacy_alloc_children(loc, 5);
        rbs_loc_legacy_add_required_child(loc, rb_intern("keyword"), (rbs_loc_range) { .start = node->keyword_range.start_char, .end = node->keyword_range.end_char });
        rbs_loc_legacy_add_required_child(loc, rb_intern("name"), (rbs_loc_range) { .start = node->name_range.start_char, .end = node->name_range.end_char });
        rbs_loc_legacy_add_required_child(loc, rb_intern("end"), (rbs_loc_range) { .start = node->end_range.start_char, .end = node->end_range.end_char });
        rbs_loc_legacy_add_optional_child(loc, rb_intern("type_params"), (rbs_loc_range) { .start = node->type_params_range.start_char, .end = node->type_params_range.end_char });
        rbs_loc_legacy_add_optional_child(loc, rb_intern("lt"), (rbs_loc_range) { .start = node->lt_range.start_char, .end = node->lt_range.end_char });
        rb_hash_aset(h, ID2SYM(rb_intern("location")), location);
        rb_hash_aset(h, ID2SYM(rb_intern("name")), rbs_struct_to_ruby_value(ctx, (rbs_node_t *) node->name)); // rbs_type_name
        rb_hash_aset(h, ID2SYM(rb_intern("type_params")), rbs_node_list_to_ruby_array(ctx, node->type_params));
        rb_hash_aset(h, ID2SYM(rb_intern("super_class")), rbs_struct_to_ruby_value(ctx, (rbs_node_t *) node->super_class)); // rbs_ast_declarations_class_super
        rb_hash_aset(h, ID2SYM(rb_intern("members")), rbs_node_list_to_ruby_array(ctx, node->members));
        rb_hash_aset(h, ID2SYM(rb_intern("annotations")), rbs_node_list_to_ruby_array(ctx, node->annotations));
        rb_hash_aset(h, ID2SYM(rb_intern("comment")), rbs_struct_to_ruby_value(ctx, (rbs_node_t *) node->comment)); // rbs_ast_comment

        rb_funcall(
            RBS_AST_TypeParam,
            rb_intern("resolve_variables"),
            1,
            rb_hash_lookup(h, ID2SYM(rb_intern("type_params")))
        );
        return CLASS_NEW_INSTANCE(
            RBS_AST_Declarations_Class,
            1,
            &h
        );
    }
```

## enums

`enums` defines *enum* data types in C or Rust.

```yaml
enums:
  attribute_visibility:
    optional: true
    symbols:
      - unspecified
      - public
      - private
```

For example, the `attribute_visibility` enum is a data type for `visibility` attribute of `attr_reader`, `attr_writer`, and `attr_accessor` definitions.
The `visibility` attribute can be one of `unspecified`, `public`, and `private`.

### Symbol enums

Enum definition with `symbols:` attribute defines *enum* data that is mapped to Ruby symbols.

```yaml
enums:
  attribute_visibility:
    optional: true
    symbols:
      - unspecified
      - public
      - private
```

It defines an `enum` in C AST definition.

```c
enum RBS_ATTRIBUTE_VISIBILITY_TAG {
    RBS_ATTRIBUTE_VISIBILITY_TAG_UNSPECIFIED,
    RBS_ATTRIBUTE_VISIBILITY_TAG_PUBLIC,
    RBS_ATTRIBUTE_VISIBILITY_TAG_PRIVATE,
};
```

The C extension also defines a translation:

```c
VALUE rbs_attribute_visibility_to_ruby(enum rbs_attribute_visibility value) {
    switch (value) {
    case RBS_ATTRIBUTE_VISIBILITY_UNSPECIFIED:
        return Qnil;
    case RBS_ATTRIBUTE_VISIBILITY_PUBLIC:
        return rb_id2sym(rb_intern("public"));
    case RBS_ATTRIBUTE_VISIBILITY_PRIVATE:
        return rb_id2sym(rb_intern("private"));
    default:
        rb_fatal("unknown enum rbs_attribute_visibility value: %d", value);
    }
}
```

`RBS_ATTRIBUTE_VISIBILITY_PUBLIC` and `RBS_ATTRIBUTE_VISIBILITY_PRIVATE` are translated to Ruby symbols `:public` and `:private` respectively. 

Note that the first `RBS_ATTRIBUTE_VISIBILITY_UNSPECIFIED` is translated to `nil` in Ruby. This is specified by the `optional: true` attribute in YAML. When `optional: true` is set, the first enum value is translated to `nil`.

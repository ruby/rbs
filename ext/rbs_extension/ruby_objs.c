#include "rbs_extension.h"

#ifdef RB_PASS_KEYWORDS

#define FUNCALL_KW(receiver, method, argc, argv) rb_funcallv_kw(receiver, method, argc, argv, RB_PASS_KEYWORDS)

#else

#define FUNCALL_KW(receiver, method, argc, argv) rb_funcallv(receiver, method, argc, argv)

#endif


VALUE rbs_base_type(VALUE klass, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    klass,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_namespace(VALUE path, VALUE absolute) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("path")), path);
  rb_hash_aset(args, ID2SYM(rb_intern("absolute")), absolute);

  return FUNCALL_KW(
    RBS_Namespace,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_type_name(VALUE namespace, VALUE name) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("namespace")), namespace);
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);

  return FUNCALL_KW(
    RBS_TypeName,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_class_instance(VALUE typename, VALUE type_args, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), typename);
  rb_hash_aset(args, ID2SYM(rb_intern("args")), type_args);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_ClassInstance,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_class_singleton(VALUE typename, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), typename);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_ClassSingleton,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_alias(VALUE typename, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), typename);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Alias,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_interface(VALUE typename, VALUE type_args, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), typename);
  rb_hash_aset(args, ID2SYM(rb_intern("args")), type_args);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Interface,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_union(VALUE types, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Union,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_intersection(VALUE types, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Intersection,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_tuple(VALUE types, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Tuple,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_optional(VALUE type, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Optional,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_block(VALUE type, VALUE required) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("required")), required);

  return FUNCALL_KW(
    RBS_Types_Block,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_function_param(VALUE type, VALUE name, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Function_Param,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_function(
  VALUE required_positional_params,
  VALUE optional_positional_params,
  VALUE rest_positional_param,
  VALUE trailing_positional_params,
  VALUE required_keyword_params,
  VALUE optional_keyword_params,
  VALUE rest_keyword_param,
  VALUE return_type
) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("required_positionals")), required_positional_params);
  rb_hash_aset(args, ID2SYM(rb_intern("optional_positionals")), optional_positional_params);
  rb_hash_aset(args, ID2SYM(rb_intern("rest_positionals")), rest_positional_param);
  rb_hash_aset(args, ID2SYM(rb_intern("trailing_positionals")), trailing_positional_params);
  rb_hash_aset(args, ID2SYM(rb_intern("required_keywords")), required_keyword_params);
  rb_hash_aset(args, ID2SYM(rb_intern("optional_keywords")), optional_keyword_params);
  rb_hash_aset(args, ID2SYM(rb_intern("rest_keywords")), rest_keyword_param);
  rb_hash_aset(args, ID2SYM(rb_intern("return_type")), return_type);

  return FUNCALL_KW(
    RBS_Types_Function,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_proc(VALUE function, VALUE block, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("type")), function);
  rb_hash_aset(args, ID2SYM(rb_intern("block")), block);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Proc,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_void(VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_Types_Bases_Void,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_literal(VALUE literal, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("literal")), literal);

  return FUNCALL_KW(
    RBS_Types_Literal,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_record(VALUE fields, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("fields")), fields);

  return FUNCALL_KW(
    RBS_Types_Record,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_variable(VALUE name, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);

  return FUNCALL_KW(
    RBS_Types_Variable,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_method_type(VALUE type_params, VALUE type, VALUE block, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("block")), block);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_MethodType,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_comment(VALUE string, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("string")), string);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_AST_Comment,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_annotation(VALUE string, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("string")), string);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_AST_Annotation,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_module_type_params() {
  return rb_funcall(RBS_AST_Declarations_ModuleTypeParams, rb_intern("new"), 0);
}

VALUE rbs_ast_decl_module_type_params_param(VALUE name, VALUE variance, VALUE skip_validation, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("variance")), variance);
  rb_hash_aset(args, ID2SYM(rb_intern("skip_validation")), skip_validation);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_AST_Declarations_ModuleTypeParams_TypeParam,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_constant(VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Constant,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_global(VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Global,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_alias(VALUE name, VALUE type, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Alias,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_interface(VALUE name, VALUE type_params, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(args, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Interface,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_module_self(VALUE name, VALUE args, VALUE location) {
  VALUE kw_args = rb_hash_new();
  rb_hash_aset(kw_args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(kw_args, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(kw_args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_AST_Declarations_Module_Self,
    rb_intern("new"),
    1,
    &kw_args
  );
}

VALUE rbs_ast_decl_module(VALUE name, VALUE type_params, VALUE self_types, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(args, ID2SYM(rb_intern("self_types")), self_types);
  rb_hash_aset(args, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Module,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_method_definition(VALUE name, VALUE kind, VALUE types, VALUE annotations, VALUE location, VALUE comment, VALUE overload) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(args, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(args, ID2SYM(rb_intern("overload")), overload);

  return FUNCALL_KW(
    RBS_AST_Members_MethodDefinition,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_variable(VALUE klass, VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    klass,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_mixin(VALUE klass, VALUE name, VALUE module_args, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("args")), module_args);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    klass,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_attribute(VALUE klass, VALUE name, VALUE type, VALUE ivar_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(args, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(args, ID2SYM(rb_intern("ivar_name")), ivar_name);
  rb_hash_aset(args, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    klass,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_visibility(VALUE klass, VALUE location) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    klass,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_members_alias(VALUE new_name, VALUE old_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment) {
  VALUE args = rb_hash_new();
  rb_hash_aset(args, ID2SYM(rb_intern("new_name")), new_name);
  rb_hash_aset(args, ID2SYM(rb_intern("old_name")), old_name);
  rb_hash_aset(args, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(args, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(args, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(args, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Members_Alias,
    rb_intern("new"),
    1,
    &args
  );
}

VALUE rbs_ast_decl_class_super(VALUE name, VALUE args, VALUE location) {
  VALUE kwargs = rb_hash_new();
  rb_hash_aset(kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("location")), location);

  return FUNCALL_KW(
    RBS_AST_Declarations_Class_Super,
    rb_intern("new"),
    1,
    &kwargs
  );
}

VALUE rbs_ast_decl_class(VALUE name, VALUE type_params, VALUE super_class, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE kwargs = rb_hash_new();
  rb_hash_aset(kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("super_class")), super_class);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(kwargs, ID2SYM(rb_intern("comment")), comment);

  return FUNCALL_KW(
    RBS_AST_Declarations_Class,
    rb_intern("new"),
    1,
    &kwargs
  );
}

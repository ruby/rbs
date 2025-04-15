/*----------------------------------------------------------------------------*/
/* This file is generated by the templates/template.rb script and should not  */
/* be modified manually.                                                      */
/* To change the template see                                                 */
/* templates/src/ruby_objs.c.erb                                              */
/*----------------------------------------------------------------------------*/

#include "rbs_extension.h"

#ifdef RB_PASS_KEYWORDS
  // Ruby 2.7 or later
  #define CLASS_NEW_INSTANCE(klass, argc, argv)\
          rb_class_new_instance_kw(argc, argv, klass, RB_PASS_KEYWORDS)
#else
  // Ruby 2.6
  #define CLASS_NEW_INSTANCE(receiver, argc, argv)\
          rb_class_new_instance(argc, argv, receiver)
#endif

VALUE rbs_ast_annotation(VALUE string, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("string")), string);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Annotation,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_comment(VALUE string, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("string")), string);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Comment,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_class(VALUE name, VALUE type_params, VALUE super_class, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("super_class")), super_class);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Class,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_class_super(VALUE name, VALUE args, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Class_Super,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_class_alias(VALUE new_name, VALUE old_name, VALUE location, VALUE comment, VALUE annotations) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("new_name")), new_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("old_name")), old_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_ClassAlias,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_constant(VALUE name, VALUE type, VALUE location, VALUE comment, VALUE annotations) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Constant,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_global(VALUE name, VALUE type, VALUE location, VALUE comment, VALUE annotations) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Global,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_interface(VALUE name, VALUE type_params, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Interface,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_module(VALUE name, VALUE type_params, VALUE self_types, VALUE members, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("self_types")), self_types);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("members")), members);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Module,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_module_self(VALUE name, VALUE args, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_Module_Self,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_module_alias(VALUE new_name, VALUE old_name, VALUE location, VALUE comment, VALUE annotations) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("new_name")), new_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("old_name")), old_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_ModuleAlias,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_decl_type_alias(VALUE name, VALUE type_params, VALUE type, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Declarations_TypeAlias,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_directives_use(VALUE clauses, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("clauses")), clauses);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Directives_Use,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_directives_use_single_clause(VALUE type_name, VALUE new_name, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_name")), type_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("new_name")), new_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Directives_Use_SingleClause,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_directives_use_wildcard_clause(VALUE namespace, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("namespace")), namespace);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Directives_Use_WildcardClause,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_alias(VALUE new_name, VALUE old_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("new_name")), new_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("old_name")), old_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Alias,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_attr_accessor(VALUE name, VALUE type, VALUE ivar_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment, VALUE visibility) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("ivar_name")), ivar_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("visibility")), visibility);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_AttrAccessor,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_attr_reader(VALUE name, VALUE type, VALUE ivar_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment, VALUE visibility) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("ivar_name")), ivar_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("visibility")), visibility);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_AttrReader,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_attr_writer(VALUE name, VALUE type, VALUE ivar_name, VALUE kind, VALUE annotations, VALUE location, VALUE comment, VALUE visibility) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("ivar_name")), ivar_name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("visibility")), visibility);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_AttrWriter,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_class_instance_variable(VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_ClassInstanceVariable,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_class_variable(VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_ClassVariable,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_extend(VALUE name, VALUE args, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Extend,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_include(VALUE name, VALUE args, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Include,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_instance_variable(VALUE name, VALUE type, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_InstanceVariable,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_method_definition(VALUE name, VALUE kind, VALUE overloads, VALUE annotations, VALUE location, VALUE comment, VALUE overloading, VALUE visibility) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("kind")), kind);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("overloads")), overloads);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("overloading")), overloading);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("visibility")), visibility);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_MethodDefinition,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_method_definition_overload(VALUE annotations, VALUE method_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("method_type")), method_type);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_MethodDefinition_Overload,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_prepend(VALUE name, VALUE args, VALUE annotations, VALUE location, VALUE comment) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment")), comment);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Prepend,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_private(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Private,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_members_public(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Members_Public,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_ruby_annotations_colon_method_type_annotation(VALUE location, VALUE prefix_location, VALUE annotations, VALUE method_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("prefix_location")), prefix_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("annotations")), annotations);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("method_type")), method_type);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Ruby_Annotations_ColonMethodTypeAnnotation,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_ruby_annotations_method_types_annotation(VALUE location, VALUE prefix_location, VALUE overloads, VALUE vertical_bar_locations) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("prefix_location")), prefix_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("overloads")), overloads);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("vertical_bar_locations")), vertical_bar_locations);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Ruby_Annotations_MethodTypesAnnotation,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_ruby_annotations_node_type_assertion(VALUE location, VALUE prefix_location, VALUE type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("prefix_location")), prefix_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Ruby_Annotations_NodeTypeAssertion,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_ruby_annotations_return_type_annotation(VALUE location, VALUE prefix_location, VALUE return_location, VALUE colon_location, VALUE return_type, VALUE comment_location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("prefix_location")), prefix_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("return_location")), return_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("colon_location")), colon_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("return_type")), return_type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment_location")), comment_location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Ruby_Annotations_ReturnTypeAnnotation,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_ruby_annotations_skip_annotation(VALUE location, VALUE prefix_location, VALUE skip_location, VALUE comment_location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("prefix_location")), prefix_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("skip_location")), skip_location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("comment_location")), comment_location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_Ruby_Annotations_SkipAnnotation,
    1,
    &_init_kwargs
  );
}

VALUE rbs_ast_type_param(VALUE name, VALUE variance, VALUE upper_bound, VALUE default_type, VALUE unchecked, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("variance")), variance);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("upper_bound")), upper_bound);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("default_type")), default_type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("unchecked")), unchecked);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_AST_TypeParam,
    1,
    &_init_kwargs
  );
}

VALUE rbs_method_type(VALUE type_params, VALUE type, VALUE block, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type_params")), type_params);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("block")), block);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_MethodType,
    1,
    &_init_kwargs
  );
}

VALUE rbs_namespace(VALUE path, VALUE absolute) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("path")), path);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("absolute")), absolute);

  return CLASS_NEW_INSTANCE(
    RBS_Namespace,
    1,
    &_init_kwargs
  );
}

VALUE rbs_type_name(VALUE namespace, VALUE name) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("namespace")), namespace);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);

  return CLASS_NEW_INSTANCE(
    RBS_TypeName,
    1,
    &_init_kwargs
  );
}

VALUE rbs_alias(VALUE name, VALUE args, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Alias,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_any(VALUE todo, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("todo")), todo);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Any,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_bool(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Bool,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_bottom(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Bottom,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_class(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Class,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_instance(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Instance,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_nil(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Nil,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_self(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Self,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_top(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Top,
    1,
    &_init_kwargs
  );
}

VALUE rbs_bases_void(VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Bases_Void,
    1,
    &_init_kwargs
  );
}

VALUE rbs_block(VALUE type, VALUE required, VALUE self_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("required")), required);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("self_type")), self_type);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Block,
    1,
    &_init_kwargs
  );
}

VALUE rbs_class_instance(VALUE name, VALUE args, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_ClassInstance,
    1,
    &_init_kwargs
  );
}

VALUE rbs_class_singleton(VALUE name, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_ClassSingleton,
    1,
    &_init_kwargs
  );
}

VALUE rbs_function(VALUE required_positionals, VALUE optional_positionals, VALUE rest_positionals, VALUE trailing_positionals, VALUE required_keywords, VALUE optional_keywords, VALUE rest_keywords, VALUE return_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("required_positionals")), required_positionals);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("optional_positionals")), optional_positionals);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("rest_positionals")), rest_positionals);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("trailing_positionals")), trailing_positionals);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("required_keywords")), required_keywords);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("optional_keywords")), optional_keywords);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("rest_keywords")), rest_keywords);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("return_type")), return_type);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Function,
    1,
    &_init_kwargs
  );
}

VALUE rbs_function_param(VALUE type, VALUE name, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Function_Param,
    1,
    &_init_kwargs
  );
}

VALUE rbs_interface(VALUE name, VALUE args, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("args")), args);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Interface,
    1,
    &_init_kwargs
  );
}

VALUE rbs_intersection(VALUE types, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Intersection,
    1,
    &_init_kwargs
  );
}

VALUE rbs_literal(VALUE literal, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("literal")), literal);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Literal,
    1,
    &_init_kwargs
  );
}

VALUE rbs_optional(VALUE type, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Optional,
    1,
    &_init_kwargs
  );
}

VALUE rbs_proc(VALUE type, VALUE block, VALUE location, VALUE self_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("type")), type);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("block")), block);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("self_type")), self_type);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Proc,
    1,
    &_init_kwargs
  );
}

VALUE rbs_record(VALUE all_fields, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("all_fields")), all_fields);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Record,
    1,
    &_init_kwargs
  );
}

VALUE rbs_tuple(VALUE types, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Tuple,
    1,
    &_init_kwargs
  );
}

VALUE rbs_union(VALUE types, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("types")), types);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Union,
    1,
    &_init_kwargs
  );
}

VALUE rbs_untyped_function(VALUE return_type) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("return_type")), return_type);

  return CLASS_NEW_INSTANCE(
    RBS_Types_UntypedFunction,
    1,
    &_init_kwargs
  );
}

VALUE rbs_variable(VALUE name, VALUE location) {
  VALUE _init_kwargs = rb_hash_new();
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("name")), name);
  rb_hash_aset(_init_kwargs, ID2SYM(rb_intern("location")), location);

  return CLASS_NEW_INSTANCE(
    RBS_Types_Variable,
    1,
    &_init_kwargs
  );
}


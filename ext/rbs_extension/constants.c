#include "rbs_extension.h"

VALUE RBS_Parser;

VALUE RBS;
VALUE RBS_AST;
VALUE RBS_AST_Comment;
VALUE RBS_AST_Annotation;
VALUE RBS_AST_TypeParam;

VALUE RBS_AST_Declarations;

VALUE RBS_AST_Declarations_TypeAlias;
VALUE RBS_AST_Declarations_Constant;
VALUE RBS_AST_Declarations_Global;
VALUE RBS_AST_Declarations_Interface;
VALUE RBS_AST_Declarations_Module;
VALUE RBS_AST_Declarations_Module_Self;
VALUE RBS_AST_Declarations_Class;
VALUE RBS_AST_Declarations_Class_Super;
VALUE RBS_AST_Declarations_ModuleAlias;
VALUE RBS_AST_Declarations_ClassAlias;

VALUE RBS_AST_Directives;
VALUE RBS_AST_Directives_Use;
VALUE RBS_AST_Directives_Use_SingleClause;
VALUE RBS_AST_Directives_Use_WildcardClause;

VALUE RBS_AST_Members;
VALUE RBS_AST_Members_Alias;
VALUE RBS_AST_Members_AttrAccessor;
VALUE RBS_AST_Members_AttrReader;
VALUE RBS_AST_Members_AttrWriter;
VALUE RBS_AST_Members_ClassInstanceVariable;
VALUE RBS_AST_Members_ClassVariable;
VALUE RBS_AST_Members_Extend;
VALUE RBS_AST_Members_Include;
VALUE RBS_AST_Members_InstanceVariable;
VALUE RBS_AST_Members_MethodDefinition;
VALUE RBS_AST_Members_MethodDefinition_Overload;
VALUE RBS_AST_Members_Prepend;
VALUE RBS_AST_Members_Private;
VALUE RBS_AST_Members_Public;

VALUE RBS_Namespace;
VALUE RBS_TypeName;

VALUE RBS_Types_Alias;
VALUE RBS_Types_Bases_Any;
VALUE RBS_Types_Bases_Bool;
VALUE RBS_Types_Bases_Bottom;
VALUE RBS_Types_Bases_Class;
VALUE RBS_Types_Bases_Instance;
VALUE RBS_Types_Bases_Nil;
VALUE RBS_Types_Bases_Self;
VALUE RBS_Types_Bases_Top;
VALUE RBS_Types_Bases_Void;
VALUE RBS_Types_Bases;
VALUE RBS_Types_Block;
VALUE RBS_Types_ClassInstance;
VALUE RBS_Types_ClassSingleton;
VALUE RBS_Types_Function_Param;
VALUE RBS_Types_Function;
VALUE RBS_Types_UntypedFunction;
VALUE RBS_Types_Interface;
VALUE RBS_Types_Intersection;
VALUE RBS_Types_Literal;
VALUE RBS_Types_Optional;
VALUE RBS_Types_Proc;
VALUE RBS_Types_Record;
VALUE RBS_Types_Tuple;
VALUE RBS_Types_Union;
VALUE RBS_Types_Variable;
VALUE RBS_Types;
VALUE RBS_MethodType;

VALUE RBS_ParsingError;

#define IMPORT_CONSTANT(var, parent, name) { var = rb_const_get(parent, rb_intern(name)); rb_gc_register_mark_object(var); }

void rbs__init_constants(void) {
  IMPORT_CONSTANT(RBS, rb_cObject, "RBS");
  IMPORT_CONSTANT(RBS_ParsingError, RBS, "ParsingError");

  IMPORT_CONSTANT(RBS_AST, RBS, "AST");
  IMPORT_CONSTANT(RBS_AST_Comment, RBS_AST, "Comment");
  IMPORT_CONSTANT(RBS_AST_Annotation, RBS_AST, "Annotation");
  IMPORT_CONSTANT(RBS_AST_TypeParam, RBS_AST, "TypeParam");

  IMPORT_CONSTANT(RBS_AST_Declarations, RBS_AST, "Declarations");

  IMPORT_CONSTANT(RBS_AST_Declarations_TypeAlias, RBS_AST_Declarations, "TypeAlias");
  IMPORT_CONSTANT(RBS_AST_Declarations_Constant, RBS_AST_Declarations, "Constant");
  IMPORT_CONSTANT(RBS_AST_Declarations_Global, RBS_AST_Declarations, "Global");
  IMPORT_CONSTANT(RBS_AST_Declarations_Interface, RBS_AST_Declarations, "Interface");
  IMPORT_CONSTANT(RBS_AST_Declarations_Module, RBS_AST_Declarations, "Module");
  IMPORT_CONSTANT(RBS_AST_Declarations_Module_Self, RBS_AST_Declarations_Module, "Self");
  IMPORT_CONSTANT(RBS_AST_Declarations_Class, RBS_AST_Declarations, "Class");
  IMPORT_CONSTANT(RBS_AST_Declarations_Class_Super, RBS_AST_Declarations_Class, "Super");
  IMPORT_CONSTANT(RBS_AST_Declarations_ClassAlias, RBS_AST_Declarations, "ClassAlias");
  IMPORT_CONSTANT(RBS_AST_Declarations_ModuleAlias, RBS_AST_Declarations, "ModuleAlias");

  IMPORT_CONSTANT(RBS_AST_Directives, RBS_AST, "Directives");
  IMPORT_CONSTANT(RBS_AST_Directives_Use, RBS_AST_Directives, "Use");
  IMPORT_CONSTANT(RBS_AST_Directives_Use_SingleClause, RBS_AST_Directives_Use, "SingleClause");
  IMPORT_CONSTANT(RBS_AST_Directives_Use_WildcardClause, RBS_AST_Directives_Use, "WildcardClause");

  IMPORT_CONSTANT(RBS_AST_Members, RBS_AST, "Members");
  IMPORT_CONSTANT(RBS_AST_Members_Alias, RBS_AST_Members, "Alias");
  IMPORT_CONSTANT(RBS_AST_Members_AttrAccessor, RBS_AST_Members, "AttrAccessor");
  IMPORT_CONSTANT(RBS_AST_Members_AttrReader, RBS_AST_Members, "AttrReader");
  IMPORT_CONSTANT(RBS_AST_Members_AttrWriter, RBS_AST_Members, "AttrWriter");
  IMPORT_CONSTANT(RBS_AST_Members_ClassInstanceVariable, RBS_AST_Members, "ClassInstanceVariable");
  IMPORT_CONSTANT(RBS_AST_Members_ClassVariable, RBS_AST_Members, "ClassVariable");
  IMPORT_CONSTANT(RBS_AST_Members_Extend, RBS_AST_Members, "Extend");
  IMPORT_CONSTANT(RBS_AST_Members_Include, RBS_AST_Members, "Include");
  IMPORT_CONSTANT(RBS_AST_Members_InstanceVariable, RBS_AST_Members, "InstanceVariable");
  IMPORT_CONSTANT(RBS_AST_Members_MethodDefinition, RBS_AST_Members, "MethodDefinition");
  IMPORT_CONSTANT(RBS_AST_Members_MethodDefinition_Overload, RBS_AST_Members_MethodDefinition, "Overload");
  IMPORT_CONSTANT(RBS_AST_Members_Prepend, RBS_AST_Members, "Prepend");
  IMPORT_CONSTANT(RBS_AST_Members_Private, RBS_AST_Members, "Private");
  IMPORT_CONSTANT(RBS_AST_Members_Public, RBS_AST_Members, "Public");

  IMPORT_CONSTANT(RBS_Namespace, RBS, "Namespace");
  IMPORT_CONSTANT(RBS_TypeName, RBS, "TypeName");
  IMPORT_CONSTANT(RBS_Types, RBS, "Types");
  IMPORT_CONSTANT(RBS_Types_Alias, RBS_Types, "Alias");
  IMPORT_CONSTANT(RBS_Types_Bases, RBS_Types, "Bases");
  IMPORT_CONSTANT(RBS_Types_Bases_Any, RBS_Types_Bases, "Any");
  IMPORT_CONSTANT(RBS_Types_Bases_Bool, RBS_Types_Bases, "Bool");
  IMPORT_CONSTANT(RBS_Types_Bases_Bottom, RBS_Types_Bases, "Bottom");
  IMPORT_CONSTANT(RBS_Types_Bases_Class, RBS_Types_Bases, "Class");
  IMPORT_CONSTANT(RBS_Types_Bases_Instance, RBS_Types_Bases, "Instance");
  IMPORT_CONSTANT(RBS_Types_Bases_Nil, RBS_Types_Bases, "Nil");
  IMPORT_CONSTANT(RBS_Types_Bases_Self, RBS_Types_Bases, "Self");
  IMPORT_CONSTANT(RBS_Types_Bases_Top, RBS_Types_Bases, "Top");
  IMPORT_CONSTANT(RBS_Types_Bases_Void, RBS_Types_Bases, "Void");
  IMPORT_CONSTANT(RBS_Types_Block, RBS_Types, "Block");
  IMPORT_CONSTANT(RBS_Types_ClassInstance, RBS_Types, "ClassInstance");
  IMPORT_CONSTANT(RBS_Types_ClassSingleton, RBS_Types, "ClassSingleton");
  IMPORT_CONSTANT(RBS_Types_Function, RBS_Types, "Function");
  IMPORT_CONSTANT(RBS_Types_UntypedFunction, RBS_Types, "UntypedFunction");
  IMPORT_CONSTANT(RBS_Types_Function_Param, RBS_Types_Function, "Param");
  IMPORT_CONSTANT(RBS_Types_Interface, RBS_Types, "Interface");
  IMPORT_CONSTANT(RBS_Types_Intersection, RBS_Types, "Intersection");
  IMPORT_CONSTANT(RBS_Types_Literal, RBS_Types, "Literal");
  IMPORT_CONSTANT(RBS_Types_Optional, RBS_Types, "Optional");
  IMPORT_CONSTANT(RBS_Types_Proc, RBS_Types, "Proc");
  IMPORT_CONSTANT(RBS_Types_Record, RBS_Types, "Record");
  IMPORT_CONSTANT(RBS_Types_Tuple, RBS_Types, "Tuple");
  IMPORT_CONSTANT(RBS_Types_Union, RBS_Types, "Union");
  IMPORT_CONSTANT(RBS_Types_Variable, RBS_Types, "Variable");
  IMPORT_CONSTANT(RBS_MethodType, RBS, "MethodType");
}

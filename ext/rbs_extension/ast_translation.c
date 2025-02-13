/*----------------------------------------------------------------------------*/
/* This file is generated by the templates/template.rb script and should not  */
/* be modified manually.                                                      */
/* To change the template see                                                 */
/* templates/ext/rbs_extension/ast_translation.c.erb                          */
/*----------------------------------------------------------------------------*/

#include "ast_translation.h"


const char* get_class_name(VALUE o) {
    VALUE klass = rb_class_of(o);      // Get the class of the object
    VALUE klass_name = rb_class_name(klass);  // Get the name of the class
    const char* name = StringValueCStr(klass_name);  // Convert to C string
    return name;
}

VALUE rbs_struct_to_ruby_value(rbs_node_t *instance) {
    if (instance == NULL) {
        fprintf(stderr, "Tried to call rbs_struct_to_ruby_value(NULL)\n");
        exit(1);
    }

    if (instance->type == RBS_TYPES_ZZZTMPNOTIMPLEMENTED) {
        // Special case: skip assertions/translation below.
        return instance->cached_ruby_value;
    }

    VALUE ruby_value = instance->cached_ruby_value;

    if (ruby_value == Qnil || ruby_value == Qundef) {
        fprintf(stderr, "cached_ruby_value is NULL\n");
        exit(1);
    }

    const char *class_name = get_class_name(ruby_value);

    switch (instance->type) {
        case RBS_AST_ANNOTATION: {
            if (strcmp(class_name, "RBS::AST::Annotation") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Annotation, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_COMMENT: {
            if (strcmp(class_name, "RBS::AST::Comment") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Comment, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_CLASS: {
            if (strcmp(class_name, "RBS::AST::Declarations::Class") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Class, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_CLASS_SUPER: {
            if (strcmp(class_name, "RBS::AST::Declarations::Class::Super") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Class::Super, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_CLASSALIAS: {
            if (strcmp(class_name, "RBS::AST::Declarations::ClassAlias") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::ClassAlias, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_CONSTANT: {
            if (strcmp(class_name, "RBS::AST::Declarations::Constant") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Constant, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_GLOBAL: {
            if (strcmp(class_name, "RBS::AST::Declarations::Global") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Global, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_INTERFACE: {
            if (strcmp(class_name, "RBS::AST::Declarations::Interface") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Interface, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_MODULE: {
            if (strcmp(class_name, "RBS::AST::Declarations::Module") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Module, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_MODULE_SELF: {
            if (strcmp(class_name, "RBS::AST::Declarations::Module::Self") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::Module::Self, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_MODULEALIAS: {
            if (strcmp(class_name, "RBS::AST::Declarations::ModuleAlias") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::ModuleAlias, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DECLARATIONS_TYPEALIAS: {
            if (strcmp(class_name, "RBS::AST::Declarations::TypeAlias") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Declarations::TypeAlias, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DIRECTIVES_USE: {
            if (strcmp(class_name, "RBS::AST::Directives::Use") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Directives::Use, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DIRECTIVES_USE_SINGLECLAUSE: {
            if (strcmp(class_name, "RBS::AST::Directives::Use::SingleClause") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Directives::Use::SingleClause, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_DIRECTIVES_USE_WILDCARDCLAUSE: {
            if (strcmp(class_name, "RBS::AST::Directives::Use::WildcardClause") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Directives::Use::WildcardClause, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_ALIAS: {
            if (strcmp(class_name, "RBS::AST::Members::Alias") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Alias, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_ATTRACCESSOR: {
            if (strcmp(class_name, "RBS::AST::Members::AttrAccessor") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::AttrAccessor, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_ATTRREADER: {
            if (strcmp(class_name, "RBS::AST::Members::AttrReader") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::AttrReader, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_ATTRWRITER: {
            if (strcmp(class_name, "RBS::AST::Members::AttrWriter") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::AttrWriter, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_CLASSINSTANCEVARIABLE: {
            if (strcmp(class_name, "RBS::AST::Members::ClassInstanceVariable") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::ClassInstanceVariable, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_CLASSVARIABLE: {
            if (strcmp(class_name, "RBS::AST::Members::ClassVariable") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::ClassVariable, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_EXTEND: {
            if (strcmp(class_name, "RBS::AST::Members::Extend") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Extend, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_INCLUDE: {
            if (strcmp(class_name, "RBS::AST::Members::Include") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Include, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_INSTANCEVARIABLE: {
            if (strcmp(class_name, "RBS::AST::Members::InstanceVariable") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::InstanceVariable, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_METHODDEFINITION: {
            if (strcmp(class_name, "RBS::AST::Members::MethodDefinition") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::MethodDefinition, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_METHODDEFINITION_OVERLOAD: {
            if (strcmp(class_name, "RBS::AST::Members::MethodDefinition::Overload") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::MethodDefinition::Overload, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_PREPEND: {
            if (strcmp(class_name, "RBS::AST::Members::Prepend") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Prepend, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_PRIVATE: {
            if (strcmp(class_name, "RBS::AST::Members::Private") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Private, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_MEMBERS_PUBLIC: {
            if (strcmp(class_name, "RBS::AST::Members::Public") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::Members::Public, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_AST_TYPEPARAM: {
            if (strcmp(class_name, "RBS::AST::TypeParam") != 0) {
                fprintf(stderr, "Expected class name: RBS::AST::TypeParam, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_METHODTYPE: {
            if (strcmp(class_name, "RBS::MethodType") != 0) {
                fprintf(stderr, "Expected class name: RBS::MethodType, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_NAMESPACE: {
            if (strcmp(class_name, "RBS::Namespace") != 0) {
                fprintf(stderr, "Expected class name: RBS::Namespace, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPENAME: {
            if (strcmp(class_name, "RBS::TypeName") != 0) {
                fprintf(stderr, "Expected class name: RBS::TypeName, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_ALIAS: {
            if (strcmp(class_name, "RBS::Types::Alias") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Alias, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_ANY: {
            if (strcmp(class_name, "RBS::Types::Bases::Any") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Any, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_BOOL: {
            if (strcmp(class_name, "RBS::Types::Bases::Bool") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Bool, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_BOTTOM: {
            if (strcmp(class_name, "RBS::Types::Bases::Bottom") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Bottom, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_CLASS: {
            if (strcmp(class_name, "RBS::Types::Bases::Class") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Class, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_INSTANCE: {
            if (strcmp(class_name, "RBS::Types::Bases::Instance") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Instance, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_NIL: {
            if (strcmp(class_name, "RBS::Types::Bases::Nil") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Nil, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_SELF: {
            if (strcmp(class_name, "RBS::Types::Bases::Self") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Self, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_TOP: {
            if (strcmp(class_name, "RBS::Types::Bases::Top") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Top, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BASES_VOID: {
            if (strcmp(class_name, "RBS::Types::Bases::Void") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Bases::Void, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_BLOCK: {
            if (strcmp(class_name, "RBS::Types::Block") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Block, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_CLASSINSTANCE: {
            if (strcmp(class_name, "RBS::Types::ClassInstance") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::ClassInstance, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_CLASSSINGLETON: {
            if (strcmp(class_name, "RBS::Types::ClassSingleton") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::ClassSingleton, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_FUNCTION: {
            if (strcmp(class_name, "RBS::Types::Function") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Function, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_FUNCTION_PARAM: {
            if (strcmp(class_name, "RBS::Types::Function::Param") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Function::Param, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_INTERFACE: {
            if (strcmp(class_name, "RBS::Types::Interface") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Interface, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_INTERSECTION: {
            if (strcmp(class_name, "RBS::Types::Intersection") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Intersection, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_LITERAL: {
            if (strcmp(class_name, "RBS::Types::Literal") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Literal, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_OPTIONAL: {
            if (strcmp(class_name, "RBS::Types::Optional") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Optional, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_PROC: {
            if (strcmp(class_name, "RBS::Types::Proc") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Proc, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_RECORD: {
            if (strcmp(class_name, "RBS::Types::Record") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Record, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_TUPLE: {
            if (strcmp(class_name, "RBS::Types::Tuple") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Tuple, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_UNION: {
            if (strcmp(class_name, "RBS::Types::Union") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Union, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_UNTYPEDFUNCTION: {
            if (strcmp(class_name, "RBS::Types::UntypedFunction") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::UntypedFunction, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_VARIABLE: {
            if (strcmp(class_name, "RBS::Types::Variable") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::Variable, got %s\n", class_name);
                exit(1);
            }
            break;
        }
        case RBS_TYPES_ZZZTMPNOTIMPLEMENTED: {
            if (strcmp(class_name, "RBS::Types::ZzzTmpNotImplemented") != 0) {
                fprintf(stderr, "Expected class name: RBS::Types::ZzzTmpNotImplemented, got %s\n", class_name);
                exit(1);
            }
            break;
        }
    }

    return instance->cached_ruby_value;
}

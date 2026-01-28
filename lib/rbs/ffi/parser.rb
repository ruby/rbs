# frozen_string_literal: true
require 'ffi'

module RBS

  module Native
    extend FFI::Library

    ffi_lib "librbs.dylib"

    NodeType = enum(
        :ast_annotation, 1,
        :ast_bool, 2,
        :ast_comment, 3,
        :ast_declarations_class, 4,
        :ast_declarations_class_super, 5,
        :ast_declarations_class_alias, 6,
        :ast_declarations_constant, 7,
        :ast_declarations_global, 8,
        :ast_declarations_interface, 9,
        :ast_declarations_module, 10,
        :ast_declarations_module_self, 11,
        :ast_declarations_module_alias, 12,
        :ast_declarations_type_alias, 13,
        :ast_directives_use, 14,
        :ast_directives_use_single_clause, 15,
        :ast_directives_use_wildcard_clause, 16,
        :ast_integer, 17,
        :ast_members_alias, 18,
        :ast_members_attr_accessor, 19,
        :ast_members_attr_reader, 20,
        :ast_members_attr_writer, 21,
        :ast_members_class_instance_variable, 22,
        :ast_members_class_variable, 23,
        :ast_members_extend, 24,
        :ast_members_include, 25,
        :ast_members_instance_variable, 26,
        :ast_members_method_definition, 27,
        :ast_members_method_definition_overload, 28,
        :ast_members_prepend, 29,
        :ast_members_private, 30,
        :ast_members_public, 31,
        :ast_ruby_annotations_class_alias_annotation, 32,
        :ast_ruby_annotations_colon_method_type_annotation, 33,
        :ast_ruby_annotations_instance_variable_annotation, 34,
        :ast_ruby_annotations_method_types_annotation, 35,
        :ast_ruby_annotations_module_alias_annotation, 36,
        :ast_ruby_annotations_node_type_assertion, 37,
        :ast_ruby_annotations_return_type_annotation, 38,
        :ast_ruby_annotations_skip_annotation, 39,
        :ast_ruby_annotations_type_application_annotation, 40,
        :ast_string, 41,
        :ast_type_param, 42,
        :method_type, 43,
        :namespace, 44,
        :signature, 45,
        :type_name, 46,
        :types_alias, 47,
        :types_bases_any, 48,
        :types_bases_bool, 49,
        :types_bases_bottom, 50,
        :types_bases_class, 51,
        :types_bases_instance, 52,
        :types_bases_nil, 53,
        :types_bases_self, 54,
        :types_bases_top, 55,
        :types_bases_void, 56,
        :types_block, 57,
        :types_class_instance, 58,
        :types_class_singleton, 59,
        :types_function, 60,
        :types_function_param, 61,
        :types_interface, 62,
        :types_intersection, 63,
        :types_literal, 64,
        :types_optional, 65,
        :types_proc, 66,
        :types_record, 67,
        :types_record_field_type, 68,
        :types_tuple, 69,
        :types_union, 70,
        :types_untyped_function, 71,
        :types_variable, 72,
        :keyword,
        :symbol,
    )

    module StructUtils
      def safe_get(name)
        value = self[name]
        if value.respond_to?(:null?) && value.null?
          value = nil
        end
        value
      end

      def inspect
        str = "#<#{self.class}"
        members.each do
          str << " #{it}=#{safe_get(it).inspect}"
        end
        str << ">"
        str
      end
    end

    class StringPointer < FFI::Struct
      include StructUtils

      layout :start, :pointer, :end, :pointer

      def self.new(str)
        str_ptr = super()
        @ptr = FFI::MemoryPointer.from_string(str)
        str_ptr[:start] = @ptr
        str_ptr[:end] = @ptr + str.length
        str_ptr
      end
    end

    typedef :uint32, :constant_id

    class Position < FFI::Struct
      include StructUtils

      layout :byte_pos, :int32,
             :char_pos, :int32,
             :line, :int32,
             :column, :int32
    end

    class Range < FFI::Struct
      include StructUtils

      layout :start, Position,
             :end, Position
    end

    class LocRange < FFI::Struct
      include StructUtils

      layout :start, :int32,
             :end, :int32
    end

    class LocEntry < FFI::Struct
      include StructUtils

      layout :name, :constant_id,
             :range, LocRange
    end

    typedef :uint32, :loc_entry_bitmap

    class LocChildren < FFI::Struct
      include StructUtils

      layout :len, :uint16,
             :cap, :uint16,
             :required_p, :loc_entry_bitmap,
             :entries, [LocEntry, 1]
    end

    class Location < FFI::Struct
      include StructUtils

      layout :rg, Range,
             :children, LocChildren.ptr
    end

    class LocationListNode < FFI::Struct
      include StructUtils

      layout :loc, Location.ptr,
             :next, :pointer # LocationListNode
    end

    class LocationList < FFI::Struct
      include StructUtils

      layout :allocator, :pointer,
             :head, LocationListNode.ptr,
             :tail, :pointer, # LocationListNode
             :length, :size_t
    end

    class Node < FFI::Struct
      include StructUtils

      layout :type, :uint8, :location, Location.ptr
    end

    class NodeListNode < FFI::Struct
      include StructUtils

      layout :node, Node.ptr, :next, :pointer
    end

    class NodeList < FFI::Struct
      include StructUtils

      layout :allocator, :pointer, :head, NodeListNode.ptr, :tail, NodeListNode.ptr, :length, :size_t

      def to_a
        ary = []
        each do |node|
          ary << node
        end
        ary
      end

      def each
        node = self.safe_get(:head)
        while node
          yield node
          nxt = node[:next]
          break if nxt.address == 0
          node = NodeListNode.new(nxt)
        end
      end
    end

    class HashNode < FFI::Struct
      include StructUtils

      layout :key, Node.ptr,
             :value, Node.ptr,
             :next, :pointer # HashNode
    end

    class Hash < FFI::Struct
      include StructUtils

      layout :allocator, :pointer,
             :head, HashNode,
             :tail, :pointer,
             :length, :size_t
    end

    class Namespace < FFI::Struct
      include StructUtils

      layout :base, Node,
             :path, NodeList.ptr,
             :absolute, :bool
    end

    class ASTSymbol < FFI::Struct
      include StructUtils

      layout :base, Node,
             :constant_id, :constant_id
    end

    class TypeName < FFI::Struct
      include StructUtils

      layout :base, Node,
             :rbs_namespace, Namespace.ptr,
             :name, ASTSymbol.ptr
    end

    class ASTAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :string, StringPointer
    end

    class ASTBool < FFI::Struct
      include StructUtils

      layout :base, Node,
             :value, :bool
    end

    class ASTComment < FFI::Struct
      include StructUtils

      layout :base, Node,
             :string, StringPointer
    end

    class ASTDeclarationsClassSuper < FFI::Struct
      include StructUtils

      layout :base, Node,
             :new_name, TypeName.ptr,
             :old_name, TypeName.ptr,
             :comment, ASTComment.ptr,
             :anotations, NodeList.ptr
    end

    class ASTDeclarationsClass < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :type_params, NodeList.ptr,
             :super_class, ASTDeclarationsClassSuper.ptr,
             :members, NodeList.ptr, :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTDeclarationsGlobal < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :comment, ASTComment.ptr,
             :annotations, NodeList.ptr
    end

    class ASTDeclarationsInterface < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :type_params, NodeList.ptr,
             :members, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTDeclarationsModule < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :args, NodeList.ptr,
             :self_types, NodeList.ptr,
             :members, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTDeclarationsModuleSelf < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :args, NodeList.ptr
    end

    class ASTDeclarationsModuleAlias < FFI::Struct
      include StructUtils

      layout :base, Node,
             :new_name, TypeName.ptr,
             :old_name, TypeName.ptr,
             :comment, ASTComment.ptr,
             :annotations, NodeList.ptr
    end

    class ASTDeclarationsTypeAlias < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :type_params, NodeList.ptr,
             :type, Node.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTDeclarationsUse < FFI::Struct
      include StructUtils

      layout :base, Node,
             :clauses, NodeList.ptr
    end

    class ASTDeclarationsUseSingleClause < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type_name, TypeName.ptr,
             :new_name, ASTSymbol.ptr
    end

    class ASTDirectivesUseWildcardClause < FFI::Struct
      include StructUtils

      layout :base, Node,
             :namespace, Namespace.ptr
    end

    class ASTInteger < FFI::Struct
      include StructUtils

      layout :base, Node,
             :string_representation, StringPointer.ptr
    end

    class Keyword < FFI::Struct
      include StructUtils

      layout :base, Node,
             :constant_id, :constant_id
    end

    class ASTMembersAlias < FFI::Struct
      include StructUtils

      layout :base, Node,
             :new_name, ASTSymbol.ptr,
             :old_name, ASTSymbol.ptr,
             :kind, Keyword.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersAttrAccessor < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :ivar_name, Node.ptr,
             :kind, Keyword.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr,
             :visibility, Keyword.ptr
    end

    class ASTMembersAttReader < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :ivar_name, Node.ptr,
             :kind, Keyword.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr,
             :visibility, Keyword.ptr
    end

    class ASTMembersAttWriter < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :ivar_name, Node.ptr,
             :kind, Keyword.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr,
             :visibility, Keyword.ptr
    end

    class ASTMembersClassInstanceVariable < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersExtend < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :args, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersInclude < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :args, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersInstanceVariable < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :type, Node.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersMethodDefinition < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :kind, Keyword.ptr,
             :overloads, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr,
             :overloading, :bool,
             :visibility, Keyword.ptr
    end

    class ASTMembersMethodDefinitionOverload < FFI::Struct
      include StructUtils

      layout :base, Node,
             :annotations, NodeList.ptr,
             :method_type, Node.ptr
    end

    class ASTMembersPrepend < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :node_list, NodeList.ptr,
             :annotations, NodeList.ptr,
             :comment, ASTComment.ptr
    end

    class ASTMembersPrivate < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class ASTMembersPublic < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class Token < FFI::Struct
      include StructUtils

      layout :type, :uint8, # RBSTokenType enum
             :range, Range
    end

    class ASTRubyAnnotationsClassAliasAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :keyword_location, Location.ptr,
             :type_name, TypeName.ptr,
             :location, Location.ptr
    end

    class ASTRubyAnnotationsColonMethodTypeAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :annotations, NodeList.ptr,
             :method_type, Node.ptr
    end

    class ASTRubyAnnotationsInstanceVariableAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :ivar_name, ASTSymbol.ptr,
             :ivar_name_location, Location.ptr,
             :colon_location, Location.ptr,
             :type, Node.ptr,
             :comment_location, Location.ptr
    end

    class ASTRubyAnnotationsMethodTypesAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :overloads, NodeList.ptr,
             :vertical_bar_locations, LocationList.ptr
    end

    class ASTRubyAnnotationsModuleAliasAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :keyword_location, Location.ptr,
             :type_name, TypeName.ptr,
             :type_name_location, Location.ptr
    end

    class ASTRubyAnnotationsNodeTypeAssertion < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :type, Node.ptr
    end

    class ASTRubyAnnotationsReturnTypeAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :return_location, Location.ptr,
             :colon_location, Location.ptr,
             :return_type, TypeName.ptr,
             :comment_location, Location.ptr
    end

    class ASTRubyAnnotationsSkipAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :skip_location, Location.ptr,
             :comment_location, Location.ptr
    end

    class ASTRubyAnnotationsTypeApplicationAnnotation < FFI::Struct
      include StructUtils

      layout :base, Node,
             :prefix_location, Location.ptr,
             :type_args, NodeList.ptr,
             :close_bracket_location, Location.ptr,
             :comma_locations, Location.ptr
    end

    class ASTString < FFI::Struct
      include StructUtils

      layout :base, Node,
             :string, StringPointer.ptr
    end

    class ASTTypeParam < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr,
             :variance, Keyword.ptr,
             :upper_bound, Node.ptr,
             :lower_bound, Node.ptr,
             :default_type, Node.ptr,
             :unchecked, :bool
    end

    class TypesBlock < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr,
             :required, :bool,
             :self_type, Node.ptr
    end

    class MethodType < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type_params, NodeList.ptr,
             :type, Node.ptr,
             :block, TypesBlock.ptr
    end

    class Signature < FFI::Struct
      include StructUtils

      layout :base, Node, :directives, NodeList.ptr, :declarations, NodeList.ptr

      def inspect
        [base, directives, declarations].inspect
      end

      def base
        self.safe_get(:base)
      end

      def directives
        self.safe_get(:directives)
      end

      def declarations
        self.safe_get(:declarations)
      end
    end

    class TypesAlias < FFI::Struct
      include StructUtils
      
      layout :base, Node,
             :type_name, TypeName.ptr,
             :args, NodeList.ptr
    end

    class TypesBasesAny < FFI::Struct
      include StructUtils

      layout :base, Node,
             :todo, :bool
    end

    class TypesBasesBool < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesBottom < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesClasses < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesInstance < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesNil < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesSelf < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesTop < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesBasesVoid < FFI::Struct
      include StructUtils

      layout :base, Node
    end

    class TypesClassInstance < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr,
             :args, NodeList.ptr
    end

    class TypesClassSingleton < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, TypeName.ptr
    end

    class TypesFunction < FFI::Struct
      include StructUtils

      layout :base, Node,
             :required_positionals, NodeList.ptr,
             :optional_positionals, NodeList.ptr,
             :rest_positionals, Node.ptr,
             :trailing_positionals, NodeList.ptr,
             :required_keywords, Hash.ptr,
             :optional_keywords, Hash.ptr,
             :rest_keywords, Node.ptr,
             :return_type, Node.ptr
    end

    class TypesFunctionParam < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr,
             :name, ASTSymbol.ptr
    end

    class TypesInterface < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr,
             :args, NodeList.ptr
    end

    class TypesIntersection < FFI::Struct
      include StructUtils

      layout :base, Node,
             :types, NodeList.ptr
    end

    class TypesLiteral < FFI::Struct
      include StructUtils

      layout :base, Node,
             :literal, Node.ptr
    end

    class TypesOptional < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr
    end

    class TypesProc < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr,
             :block, TypesBlock.ptr,
             :self_type, Node.ptr
    end

    class TypesRecord < FFI::Struct
      include StructUtils

      layout :base, Node,
             :all_fields, Hash.ptr
    end

    class TypesRecordFieldType < FFI::Struct
      include StructUtils

      layout :base, Node,
             :type, Node.ptr,
             :required, :bool
    end

    class TypesTuple < FFI::Struct
      include StructUtils

      layout :base, Node,
             :types, NodeList.ptr
    end

    class TypesUnion < FFI::Struct
      include StructUtils

      layout :base, Node,
             :types, NodeList.ptr
    end

    class TypesUntypedFunction < FFI::Struct
      include StructUtils

      layout :base, Node,
             :return_type, Node.ptr
    end

    class TypesVariable < FFI::Struct
      include StructUtils

      layout :base, Node,
             :name, ASTSymbol.ptr
    end

    class ASTRubyAnnotations < FFI::Struct
      include StructUtils

      layout :base, Node,
             :colon_method_type_annotation, ASTRubyAnnotationsColonMethodTypeAnnotation.ptr,
             :method_types_annotation, ASTRubyAnnotationsMethodTypesAnnotation.ptr,
             :node_type_assertion, ASTRubyAnnotationsNodeTypeAssertion.ptr,
             :return_type_annotation, ASTRubyAnnotationsReturnTypeAnnotation.ptr,
             :skip_annotation, ASTRubyAnnotationsSkipAnnotation.ptr
    end

    attach_function :rbs_encoding_find, [:pointer, :pointer], :pointer

    attach_function :rbs_parser_new, [StringPointer.by_value, :pointer, :int32, :int32], :pointer
    attach_function :rbs_parser_free, [:pointer], :void
    attach_function :rbs_parse_type, [:pointer, :pointer, :bool, :bool, :bool], :bool
    attach_function :rbs_parse_signature, [:pointer, :pointer], :bool
    attach_function :rbs_constant_pool_init, [:pointer, :uint32], :bool
    attach_variable :RBS_GLOBAL_CONSTANT_POOL, :pointer
  end

  Native.rbs_constant_pool_init(Native.RBS_GLOBAL_CONSTANT_POOL, 7)

  class Parser

    def self.new_parser(str, start_pos, end_pos)
      buffer = Native::StringPointer.new(str)
      enc = str.encoding.name
      encoding_ptr = FFI::MemoryPointer.from_string(enc)
      rbs_encoding = Native.rbs_encoding_find(encoding_ptr, encoding_ptr + enc.length)
      Native.rbs_parser_new buffer, rbs_encoding, start_pos, end_pos
    end

    def self.free_parser(parser)
      Native.rbs_parser_free parser
    end

    def _parse_type(buffer, start_pos, end_pos, variables, require_eof)

    end

    def _parse_method_type(buffer, start_pos, end_pos, variables, require_eof)

    end

    def self._parse_signature(buffer, start_pos, end_pos)
      str = buffer.content

      parser = new_parser(str, start_pos, end_pos)

      signature_ptr = FFI::MemoryPointer.new(:pointer, 1)

      result = Native.rbs_parse_signature parser, signature_ptr

      signature = Native::Signature.new(signature_ptr.get_pointer(0))

      raise RuntimeError.new("failed to parse signature") unless result

      [signature.directives, signature.declarations]
    end

    def _parse_type_params(buffer, start_pos, end_pos, module_type_params)

    end

    def _parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)

    end

    def _parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)

    end
  end
end

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

    class FFI::Struct
      def safe_get(name)
        value = self[name]
        if value.respond_to?(:null?) && value.null?
          value = nil
        end
        value
      end
    end

    class StringPointer < FFI::Struct
      layout :start, :pointer, :end, :pointer

      def self.new(str)
        str_ptr = super()
        @ptr = FFI::MemoryPointer.from_string(str)
        str_ptr[:start] = @ptr
        str_ptr[:end] = @ptr + str.length
        str_ptr
      end
    end

    class Node < FFI::Struct
      layout :type, :uint8, :location, :pointer

      def inspect
        "#<Node type=#{self.safe_get(:type).inspect} location:#{self.safe_get(:location).inspect}"
      end
    end

    class NodeListNode < FFI::Struct
      layout :node, Node.ptr, :next, :pointer

      def inspect
        "#<NodeListNode node=#{self.safe_get(:node).inspect} next=#{self.safe_get(:next).inspect}"
      end
    end

    class NodeList < FFI::Struct
      layout :allocator, :pointer, :head, NodeListNode.ptr, :tail, NodeListNode.ptr, :length, :size_t

      def to_a
        ary = []
        head = self.safe_get(:head)
        while head
          ary << head.safe_get(:node)
          nxt = head[:next]
          break if nxt.address == 0
          head = NodeListNode.new(nxt)
        end
        ary
      end

      def inspect
        str = +"#<NodeList ["
        head = self.safe_get(:head)
        while head
          str << head.inspect
          nxt = head[:next]
          break if nxt.address == 0
          head = NodeListNode.new(nxt)
        end
        str << "]>"
        str
      end
    end

    class Signature < FFI::Struct
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

    attach_function :rbs_encoding_find, [:pointer, :pointer], :pointer

    attach_function :rbs_parser_new, [StringPointer.by_value, :pointer, :int32, :int32], :pointer
    attach_function :rbs_parser_free, [:pointer], :void
    attach_function :rbs_parse_type, [:pointer, :pointer, :bool, :bool, :bool], :bool
    attach_function :rbs_parse_signature, [:pointer, :pointer], :bool
  end

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

      [signature.directives.to_a, signature.declarations.to_a]
    end

    def _parse_type_params(buffer, start_pos, end_pos, module_type_params)

    end

    def _parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)

    end

    def _parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)

    end
  end
end

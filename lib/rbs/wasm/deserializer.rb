# frozen_string_literal: true

require_relative "serialization_schema"

module RBS
  module WASM
    # Rebuilds RBS::AST objects from the binary buffer produced by
    # `rbs_serialize_node` (src/serialize.c), driven by the generated
    # SerializationSchema. This is the pure-Ruby counterpart of the C extension's
    # ast_translation.c, used when the parser runs inside WebAssembly (JRuby).
    #
    # All locations are reconstructed through the public RBS::Location API, so the
    # same code works whether RBS::Location is backed by the C extension (CRuby)
    # or by a pure-Ruby implementation (JRuby).
    class Deserializer
      # Deserialize a buffer produced for a whole signature, returning
      # `[directives, declarations]` to match RBS::Parser._parse_signature.
      def self.deserialize(bytes, buffer)
        new(bytes, buffer).read_node
      end

      # Deserialize a bare node list (rbs_serialize_node_list), e.g. the result
      # of RBS::Parser._parse_type_params.
      def self.deserialize_node_list(bytes, buffer)
        new(bytes, buffer).read_node_list
      end

      # Deserialize the token stream produced by rbs_wasm_lex into the
      # [type, location] pairs RBS::Parser._lex returns.
      def self.deserialize_tokens(bytes, buffer)
        new(bytes, buffer).read_tokens
      end

      def initialize(bytes, buffer)
        @bytes = bytes
        @buffer = buffer
        # Symbols and rbs_string fields (comments, annotations) inherit the
        # source encoding, matching ast_translation.c. String/Integer literal
        # nodes are always UTF-8 (see read_node).
        @encoding = buffer.content.encoding
        @pos = 0
        @class_cache = {} #: Hash[String, untyped]
      end

      def read_node
        tag = read_u8
        return nil if tag == 0
        return read_string(@encoding).to_sym if tag == SerializationSchema::SYMBOL_TAG

        entry = SerializationSchema::SCHEMA[tag] or raise "Unknown node tag: #{tag}"

        case entry[0]
        when :node then read_struct(entry)
        when :bool then read_u8 != 0
        when :integer then read_string(Encoding::UTF_8).to_i
        when :string_value then read_string(Encoding::UTF_8)
        when :record_field then [read_node, read_u8 != 0]
        when :signature then [read_node_list, read_node_list]
        when :namespace then RBS::Namespace[read_node_list, read_u8 != 0]
        when :type_name then RBS::TypeName[read_node, read_node]
        else raise "Unknown schema entry kind: #{entry[0].inspect}"
        end
      end

      def read_node_list
        Array.new(read_count) { read_node }
      end

      # The lex stream has no leading count: read records until the buffer is
      # exhausted. Each is a token type name followed by its character range.
      def read_tokens
        tokens = [] #: Array[[ Symbol, Location ]]
        until @pos >= @bytes.bytesize
          type = read_string(Encoding::UTF_8).to_sym
          start_char = read_i32
          end_char = read_i32
          tokens << [type, RBS::Location.new(@buffer, start_char, end_char)]
        end
        tokens
      end

      private

      def read_struct(entry)
        _, class_name, expose_location, loc_children, fields, resolve_type_params = entry

        location = read_location(loc_children) if expose_location

        kwargs = {} #: Hash[Symbol, untyped]
        (fields || []).each do |name, reader|
          kwargs[name] = read_field(reader)
        end

        RBS::AST::TypeParam.resolve_variables(kwargs[:type_params]) if resolve_type_params

        klass = class_for(class_name)
        if expose_location
          klass.new(location: location, **kwargs)
        else
          klass.new(**kwargs)
        end
      end

      def read_field(reader)
        case reader
        when :node then read_node
        when :node_list then read_node_list
        when :hash then read_hash
        when :string then read_string(@encoding)
        when :bool then read_u8 != 0
        when :location_range then read_location_value
        when :location_range_list then read_location_value_list
        when :attr_ivar_name then read_attr_ivar_name
        else # [:enum, [value_or_nil, ...]]
          reader[1][read_u8]
        end
      end

      def read_hash
        hash = {} #: Hash[untyped, untyped]
        read_count.times do
          key = read_node
          hash[key] = read_node
        end
        hash
      end

      # A count of nested items. Each item is at least one byte, so a count that
      # exceeds the bytes remaining signals the cursor has drifted out of sync.
      def read_count
        count = read_u32
        if count > @bytes.bytesize - @pos
          raise "Corrupt buffer: count #{count} exceeds #{@bytes.bytesize - @pos} remaining bytes at offset #{@pos}"
        end
        count
      end

      # The base location of a node, followed by its named child ranges.
      def read_location(loc_children)
        base = read_range
        children = (loc_children || []).map { |name, required| [name, required, read_range] }

        return nil unless base

        location = RBS::Location.new(@buffer, base[0], base[1])
        children.each do |name, required, range|
          if required
            location.add_required_child(name, range[0]...range[1]) if range
          else
            location.add_optional_child(name, range ? (range[0]...range[1]) : nil)
          end
        end
        location
      end

      # A standalone location range field: nil or an RBS::Location without children.
      def read_location_value
        range = read_range
        range && RBS::Location.new(@buffer, range[0], range[1])
      end

      def read_location_value_list
        Array.new(read_count) { read_location_value }
      end

      def read_attr_ivar_name
        case read_u8
        when 0 then nil   # inferred instance variable
        when 1 then false # no instance variable
        else read_string(@encoding).to_sym
        end
      end

      # Reads a presence byte and, when present, the start/end character positions.
      def read_range
        return nil if read_u8 == 0

        start_char = read_i32
        end_char = read_i32
        [start_char, end_char]
      end

      def read_u8
        byte = @bytes.getbyte(@pos) or raise "Unexpected end of buffer"
        @pos += 1
        byte
      end

      def read_u32
        value = @bytes.unpack1("L<", offset: @pos) #: Integer
        @pos += 4
        value
      end

      def read_i32
        value = @bytes.unpack1("l<", offset: @pos) #: Integer
        @pos += 4
        value
      end

      def read_string(encoding)
        length = read_u32
        string = @bytes.byteslice(@pos, length) or raise "Unexpected end of buffer"
        @pos += length
        string.force_encoding(encoding)
      end

      def class_for(name)
        @class_cache[name] ||= Object.const_get(name)
      end
    end
  end
end

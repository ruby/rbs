# frozen_string_literal: true

# FFI backend for non-MRI Ruby implementations (JRuby, TruffleRuby).
#
# This file defines the same `RBS::Parser._parse_*` / `._lex` singleton
# methods as the C extension (ext/rbs_extension/main.c), backed by the core
# parser built as a plain shared library (librbs, see
# ext/rbs_extension/extconf.rb). Results cross the FFI boundary as a
# serialized byte buffer produced by src/ffi_entry.c, which is decoded here
# and by RBS::Parser::Deserializer.
#
# Set RBS_FFI_BACKEND=1 to use this backend on MRI for development/testing.

require "ffi"
require "rbs/parser/deserializer"

module RBS
  class Parser
    module FFIBackend
      extend ::FFI::Library

      STATUS_SUCCESS = 0
      STATUS_ERROR = 1
      STATUS_NIL = 2

      soext = RbConfig::CONFIG["SOEXT"] ||
              (RbConfig::CONFIG["host_os"] =~ /darwin/ ? "dylib" : "so")
      ffi_lib File.expand_path("../librbs.#{soext}", __dir__)

      attach_function :rbs_ffi_lex, [:pointer, :size_t, :string, :int], :pointer
      attach_function :rbs_ffi_parse_type, [:pointer, :size_t, :string, :int, :int, :pointer, :bool, :bool, :bool, :bool], :pointer
      attach_function :rbs_ffi_parse_method_type, [:pointer, :size_t, :string, :int, :int, :pointer, :bool], :pointer
      attach_function :rbs_ffi_parse_signature, [:pointer, :size_t, :string, :int, :int], :pointer
      attach_function :rbs_ffi_parse_type_params, [:pointer, :size_t, :string, :int, :int, :bool], :pointer
      attach_function :rbs_ffi_parse_inline_leading_annotation, [:pointer, :size_t, :string, :int, :int, :pointer], :pointer
      attach_function :rbs_ffi_parse_inline_trailing_annotation, [:pointer, :size_t, :string, :int, :int, :pointer], :pointer
      attach_function :rbs_ffi_result_bytes, [:pointer], :pointer
      attach_function :rbs_ffi_result_length, [:pointer], :size_t
      attach_function :rbs_ffi_result_free, [:pointer], :void

      # Calls the named one-shot entry point with the buffer content and
      # returns the serialized result as a binary String. The native result
      # is released before returning.
      def self.fetch_result(name, content, *args)
        source = ::FFI::MemoryPointer.from_string(content)
        result = public_send(name, source, content.bytesize, content.encoding.name, *args)
        begin
          rbs_ffi_result_bytes(result).read_string(rbs_ffi_result_length(result))
        ensure
          rbs_ffi_result_free(result)
        end
      end

      # Mirrors `validate_position_range()` in ext/rbs_extension/main.c.
      def self.validate_position_range(start_pos, end_pos)
        if start_pos < 0 || end_pos < 0
          raise ArgumentError, "negative position range: #{start_pos}...#{end_pos}"
        end
        if start_pos > end_pos
          raise ArgumentError, "invalid position range: #{start_pos}...#{end_pos}"
        end
      end

      # Packs an array of type variable Symbols into the binary layout
      # consumed by `declare_type_variables()` in src/ffi_entry.c: u32 count,
      # then (u32 length, bytes) per name. Returns nil for nil input.
      # Type checks mirror `declare_type_variables()` in
      # ext/rbs_extension/main.c.
      def self.pack_variables(variables)
        return nil if variables.nil?

        unless variables.is_a?(Array)
          raise TypeError, "wrong argument type #{variables.class} (must be an Array of Symbols or nil)"
        end

        packed = [variables.size].pack("L<")
        variables.each do |variable|
          unless variable.is_a?(Symbol)
            raise TypeError, "Type variables Array contains invalid value #{variable.inspect} of type #{variable.class} (must be an Array of Symbols or nil)"
          end

          name = variable.to_s
          packed << [name.bytesize].pack("L<") << name.b
        end

        ::FFI::MemoryPointer.from_string(packed)
      end

      # Decodes a serialized parse result: returns the deserialized node (or
      # node list with list: true) on success, nil for the nil status, and
      # raises RBS::ParsingError for parse errors.
      def self.decode(buffer, bytes, list: false)
        reader = Reader.new(bytes)

        case reader.read_u8
        when STATUS_SUCCESS
          deserializer = Deserializer.new(buffer: buffer, reader: reader)
          list ? deserializer.read_node_list : deserializer.read_node
        when STATUS_NIL
          nil
        when STATUS_ERROR
          raise_error(buffer, reader)
        end
      end

      # Mirrors `raise_error()` in ext/rbs_extension/main.c.
      def self.raise_error(buffer, reader)
        syntax_error = reader.read_u8 != 0
        message = reader.read_string.force_encoding(Encoding::UTF_8)
        token_type = reader.read_string.force_encoding(Encoding::UTF_8)
        start_char = reader.read_i32
        end_char = reader.read_i32

        raise "Unexpected error" unless syntax_error

        location = Location.new(buffer, start_char, end_char)
        raise ParsingError.new(location, message, token_type)
      end

      # Sequential decoder for the byte format written by src/ffi_entry.c and
      # src/serializer.c. All integers are little-endian.
      class Reader
        def initialize(bytes)
          @bytes = bytes
          @pos = 0
        end

        def read_u8
          value = @bytes.getbyte(@pos) or raise "Unexpected end of serialized parser result"
          @pos += 1
          value
        end

        def read_u32
          raw = @bytes.byteslice(@pos, 4) or raise "Unexpected end of serialized parser result"
          @pos += 4
          raw.unpack1("L<")
        end

        def read_i32
          raw = @bytes.byteslice(@pos, 4) or raise "Unexpected end of serialized parser result"
          @pos += 4
          raw.unpack1("l<")
        end

        def read_string
          length = read_u32
          value = @bytes.byteslice(@pos, length) or raise "Unexpected end of serialized parser result"
          @pos += length
          value
        end
      end
    end

    def self._lex(buffer, end_pos)
      content = buffer.content
      reader = FFIBackend::Reader.new(FFIBackend.fetch_result(:rbs_ffi_lex, content, end_pos))

      reader.read_u8 # status: lexing always succeeds

      Array.new(reader.read_u32) do
        type = reader.read_string.to_sym
        start_char = reader.read_i32
        end_char = reader.read_i32
        [type, Location.new(buffer, start_char, end_char)]
      end
    end

    def self._parse_type(buffer, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
      FFIBackend.validate_position_range(start_pos, end_pos)
      vars = FFIBackend.pack_variables(variables)
      bytes = FFIBackend.fetch_result(
        :rbs_ffi_parse_type, buffer.content, start_pos, end_pos, vars,
        !!require_eof, !!void_allowed, !!self_allowed, !!classish_allowed
      )
      FFIBackend.decode(buffer, bytes)
    end

    def self._parse_method_type(buffer, start_pos, end_pos, variables, require_eof)
      FFIBackend.validate_position_range(start_pos, end_pos)
      vars = FFIBackend.pack_variables(variables)
      bytes = FFIBackend.fetch_result(
        :rbs_ffi_parse_method_type, buffer.content, start_pos, end_pos, vars, !!require_eof
      )
      FFIBackend.decode(buffer, bytes)
    end

    def self._parse_signature(buffer, start_pos, end_pos)
      FFIBackend.validate_position_range(start_pos, end_pos)
      bytes = FFIBackend.fetch_result(:rbs_ffi_parse_signature, buffer.content, start_pos, end_pos)
      FFIBackend.decode(buffer, bytes)
    end

    def self._parse_type_params(buffer, start_pos, end_pos, module_type_params)
      FFIBackend.validate_position_range(start_pos, end_pos)
      bytes = FFIBackend.fetch_result(
        :rbs_ffi_parse_type_params, buffer.content, start_pos, end_pos, !!module_type_params
      )
      FFIBackend.decode(buffer, bytes, list: true)
    end

    def self._parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)
      FFIBackend.validate_position_range(start_pos, end_pos)
      vars = FFIBackend.pack_variables(variables)
      bytes = FFIBackend.fetch_result(
        :rbs_ffi_parse_inline_leading_annotation, buffer.content, start_pos, end_pos, vars
      )
      FFIBackend.decode(buffer, bytes)
    end

    def self._parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)
      FFIBackend.validate_position_range(start_pos, end_pos)
      vars = FFIBackend.pack_variables(variables)
      bytes = FFIBackend.fetch_result(
        :rbs_ffi_parse_inline_trailing_annotation, buffer.content, start_pos, end_pos, vars
      )
      FFIBackend.decode(buffer, bytes)
    end
  end
end

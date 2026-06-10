# frozen_string_literal: true

# FFI backend for non-MRI Ruby implementations (JRuby, TruffleRuby).
#
# This file defines the same `RBS::Parser._parse_*` / `._lex` singleton
# methods as the C extension (ext/rbs_extension/main.c), backed by the core
# parser built as a plain shared library (librbs, see
# ext/rbs_extension/extconf.rb). Results cross the FFI boundary as a
# serialized byte buffer produced by src/ffi_entry.c, which is decoded here.
#
# Set RBS_FFI_BACKEND=1 to use this backend on MRI for development/testing.

require "ffi"

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

      # Sequential decoder for the byte format written by src/ffi_entry.c.
      # All integers are little-endian.
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
      raise NotImplementedError, "RBS::Parser.parse_type is not supported by the FFI backend yet"
    end

    def self._parse_method_type(buffer, start_pos, end_pos, variables, require_eof)
      raise NotImplementedError, "RBS::Parser.parse_method_type is not supported by the FFI backend yet"
    end

    def self._parse_signature(buffer, start_pos, end_pos)
      raise NotImplementedError, "RBS::Parser.parse_signature is not supported by the FFI backend yet"
    end

    def self._parse_type_params(buffer, start_pos, end_pos, module_type_params)
      raise NotImplementedError, "RBS::Parser.parse_type_params is not supported by the FFI backend yet"
    end

    def self._parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)
      raise NotImplementedError, "RBS::Parser.parse_inline_leading_annotation is not supported by the FFI backend yet"
    end

    def self._parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)
      raise NotImplementedError, "RBS::Parser.parse_inline_trailing_annotation is not supported by the FFI backend yet"
    end
  end
end

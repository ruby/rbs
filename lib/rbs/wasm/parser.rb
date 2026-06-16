# frozen_string_literal: true

require_relative "runtime"
require_relative "deserializer"

module RBS
  # WebAssembly-backed implementation of the parser primitives.
  #
  # On CRuby these come from the C extension (ext/rbs_extension/main.c). JRuby
  # loads this instead: it runs the parser inside WebAssembly, then rebuilds the
  # AST with RBS::WASM::Deserializer. rbs/parser_aux.rb layers the public
  # RBS::Parser API on top, exactly as it does for the C extension.
  class Parser
    class << self
      def _parse_signature(buffer, start_pos, end_pos)
        success, bytes = WASM::Runtime.instance.parse_signature(buffer.content, start_pos, end_pos)
        raise_parsing_error(buffer, bytes) unless success

        WASM::Deserializer.deserialize(bytes, buffer)
      end

      def _parse_type(buffer, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        success, bytes = WASM::Runtime.instance.parse_type(buffer.content, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        raise_parsing_error(buffer, bytes) unless success

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_method_type(buffer, start_pos, end_pos, variables, require_eof)
        success, bytes = WASM::Runtime.instance.parse_method_type(buffer.content, start_pos, end_pos, variables, require_eof)
        raise_parsing_error(buffer, bytes) unless success

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_type_params(buffer, start_pos, end_pos, module_type_params)
        raise NotImplementedError, "RBS::Parser._parse_type_params is not yet supported on #{RUBY_ENGINE}"
      end

      def _lex(buffer, end_pos)
        raise NotImplementedError, "RBS::Parser._lex is not yet supported on #{RUBY_ENGINE}"
      end

      def _parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)
        raise NotImplementedError, "RBS::Parser._parse_inline_leading_annotation is not yet supported on #{RUBY_ENGINE}"
      end

      def _parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)
        raise NotImplementedError, "RBS::Parser._parse_inline_trailing_annotation is not yet supported on #{RUBY_ENGINE}"
      end

      private

      # An empty result means the parser reached EOF immediately (`nil`).
      def deserialize_or_nil(bytes, buffer)
        bytes.empty? ? nil : WASM::Deserializer.deserialize(bytes, buffer)
      end

      # Decodes the error blob written by set_error_result (rbs_wasm.c) and raises
      # the same error the C extension would (see raise_error in main.c).
      def raise_parsing_error(buffer, blob)
        start_char, end_char, syntax_error = blob.unpack("l<l<C")

        raise "Unexpected error" if syntax_error.zero?

        offset = 9
        token_type_length = blob.unpack1("L<", offset: offset)
        offset += 4
        token_type = blob.byteslice(offset, token_type_length).to_s.force_encoding(Encoding::UTF_8)
        offset += token_type_length

        message_length = blob.unpack1("L<", offset: offset)
        offset += 4
        message = blob.byteslice(offset, message_length).to_s.force_encoding(Encoding::UTF_8)

        location = Location.new(buffer, start_char, end_char)
        raise ParsingError.new(location, message, token_type)
      end
    end
  end
end

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
        validate_position_range(start_pos, end_pos)
        encoding = buffer.content.encoding.name
        success, bytes = WASM::Runtime.instance.parse_signature(buffer.content, encoding, start_pos, end_pos)
        raise_parsing_error(buffer, bytes) unless success

        WASM::Deserializer.deserialize(bytes, buffer)
      end

      def _parse_type(buffer, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        validate_position_range(start_pos, end_pos)
        validate_variables(variables)
        encoding = buffer.content.encoding.name
        success, bytes = WASM::Runtime.instance.parse_type(buffer.content, encoding, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        raise_parsing_error(buffer, bytes) unless success

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_method_type(buffer, start_pos, end_pos, variables, require_eof)
        validate_position_range(start_pos, end_pos)
        validate_variables(variables)
        encoding = buffer.content.encoding.name
        success, bytes = WASM::Runtime.instance.parse_method_type(buffer.content, encoding, start_pos, end_pos, variables, require_eof)
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

      # Reject negative or reversed ranges before handing them to the parser,
      # matching validate_position_range in the C extension (main.c). A reversed
      # range would otherwise make the lexer loop forever inside WebAssembly.
      def validate_position_range(start_pos, end_pos)
        if start_pos < 0 || end_pos < 0
          raise ArgumentError, "negative position range: #{start_pos}...#{end_pos}"
        end
        if start_pos > end_pos
          raise ArgumentError, "invalid position range: #{start_pos}...#{end_pos}"
        end
      end

      # Reject anything that is not nil or an Array of Symbols, matching
      # declare_type_variables in the C extension (main.c).
      def validate_variables(variables)
        return if variables.nil?

        unless variables.is_a?(Array)
          raise TypeError, "wrong argument type #{variables.class} (must be an Array of Symbols or nil)"
        end

        variables.each do |variable|
          unless variable.is_a?(Symbol)
            raise TypeError, "Type variables Array contains invalid value #{variable.inspect} of type #{variable.class} (must be an Array of Symbols or nil)"
          end
        end
      end

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

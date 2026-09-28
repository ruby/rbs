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
      def _parse_signature(buffer, start_pos, end_pos, enable_forwarding_params)
        validate_position_range(buffer, start_pos, end_pos)
        validate_parser_options(enable_forwarding_params)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_signature(buffer.content, encoding, start_pos, end_pos)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        WASM::Deserializer.deserialize(bytes, buffer)
      end

      def _parse_type(buffer, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        validate_position_range(buffer, start_pos, end_pos)
        validate_variables(variables)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_type(buffer.content, encoding, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_method_type(buffer, start_pos, end_pos, variables, require_eof, enable_forwarding_params)
        validate_position_range(buffer, start_pos, end_pos)
        validate_variables(variables)
        validate_parser_options(enable_forwarding_params)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_method_type(buffer.content, encoding, start_pos, end_pos, variables, require_eof)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_type_params(buffer, start_pos, end_pos, module_type_params)
        validate_position_range(buffer, start_pos, end_pos)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_type_params(buffer.content, encoding, start_pos, end_pos, module_type_params)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        bytes.empty? ? nil : WASM::Deserializer.deserialize_node_list(bytes, buffer)
      end

      def _lex(buffer, end_pos)
        encoding = buffer.content.encoding.name
        _status, bytes = WASM::Runtime.instance.lex(buffer.content, encoding, end_pos)

        WASM::Deserializer.deserialize_tokens(bytes, buffer)
      end

      def _parse_inline_leading_annotation(buffer, start_pos, end_pos, variables)
        validate_position_range(buffer, start_pos, end_pos)
        validate_variables(variables)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_inline_leading_annotation(buffer.content, encoding, start_pos, end_pos, variables)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        deserialize_or_nil(bytes, buffer)
      end

      def _parse_inline_trailing_annotation(buffer, start_pos, end_pos, variables)
        validate_position_range(buffer, start_pos, end_pos)
        validate_variables(variables)
        encoding = buffer.content.encoding.name
        status, bytes = WASM::Runtime.instance.parse_inline_trailing_annotation(buffer.content, encoding, start_pos, end_pos, variables)
        raise_parse_failure(buffer, status, bytes, start_pos, end_pos) unless status == WASM::Runtime::OK

        deserialize_or_nil(bytes, buffer)
      end

      private

      # Reject the position ranges the parser cannot take, matching
      # validate_position_range in the C extension (main.c).
      #
      # `end_pos` past the end of the buffer is fine: clamping with a large
      # number instead of measuring the buffer is ordinary, and the lexer stops
      # at the end of the input on its own.
      def validate_position_range(buffer, start_pos, end_pos)
        if start_pos < 0 || end_pos < 0
          raise ArgumentError, "negative position range: #{start_pos}...#{end_pos}"
        end
        if start_pos > end_pos
          raise ArgumentError, "invalid position range: #{start_pos}...#{end_pos}"
        end

        size = buffer.content.bytesize
        if start_pos > size
          raise ArgumentError, "position range starts past the end of the buffer: #{start_pos}...#{end_pos}, buffer is #{size} bytes"
        end
      end

      # The WebAssembly entry points (rbs_wasm.c) build their parsers with the
      # default options, so the optional syntax the C extension can enable is
      # not reachable here. The public RBS::Parser API never enables it.
      def validate_parser_options(enable_forwarding_params)
        if enable_forwarding_params
          raise NotImplementedError, "forwarding parameter syntax is not supported by the WebAssembly parser"
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

      # Raise for a status other than OK (see rbs_wasm.c).
      #
      # A negative status is about the range rather than the source text, so it
      # comes with an empty result and an ArgumentError, as in the C extension
      # (main.c). Starting past the end of the buffer is plain from the
      # buffer's size and rejected above, so a start position that comes back
      # rejected can only be one inside a character.
      def raise_parse_failure(buffer, status, bytes, start_pos, end_pos)
        case status
        when WASM::Runtime::INVALID_START_POS
          raise ArgumentError, "position range starts inside a character: #{start_pos}...#{end_pos}"
        when WASM::Runtime::INVALID_RANGE
          raise ArgumentError, "invalid position range: #{start_pos}...#{end_pos}"
        else
          raise_parsing_error(buffer, bytes)
        end
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

# frozen_string_literal: true

require_relative "parser/lex_result"
require_relative "parser/token"

module RBS
  class Parser
    def self.parse_type(source, range: nil, byte_range: 0..., variables: [], require_eof: false, void_allowed: true, self_allowed: true, classish_allowed: true)
      buf = buffer(source)
      byte_range = byte_range(range, buf.content) if range
      _parse_type(buf, byte_range.begin || 0, byte_range.end || buf.content.bytesize, variables, require_eof, void_allowed, self_allowed, classish_allowed)
    end

    def self.parse_method_type(source, range: nil, byte_range: 0..., variables: [], require_eof: false)
      buf = buffer(source)
      byte_range = byte_range(range, buf.content) if range
      _parse_method_type(buf, byte_range.begin || 0, byte_range.end || buf.content.bytesize, variables, require_eof)
    end

    def self.parse_signature(source)
      buf = buffer(source)

      resolved = magic_comment(buf)
      start_pos =
        if resolved
          (resolved.location || raise).end_pos
        else
          0
        end
      content = buf.content
      dirs, decls = _parse_signature(buf, start_pos, content.bytesize)

      if resolved
        dirs = dirs.dup if dirs.frozen?
        dirs.unshift(resolved)
      end

      [buf, dirs, decls]
    end

    def self.parse_type_params(source, module_type_params: true)
      buf = buffer(source)
      _parse_type_params(buf, 0, buf.content.bytesize, module_type_params)
    end

    def self.magic_comment(buf)
      start_pos = 0

      while true
        case
        when match = /\A#\s*(?<keyword>resolve-type-names)\s*(?<colon>:)\s+(?<value>true|false)$/.match(buf.content, start_pos)
          value = match[:value] or raise

          kw_offset = match.offset(:keyword) #: [Integer, Integer]
          colon_offset = match.offset(:colon) #: [Integer, Integer]
          value_offset = match.offset(:value) #: [Integer, Integer]

          location = Location.new(buf, kw_offset[0], value_offset[1])
          location.add_required_child(:keyword, kw_offset[0]...kw_offset[1])
          location.add_required_child(:colon, colon_offset[0]...colon_offset[1])
          location.add_required_child(:value, value_offset[0]...value_offset[1])

          return AST::Directives::ResolveTypeNames.new(value: value == "true", location: location)
        else
          return
        end
      end
    end

    def self.lex(source)
      buf = buffer(source)
      list = _lex(buf, buf.content.bytesize)
      value = list.map do |type, location|
        Token.new(type: type, location: location)
      end
      LexResult.new(buffer: buf, value: value)
    end

    def self.buffer(source)
      case source
      when String
        Buffer.new(content: source, name: Pathname("a.rbs"))
      when Buffer
        source
      end
    end

    KEYWORDS = %w(
      bool
      bot
      class
      instance
      interface
      nil
      self
      singleton
      top
      void
      type
      unchecked
      in
      out
      end
      def
      include
      extend
      prepend
      alias
      module
      attr_reader
      attr_writer
      attr_accessor
      public
      private
      untyped
      true
      false
      ).each_with_object({}) do |keyword, hash| #$ Hash[String, bot]
        hash[keyword] = _ = nil
      end

    def self.parse_inline_leading_annotation(source, range, variables: [])
      buf = buffer(source)
      byte_range = byte_range(range, buf.content)
      _parse_inline_leading_annotation(buf, byte_range.begin || 0, byte_range.end || buf.content.bytesize, variables)
    end

    def self.parse_inline_trailing_annotation(source, range, variables: [])
      buf = buffer(source)
      byte_range = byte_range(range, buf.content)
      _parse_inline_trailing_annotation(buf, byte_range.begin || 0, byte_range.end || buf.content.bytesize, variables)
    end

    def self.byte_range(char_range, content)
      start_offset = char_range.begin
      end_offset = char_range.end

      start_prefix = content[0, start_offset] or raise if start_offset
      end_prefix = content[0, end_offset] or raise if end_offset

      start_prefix&.bytesize...end_prefix&.bytesize
    end
  end
end

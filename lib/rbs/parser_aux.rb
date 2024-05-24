# frozen_string_literal: true

module RBS
  class Parser
    def self.parse_type(source, range: 0..., variables: [], require_eof: false)
      buf = buffer(source)
      _parse_type(buf, range.begin || 0, range.end || buf.last_position, variables, require_eof)
    end

    def self.parse_method_type(source, range: 0..., variables: [], require_eof: false)
      buf = buffer(source)
      _parse_method_type(buf, range.begin || 0, range.end || buf.last_position, variables, require_eof)
    end

    def self.parse_signature(source)
      buf = buffer(source)
      dirs, decls = _parse_signature(buf, buf.last_position)

      [buf, dirs, decls]
    end

    class LexResult
      attr_reader :buffer
      attr_reader :value

      def initialize(buffer:, value:)
        @buffer = buffer
        @value = value
      end
    end

    class Token
      attr_reader :type
      attr_reader :location

      def initialize(type:, location:)
        @type = type
        @location = location
      end

      def value
        @location.source
      end

      def comment?
        @type == :tCOMMENT || @type == :tLINECOMMENT
      end
    end

    def self.lex(source)
      buf = buffer(source)
      value = _lex(buf, buf.last_position)
      value.map! do |type, location|
        Token.new(type: type, location: location)
      end
      LexResult.new(buffer: buf, value: value)
    end

    def self.buffer(source)
      case source
      when String
        Buffer.new(content: source, name: "a.rbs")
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
      ).each_with_object({}) do |keyword, hash|
        hash[keyword] = nil
      end
  end
end

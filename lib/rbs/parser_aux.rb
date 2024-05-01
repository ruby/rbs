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

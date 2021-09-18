module RBS
  class Parser
    def self.parse_type(source, line: 1, column: 0, variables: [])
      _parse_type(buffer(source), line, column, variables)
    end

    def self.parse_method_type(source, line: 1, column: 0, variables: [])
      _parse_method_type(buffer(source), line, column, variables)
    end

    def self.parse_signature(source, line: 1, column: 0)
      _parse_signature(buffer(source), line, column)
    end

    def self.buffer(source)
      case source
      when String
        Buffer.new(content: source, name: "a.rbs")
      when Buffer
        source
      end
    end

    SyntaxError = ParsingError
    SemanticsError = ParsingError
    LexerError = ParsingError

    class LocatedValue
    end

    KEYWORDS = Set.new(
      %w(
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
      )
    )
  end
end

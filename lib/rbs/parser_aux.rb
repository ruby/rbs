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
  end
end

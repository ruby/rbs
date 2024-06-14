# frozen_string_literal: true

module RBS
  module AST
    class Comment
      attr_reader :location

      def initialize(string:, location:, start_line: nil, end_line: nil)
        @string_base = string
        @start_line = start_line
        @end_line = end_line
        @location = location
      end

      def string
        @string ||= begin
          if (start_line = @start_line) && (end_line = @end_line)
            lines = @string_base.lines[(start_line - 1)..(end_line - 1)] or raise
            lines.map { |line| line.sub(/^\s*#\s?/, '')}.join("\n")
          else
            @string_base
          end
        end
      end

      def ==(other)
        other.is_a?(Comment) && other.string == string
      end

      def string
        raise 'string called'
      end

      alias eql? ==

      def hash
        self.class.hash ^ string.hash
      end

      def to_json(state = _ = nil)
        { string: string, location: location }.to_json(state)
      end
    end
  end
end

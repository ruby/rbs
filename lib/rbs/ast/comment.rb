# frozen_string_literal: true

module RBS
  module AST
    class Comment
      attr_reader :location

      def initialize(string: nil, location:)
        @string = string
        @location = location
      end

      def string
        @string ||= string_from_location
      end

      def ==(other)
        other.is_a?(Comment) && other.string == string
      end

      alias eql? ==

      def hash
        self.class.hash ^ string.hash
      end

      def to_json(state = nil)
        { string: string, location: location }.to_json(state)
      end

      private

      def string_from_location
        loc = location or raise "Comment#string requires a location when no string is given"

        source = loc.buffer.top_buffer.content[loc.start_pos...loc.end_pos] or raise

        source.each_line.map do |line|
          line.lstrip.delete_prefix("#").delete_prefix(" ").sub(/\r?\n\z/, "") + "\n"
        end.join
      end
    end
  end
end

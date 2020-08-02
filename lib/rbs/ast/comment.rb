module RBS
  module AST
    class Comment
      attr_reader :string
      attr_reader :location

      def initialize(string:, location:)
        @string = string
        @location = location
      end

      def ==(other)
        other.is_a?(Comment) && other.string == string
      end

      alias eql? ==

      def hash
        self.class.hash ^ string.hash
      end

      def to_json(*a)
        { string: string, location: location }.to_json(*a)
      end

      def concat(string:, location:)  
        @string.concat string
        @location.concat location
        self
      end
    end
  end
end

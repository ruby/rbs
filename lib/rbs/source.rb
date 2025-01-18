module RBS
  module Source
    class RBS
      attr_reader :buffer
      attr_reader :directives
      attr_reader :declarations

      def initialize(buffer, directives, declarations)
        @buffer = buffer
        @directives = directives
        @declarations = declarations
      end
    end

    class Ruby
      attr_reader :buffer
      attr_reader :prism_result
      attr_reader :declarations

      def initialize(buffer, prism, declarations)
        @buffer = buffer
        @prism_result = prism
        @declarations = declarations
      end
    end
  end
end

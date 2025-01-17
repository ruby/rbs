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
  end
end

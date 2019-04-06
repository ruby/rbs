module Ruby
  module Signature
    class Environment
      attr_reader :buffers
      attr_reader :declarations

      def initialize
        @buffers = []
        @declarations = []
      end
    end
  end
end

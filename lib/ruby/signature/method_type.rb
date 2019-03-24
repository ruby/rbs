module Ruby
  module Signature
    class MethodType
      class Block
        attr_reader :type
        attr_reader :required

        def initialize(type:, required:)
          @type = type
          @required = required
        end

        def ==(other)
          other.is_a?(Block) &&
            other.type == type &&
            other.required == required
        end
      end

      attr_reader :type_params
      attr_reader :type
      attr_reader :block
      attr_reader :location

      def initialize(type_params:, type:, block:, location:)
        @type_params = type_params
        @type = type
        @block = block
        @location = location
      end

      def ==(other)
        other.is_a?(MethodType) &&
          other.type_params == type_params &&
          other.type == type &&
          other.block == block
      end
    end
  end
end

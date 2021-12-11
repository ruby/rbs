module RBS
  module AST
    class TypeParam
      attr_reader :name, :variance, :location

      def initialize(name:, variance:, location:)
        @name = name
        @variance = variance
        @location = location
        @unchecked = false
      end

      def unchecked!(value = true)
        @unchecked = value ? true : false
        self
      end

      def unchecked?
        @unchecked
      end

      def ==(other)
        other.is_a?(TypeParam) &&
          other.name == name &&
          other.variance == variance &&
          other.unchecked? == unchecked?
      end

      alias eql? ==

      def hash
        self.class.hash ^ name.hash ^ variance.hash ^ unchecked?.hash
      end

      def to_json(state = JSON::State.new)
        {
          name: name,
          variance: variance,
          unchecked: unchecked?,
          location: location
        }.to_json(state)
      end

      def rename(name)
        TypeParam.new(
          name: name,
          variance: variance,
          location: location
        ).unchecked!(unchecked?)
      end
    end
  end
end

module RBS
  module Test
    module Guaranteed
      IS_AP = ::Kernel.instance_method(:is_a?)
      private_constant :IS_AP

      def self.value_is_a?(value, kind)
        IS_AP.bind_call(value, kind)
      end

      module Inspect
        EQUAL = ::BasicObject.instance_method(:equal?)
        INSPECT = ::Kernel.instance_method(:inspect)
        private_constant :EQUAL, :INSPECT

        module_function def guaranteed_inspect(obj)
          obj.inspect
        rescue NoMethodError => err
          raise unless err.name == :inspect && EQUAL.bind_call(obj, err.receiver)
          GUARANTEED_INSPECT.bind_call(obj)
        end

        def inspect
          string = "<#{self.class.name}:"

          instance_variables.each_with_index do |variable, index|
            string.concat ', ' unless index.zero?
            string.concat "#{variable}: #{guaranteed_inspect(variable)}"
          end

          string.concat '>'
        end
      end
    end
  end
end

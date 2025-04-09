module RBS
  module AST
    module Ruby
      module Annotations
        class Base
          attr_reader :location, :prefix_location

          def initialize(location, prefix_location)
            @location = location
            @prefix_location = prefix_location
          end

          def buffer
            location.buffer
          end
        end

        class NodeTypeAssertion < Base
          attr_reader :type

          def initialize(location:, prefix_location:, type:)
            super(location, prefix_location)
            @type = type
          end

          def map_type_name
            self.class.new(
              location:, prefix_location:,
              type: type.map_type_name { yield _1 }
            ) #: self
          end
        end

        class ColonMethodTypeAnnotation < Base
          attr_reader :annotations, :method_type

          def initialize(location:, prefix_location:, annotations:, method_type:)
            super(location, prefix_location)
            @annotations = annotations
            @method_type = method_type
          end

          def map_type_name
            self.class.new(
              location:,
              prefix_location:,
              annotations: annotations,
              method_type: method_type.map_type {|type| type.map_type_name { yield _1 }}
            ) #: self
          end
        end

        class MethodTypesAnnotation < Base
          Overload = AST::Members::MethodDefinition::Overload

          attr_reader :overloads, :vertical_bar_locations

          def initialize(location:, prefix_location:, overloads:, vertical_bar_locations:)
            super(location, prefix_location)
            @overloads = overloads
            @vertical_bar_locations = vertical_bar_locations
          end

          def map_type_name(&block)
            ovs = overloads.map do |overload|
              Overload.new(
                method_type: overload.method_type.map_type {|type| type.map_type_name { yield _1 } },
                annotations: overload.annotations
              )
            end

            self.class.new(location:, prefix_location:, overloads: ovs, vertical_bar_locations:) #: self
          end
        end
      end
    end
  end
end

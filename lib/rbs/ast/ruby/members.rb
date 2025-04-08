# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Members
        class Base
          attr_reader :buffer

          def initialize(buffer)
            @buffer = buffer
          end

          include Helpers::LocationHelper
        end

        class DefMember < Base
          Overload = AST::Members::MethodDefinition::Overload

          attr_reader :name
          attr_reader :node

          def initialize(buffer, name, node)
            super(buffer)
            @name = name
            @node = node
          end

          def location
            rbs_location(node.location)
          end

          def overloads
            method_type = MethodType.new(
              type_params: [],
              type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
              block: nil,
              location: nil
            )

            [
              Overload.new(method_type: method_type, annotations: [])
            ]
          end

          def overloading?
            false
          end

          def annotations
            []
          end
        end
      end
    end
  end
end

module RBS
  module AST
    module Ruby
      module Members
        class Base
        end

        class Overload
          attr_reader :method_type

          def initialize(method_type)
            @method_type = method_type
          end
        end

        class DefMember < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def overloads
            [
              Overload.new(
                MethodType.new(
                  type_params: [],
                  type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                  block: nil,
                  location: nil
                )
              )
            ]
          end
        end

        class DefSingletonMember < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def overloads
            [
              Overload.new(
                MethodType.new(
                  type_params: [],
                  type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                  block: nil,
                  location: nil
                )
              )
            ]
          end
        end
      end
    end
  end
end

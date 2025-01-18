module RBS
  module AST
    module Ruby
      module Members
        class Base
        end

        class Overload
          attr_reader :method_type
          attr_reader :annotations

          def initialize(method_type, annotations)
            @method_type = method_type
            @annotations = annotations
          end
        end

        class DefMember < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def name
            node.name
          end

          def overloads
            [
              Overload.new(
                MethodType.new(
                  type_params: [],
                  type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                  block: nil,
                  location: nil
                ),
                []
              )
            ]
          end

          def annotations
            []
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
                ),
                []
              )
            ]
          end

          def name
            node.name
          end

          def self?
            node.receiver.is_a?(Prism::SelfNode)
          end

          def annotations
            []
          end
        end
      end
    end
  end
end

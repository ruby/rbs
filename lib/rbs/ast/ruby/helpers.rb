module RBS
  module AST
    module Ruby
      module Helpers
        module ConstantHelper
          module_function

          def constant_as_type_name(node)
            case node
            when Prism::ConstantPathNode, Prism::ConstantReadNode
              TypeName.parse(node.full_name)
            end
          end
        end
      end
    end
  end
end

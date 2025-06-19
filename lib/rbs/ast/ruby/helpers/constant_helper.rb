# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Helpers
        module ConstantHelper
          module_function

          def constant_as_type_name(node)
            case node
            when Prism::ConstantPathNode, Prism::ConstantReadNode
              begin
                TypeName.parse(node.full_name)
              rescue Prism::ConstantPathNode::DynamicPartsInConstantPathError
                nil
              end
            end
          end
        end
      end
    end
  end
end

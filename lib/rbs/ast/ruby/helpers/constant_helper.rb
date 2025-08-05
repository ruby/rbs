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
            when Prism::ConstantWriteNode
              TypeName.new(name: node.name, namespace: Namespace.empty)
            when Prism::ConstantPathWriteNode
              constant_as_type_name(node.target)
            end
          end
        end
      end
    end
  end
end

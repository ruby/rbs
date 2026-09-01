# frozen_string_literal: true

module RBS
  module Prototype
    class NodeUsage
      include Helpers

      attr_reader :conditional_nodes

      def initialize(node)
        @node = node
        @conditional_nodes = Set[].compare_by_identity

        calculate(node, conditional: false)
      end

      def each_conditional_node(&block)
        if block
          conditional_nodes.each(&block)
        else
          conditional_nodes.each
        end
      end

      def calculate(node, conditional:)
        if conditional
          conditional_nodes << node
        end

        case node
        in Prism::IfNode
          calculate(node.predicate, conditional: true)
          calculate(node.statements, conditional: conditional) if node.statements
          calculate(node.subsequent, conditional: conditional) if node.subsequent
        in Prism::UnlessNode
          calculate(node.predicate, conditional: true)
          calculate(node.statements, conditional: conditional) if node.statements
          calculate(node.else_clause, conditional: conditional) if node.else_clause
        in Prism::AndNode | Prism::OrNode
          calculate(node.left, conditional: true)
          calculate(node.right, conditional: conditional)
        in Prism::CallNode if node.safe_navigation?
          calculate(node.receiver, conditional: true) if node.receiver
          calculate(node.arguments, conditional: false) if node.arguments
        in Prism::WhileNode
          calculate(node.predicate, conditional: true)
          calculate(node.statements, conditional: false) if node.statements
        in Prism::ConstantOrWriteNode | Prism::ConstantAndWriteNode |
             Prism::GlobalVariableOrWriteNode | Prism::GlobalVariableAndWriteNode |
             Prism::InstanceVariableOrWriteNode | Prism::InstanceVariableAndWriteNode |
             Prism::LocalVariableOrWriteNode | Prism::LocalVariableAndWriteNode
          conditional_nodes << node
          calculate(node.value, conditional: conditional)
        in Prism::ConstantWriteNode | Prism::MultiWriteNode |
           Prism::LocalVariableWriteNode | Prism::InstanceVariableWriteNode | Prism::GlobalVariableWriteNode
          calculate(node.value, conditional: conditional)
        in Prism::ConstantPathWriteNode
          calculate(node.target, conditional: false)
          calculate(node.value, conditional: conditional)
        in Prism::BlockNode | Prism::ClassNode | Prism::DefNode | Prism::LambdaNode | Prism::ModuleNode | Prism::SingletonClassNode
          # Anything with locals
          calculate(node.body, conditional: conditional) if node.body
        in Prism::CaseNode[predicate: predicate] unless predicate
          node.conditions.each do |when_node|
            when_node.conditions.each do |child|
              calculate(child, conditional: true)
            end
            calculate(when_node.statements, conditional: conditional) if when_node.statements
          end
        in Prism::StatementsNode
          *nodes, last = node.body
          nodes.each do |no|
            calculate(no, conditional: false)
          end
          calculate(last, conditional: conditional) if last
        else
          node.compact_child_nodes.each do |child|
            calculate(child, conditional: false)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module RBS
  class InlineParser
    class Result
      attr_reader :buffer, :prism_result, :declarations, :diagnostics

      def initialize(buffer, prism)
        @buffer = buffer
        @prism_result = prism
        @declarations = []
        @diagnostics = []
      end
    end

    module Diagnostic
      class Base
        attr_reader :message, :location

        def initialize(location, message)
          @location = location
          @message = message
        end
      end

      NonConstantClassName = _ = Class.new(Base)
      NonConstantModuleName = _ = Class.new(Base)
    end

    def self.parse(buffer, prism)
      result = Result.new(buffer, prism)

      Parser.new(result).visit(prism.value)

      result
    end

    class Parser < Prism::Visitor
      attr_reader :module_nesting, :result

      include AST::Ruby::Helpers::ConstantHelper
      include AST::Ruby::Helpers::LocationHelper

      def initialize(result)
        @result = result
        @module_nesting = []
      end

      def buffer
        result.buffer
      end

      def current_module
        module_nesting.last
      end

      def current_module!
        current_module || raise("#current_module is nil")
      end

      def diagnostics
        result.diagnostics
      end

      def push_module_nesting(mod)
        module_nesting.push(mod)
        yield
      ensure
        module_nesting.pop()
      end

      def visit_class_node(node)
        unless class_name = constant_as_type_name(node.constant_path)
          diagnostics << Diagnostic::NonConstantClassName.new(
            rbs_location(node.constant_path.location),
            "Class name must be a constant"
          )
          return
        end

        class_decl = AST::Ruby::Declarations::ClassDecl.new(buffer, class_name, node)
        insert_declaration(class_decl)
        push_module_nesting(class_decl) do
          visit_child_nodes(node)
        end
      end

      def visit_module_node(node)
        unless module_name = constant_as_type_name(node.constant_path)
          diagnostics << Diagnostic::NonConstantModuleName.new(
            rbs_location(node.constant_path.location),
            "Module name must be a constant"
          )
          return
        end

        module_decl = AST::Ruby::Declarations::ModuleDecl.new(buffer, module_name, node)
        insert_declaration(module_decl)
        push_module_nesting(module_decl) do
          visit_child_nodes(node)
        end
      end

      def insert_declaration(decl)
        if current_module
          current_module.members << decl
        else
          result.declarations << decl
        end
      end
    end
  end
end

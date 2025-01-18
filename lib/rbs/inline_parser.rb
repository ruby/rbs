# frozen_string_literal: true

module RBS
  class InlineParser
    class Result
      attr_reader :buffer
      attr_reader :prism_result
      attr_reader :declarations

      def initialize(buffer, result)
        @buffer = buffer
        @prism_result = result

        @declarations = []
      end
    end

    def self.parse(buffer, prism)
      result = Result.new(buffer, prism)

      parser = Parser.new(result)
      parser.parse()

      result
    end

    class Parser < Prism::Visitor
      attr_reader :result
      attr_reader :decl_contexts

      def buffer
        result.buffer
      end

      def current_context
        decl_contexts.last
      end

      def current_context!
        current_context or raise "No context"
      end

      def initialize(result)
        @result = result
        @decl_contexts = []
      end

      def parse()
        decl_contexts.clear
        visit(result.prism_result.value)
      end

      def push_decl_context(context)
        decl_contexts.push(context)
        yield
      ensure
        decl_contexts.pop
      end

      def insert_decl(decl)
        if current_context
          current_context.members << decl
        else
          result.declarations << decl
        end
      end

      def visit_class_node(node)
        decl = AST::Ruby::Declarations::ClassDecl.new(buffer, node)

        insert_decl(decl)
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_singleton_class_node(node)
        decl = AST::Ruby::Declarations::SingletonClassDecl.new(node)

        insert_decl(decl)
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_module_node(node)
        decl = AST::Ruby::Declarations::ModuleDecl.new(buffer, node)

        insert_decl(decl)
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_def_node(node)
        if node.receiver
          member = AST::Ruby::Members::DefSingletonMember.new(node)
        else
          member = AST::Ruby::Members::DefMember.new(node)
        end

        if current_context
          current_context.members << member
        end
      end

      def visit_constant_write_node(node)
        decl = AST::Ruby::Declarations::ConstantDecl.new(node)

        if current_context
          current_context.members << decl
        else
          result.declarations << decl
        end

        visit_child_nodes node
      end
    end
  end
end

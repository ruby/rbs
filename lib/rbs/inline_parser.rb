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

      NotImplementedYet = _ = Class.new(Base)
      NonConstantClassName = _ = Class.new(Base)
      NonConstantModuleName = _ = Class.new(Base)
      TopLevelMethodDefinition = _ = Class.new(Base)
      UnusedInlineAnnotation = _ = Class.new(Base)
      AnnotationSyntaxError = _ = Class.new(Base)
    end

    def self.parse(buffer, prism)
      result = Result.new(buffer, prism)

      Parser.new(result).visit(prism.value)

      result
    end

    class Parser < Prism::Visitor
      attr_reader :module_nesting, :result, :comments

      include AST::Ruby::Helpers::ConstantHelper
      include AST::Ruby::Helpers::LocationHelper

      def initialize(result)
        @result = result
        @module_nesting = []
        @comments = CommentAssociation.build(result.buffer, result.prism_result)
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

        comments.each_enclosed_block(node) do |block|
          report_unused_block(block)
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

        comments.each_enclosed_block(node) do |block|
          report_unused_block(block)
        end
      end

      def visit_def_node(node)
        if node.receiver
          diagnostics << Diagnostic::NotImplementedYet.new(
            rbs_location(node.receiver.location),
            "Singleton method definition is not supported yet"
          )
          return
        end

        case current = current_module
        when AST::Ruby::Declarations::ClassDecl, AST::Ruby::Declarations::ModuleDecl
          leading_block = comments.leading_block!(node)

          if node.end_keyword_loc
            # Not an end-less def
            end_loc = node.rparen_loc || node.parameters&.location || node.name_loc
            trailing_block = comments.trailing_block!(end_loc)
          end

          method_type, leading_unuseds, trailing_unused = AST::Ruby::Members::MethodTypeAnnotation.build(leading_block, trailing_block, [])
          report_unused_annotation(trailing_unused, *leading_unuseds)

          defn = AST::Ruby::Members::DefMember.new(buffer, node.name, node, method_type)
          current.members << defn

          # Skip other comments in `def` node
          comments.each_enclosed_block(node) do |block|
            comments.associated_blocks << block
          end
        else
          diagnostics << Diagnostic::TopLevelMethodDefinition.new(
            rbs_location(node.name_loc),
            "Top-level method definition is not supported"
          )
        end
      end

      def insert_declaration(decl)
        if current_module
          current_module.members << decl
        else
          result.declarations << decl
        end
      end

      def report_unused_annotation(*annotations)
        annotations.each do |annotation|
          case annotation
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            diagnostics << Diagnostic::AnnotationSyntaxError.new(
              annotation.location, "Syntax error: " + annotation.error.error_message
            )
          when AST::Ruby::Annotations::Base
            diagnostics << Diagnostic::UnusedInlineAnnotation.new(
              annotation.location, "Unused inline rbs annotation"
            )
          end
        end
      end

      def report_unused_block(block)
        block.each_paragraph([]) do |paragraph|
          case paragraph
          when Location
            # noop
          else
            report_unused_annotation(paragraph)
          end
        end
      end
    end
  end
end

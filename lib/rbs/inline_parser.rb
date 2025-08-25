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

      def type_fingerprint
        declarations.map(&:type_fingerprint)
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
      NonConstantSuperClassName = _ = Class.new(Base)
      TopLevelMethodDefinition = _ = Class.new(Base)
      TopLevelAttributeDefinition = _ = Class.new(Base)
      NonConstantConstantDeclaration = _ = Class.new(Base)
      UnusedInlineAnnotation = _ = Class.new(Base)
      AnnotationSyntaxError = _ = Class.new(Base)
      MixinMultipleArguments = _ = Class.new(Base)
      MixinNonConstantModule = _ = Class.new(Base)
      AttributeNonSymbolName = _ = Class.new(Base)
      ClassModuleAliasDeclarationMissingTypeName = _ = Class.new(Base)
    end

    def self.parse(buffer, prism)
      result = Result.new(buffer, prism)

      parser = Parser.new(result)
      parser.visit(prism.value)
      parser.comments.each_unassociated_block do |block|
        parser.report_unused_block(block)
      end

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

      def skip_node?(node)
        if ref = comments.leading_block(node)
          if ref.block.each_paragraph([]).any? { _1.is_a?(AST::Ruby::Annotations::SkipAnnotation) }
            ref.associate!
            return true
          end
        end

        false
      end

      def visit_class_node(node)
        return if skip_node?(node)

        unless class_name = constant_as_type_name(node.constant_path)
          diagnostics << Diagnostic::NonConstantClassName.new(
            rbs_location(node.constant_path.location),
            "Class name must be a constant"
          )
          return
        end

        # Parse super class if present
        super_class = if node.superclass
          node.inheritance_operator_loc or raise
          parse_super_class(node.superclass, node.inheritance_operator_loc)
        end

        class_decl = AST::Ruby::Declarations::ClassDecl.new(buffer, class_name, node, super_class)
        insert_declaration(class_decl)
        push_module_nesting(class_decl) do
          visit_child_nodes(node)

          node.child_nodes.each do |child_node|
            if child_node
              comments.each_enclosed_block(child_node) do |block|
                report_unused_block(block)
              end
            end
          end
        end

        comments.each_enclosed_block(node) do |block|
          unused_annotations = [] #: Array[AST::Ruby::CommentBlock::AnnotationSyntaxError | AST::Ruby::Annotations::leading_annotation]

          block.each_paragraph([]) do |paragraph|
            case paragraph
            when AST::Ruby::Annotations::InstanceVariableAnnotation
              class_decl.members << AST::Ruby::Members::InstanceVariableMember.new(buffer, paragraph)
            when Location
              # Skip
            when AST::Ruby::CommentBlock::AnnotationSyntaxError
              unused_annotations << paragraph
            else
              unused_annotations << paragraph
            end
          end

          report_unused_annotation(*unused_annotations)
        end

        class_decl.members.sort_by! { _1.location.start_line }
      end

      def visit_module_node(node)
        return if skip_node?(node)

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
        return if skip_node?(node)

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

          defn = AST::Ruby::Members::DefMember.new(buffer, node.name, node, method_type, leading_block)
          current.members << defn

          # Skip other comments in `def` node
          comments.each_enclosed_block(node) do |block|
            report_unused_block(block)
          end
        else
          diagnostics << Diagnostic::TopLevelMethodDefinition.new(
            rbs_location(node.name_loc),
            "Top-level method definition is not supported"
          )
        end
      end

      def visit_call_node(node)
        return unless node.receiver.nil? # Only handle top-level calls like include, extend, prepend, attr_*

        case node.name
        when :include, :extend, :prepend
          return if skip_node?(node)

          case current = current_module
          when AST::Ruby::Declarations::ClassDecl, AST::Ruby::Declarations::ModuleDecl
            parse_mixin_call(node)
          end
        when :attr_reader, :attr_writer, :attr_accessor
          return if skip_node?(node)

          case current = current_module
          when AST::Ruby::Declarations::ClassDecl, AST::Ruby::Declarations::ModuleDecl
            parse_attribute_call(node)
          when nil
            # Top-level attribute definition
            diagnostics << Diagnostic::TopLevelAttributeDefinition.new(
              rbs_location(node.message_loc || node.location),
              "Top-level attribute definition is not supported"
            )
          end
        else
          visit_child_nodes(node)
        end
      end

      def visit_constant_write_node(node)
        return if skip_node?(node)

        # Parse constant declaration (both top-level and in classes/modules)
        parse_constant_declaration(node)
      end

      def visit_constant_path_write_node(node)
        return if skip_node?(node)

        parse_constant_declaration(node)
      end

      def parse_mixin_call(node)
        # Check for multiple arguments
        if node.arguments && node.arguments.arguments.length > 1
          diagnostics << Diagnostic::MixinMultipleArguments.new(
            rbs_location(node.location),
            "Mixing multiple modules with one call is not supported"
          )
          return
        end

        # Check for missing arguments
        unless node.arguments && node.arguments.arguments.length == 1
          # This shouldn't happen in valid Ruby code, but handle it gracefully
          return
        end

        first_arg = node.arguments.arguments.first

        # Check if the argument is a constant
        unless module_name = constant_as_type_name(first_arg)
          diagnostics << Diagnostic::MixinNonConstantModule.new(
            rbs_location(first_arg.location),
            "Module name must be a constant"
          )
          return
        end

        # Look for type application annotation in trailing comments
        # For single-line calls like "include Bar #[String]", the annotation is trailing
        trailing_block = comments.trailing_block!(node.location)
        annotation = nil

        if trailing_block
          case trailing_annotation = trailing_block.trailing_annotation([])
          when AST::Ruby::Annotations::TypeApplicationAnnotation
            annotation = trailing_annotation
          else
            report_unused_annotation(trailing_annotation)
          end
        end

        # Create the appropriate member based on the method name
        member = case node.name
        when :include
          AST::Ruby::Members::IncludeMember.new(buffer, node, module_name, annotation)
        when :extend
          AST::Ruby::Members::ExtendMember.new(buffer, node, module_name, annotation)
        when :prepend
          AST::Ruby::Members::PrependMember.new(buffer, node, module_name, annotation)
        else
          raise "Unexpected mixin method: #{node.name}"
        end

        current_module!.members << member
      end

      def parse_attribute_call(node)
        # Get the name nodes (arguments to attr_*)
        unless node.arguments && !node.arguments.arguments.empty?
          return # No arguments, nothing to do
        end

        name_nodes = [] #: Array[Prism::SymbolNode]
        node.arguments.arguments.each do |arg|
          case arg
          when Prism::SymbolNode
            name_nodes << arg
          else
            # Non-symbol argument, report error
            diagnostics << Diagnostic::AttributeNonSymbolName.new(
              rbs_location(arg.location),
              "Attribute name must be a symbol"
            )
          end
        end

        return if name_nodes.empty?

        # Look for leading comment block
        leading_block = comments.leading_block!(node)

        # Look for trailing type annotation (#: Type)
        trailing_block = comments.trailing_block!(node.location)
        type_annotation = nil

        if trailing_block
          case annotation = trailing_block.trailing_annotation([])
          when AST::Ruby::Annotations::NodeTypeAssertion
            type_annotation = annotation
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            diagnostics << Diagnostic::AnnotationSyntaxError.new(
              annotation.location, "Syntax error: " + annotation.error.error_message
            )
          end
        end

        # Report unused leading annotations since @rbs annotations are not used for attributes
        if leading_block
          report_unused_block(leading_block)
        end

        # Create the appropriate member type
        member = case node.name
        when :attr_reader
          AST::Ruby::Members::AttrReaderMember.new(buffer, node, name_nodes, leading_block, type_annotation)
        when :attr_writer
          AST::Ruby::Members::AttrWriterMember.new(buffer, node, name_nodes, leading_block, type_annotation)
        when :attr_accessor
          AST::Ruby::Members::AttrAccessorMember.new(buffer, node, name_nodes, leading_block, type_annotation)
        else
          raise "Unexpected attribute method: #{node.name}"
        end

        current_module!.members << member
      end

      def parse_constant_declaration(node)
        # Create TypeName for the constant
        unless constant_name = constant_as_type_name(node)
          location =
            case node
            when Prism::ConstantWriteNode
              node.name_loc
            when Prism::ConstantPathWriteNode
              node.target.location
            end

          diagnostics << Diagnostic::NonConstantConstantDeclaration.new(
            rbs_location(location),
            "Constant name must be a constant"
          )
          return
        end

        # Look for leading comment block
        leading_block = comments.leading_block!(node)
        report_unused_block(leading_block) if leading_block

        # Look for trailing type annotation (#: Type)
        trailing_block = comments.trailing_block!(node.location)
        type_annotation = nil
        alias_annotation = nil

        if trailing_block
          case annotation = trailing_block.trailing_annotation([])
          when AST::Ruby::Annotations::NodeTypeAssertion
            type_annotation = annotation
          when AST::Ruby::Annotations::ClassAliasAnnotation, AST::Ruby::Annotations::ModuleAliasAnnotation
            alias_annotation = annotation
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            diagnostics << Diagnostic::AnnotationSyntaxError.new(
              annotation.location, "Syntax error: " + annotation.error.error_message
            )
          end
        end

        # Handle class/module alias declarations
        if alias_annotation
          # Try to infer the old name from the right-hand side
          infered_old_name = constant_as_type_name(node.value)

          # Check if we have either an explicit type name or can infer one
          if alias_annotation.type_name.nil? && infered_old_name.nil?
            message =
              if alias_annotation.is_a?(AST::Ruby::Annotations::ClassAliasAnnotation)
                "Class name is missing in class alias declaration"
              else
                "Module name is missing in module alias declaration"
              end

            diagnostics << Diagnostic::ClassModuleAliasDeclarationMissingTypeName.new(
              alias_annotation.location,
              message
            )
            return
          end

          # Create class/module alias declaration
          alias_decl = AST::Ruby::Declarations::ClassModuleAliasDecl.new(
            buffer,
            node,
            constant_name,
            infered_old_name,
            leading_block,
            alias_annotation
          )

          # Insert the alias declaration appropriately

          if current_module
            current_module.members << alias_decl
          else
            result.declarations << alias_decl
          end
        else
          # Create regular constant declaration
          constant_decl = AST::Ruby::Declarations::ConstantDecl.new(
            buffer,
            constant_name,
            node,
            leading_block,
            type_annotation
          )

          # Insert the constant declaration appropriately
          if current_module
            current_module.members << constant_decl
          else
            result.declarations << constant_decl
          end
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
        return unless block.leading?

        block.each_paragraph([]) do |paragraph|
          case paragraph
          when Location
            # noop
          else
            report_unused_annotation(paragraph)
          end
        end
      end

      def parse_super_class(super_class_expr, inheritance_operator_loc)
        # Check if the superclass is a constant
        unless super_class_name = constant_as_type_name(super_class_expr)
          diagnostics << Diagnostic::NonConstantSuperClassName.new(
            rbs_location(super_class_expr.location),
            "Super class name must be a constant"
          )
          return nil
        end

        # Look for type application annotation in trailing comments
        # For example: class StringArray < Array #[String]
        trailing_block = comments.trailing_block!(super_class_expr.location)
        type_annotation = nil

        if trailing_block
          case annotation = trailing_block.trailing_annotation([])
          when AST::Ruby::Annotations::TypeApplicationAnnotation
            type_annotation = annotation
          else
            report_unused_annotation(annotation)
          end
        end

        # Create SuperClass object
        AST::Ruby::Declarations::ClassDecl::SuperClass.new(
          rbs_location(super_class_expr.location),
          rbs_location(inheritance_operator_loc),
          super_class_name,
          type_annotation
        )
      end
    end
  end
end

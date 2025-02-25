# frozen_string_literal: true

module RBS
  class InlineParser
    class Result
      attr_reader :buffer
      attr_reader :prism_result
      attr_reader :declarations
      attr_reader :diagnostics

      def initialize(buffer, result)
        @buffer = buffer
        @prism_result = result

        @declarations = []
        @diagnostics = []
      end
    end

    module Diagnostics
      class Base
        attr_reader :location
        attr_reader :message

        def initialize(location, message)
          @location = location
          @message = message
        end
      end

      class NonConstantName < Base
      end

      class ToplevelSingletonClass < Base
      end

      class DeclarationInsideSingletonClass < Base
      end

      class NonConstantSuperClass < Base
      end

      class NonSelfSingletonClass < Base
      end

      class InvalidVisibilityCall < Base
      end

      class InvalidMixinCall < Base
      end

      class UnusedAnnotation < Base
      end

      class AnnotationSyntaxError < Base
      end

      class VariableAnnotationInSingletonClassError < Base
      end
    end

    def self.enabled?(result, default:)
      result.comments.each do |comment|
        if comment.location.start_character_column == 0
          if comment.location.slice == "# rbs_inline: enabled"
            return true
          end
          if comment.location.slice == "# rbs_inline: disabled"
            return false
          end
        end
      end

      return default
    end

    def self.parse(buffer, prism)
      result = Result.new(buffer, prism)
      association = Inline::CommentAssociation.build(buffer, prism)

      parser = Parser.new(result, association)
      parser.parse()

      result
    end

    class Parser < Prism::Visitor
      attr_reader :result
      attr_reader :decl_contexts
      attr_reader :comments

      def buffer
        result.buffer
      end

      def diagnostics
        result.diagnostics
      end

      def current_context
        decl_contexts.last
      end

      def current_context!
        current_context or raise "No context"
      end

      def initialize(result, comments)
        @result = result
        @comments = comments
        @decl_contexts = []
        @type_params_stack = []
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

      def insert_class_module_decl(decl)
        if current_context
          current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl) and raise
          current_context.members << decl
        else
          result.declarations << decl
        end
      end

      def visit_class_node(node)
        unless class_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(node.constant_path)
          diagnostics << Diagnostics::NonConstantName.new(
            buffer.rbs_location(node.constant_path.location),
            "Class name should be constant"
          )
          return
        end
        class_name_location = buffer.rbs_location(node.constant_path.location)

        if current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl)
          diagnostics << Diagnostics::DeclarationInsideSingletonClass.new(
            buffer.rbs_location(node.constant_path.location),
            "Class definition inside singleton class definition is ignored"
          )
          return
        end

        leading_block = comments.leading_block(node)
        leading_comments = [] #: Array[AST::Ruby::Annotation::leading_annotation]
        leading_block&.each_paragraph([]) do |paragraph|
          case paragraph
          when Location
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            report_annotation_syntax_error(paragraph)
          else
            leading_comments << paragraph
          end
        end

        generics, leading_comments = AST::Ruby::Declarations::GenericsTypeParams.build(leading_comments)
        super_annotation, leading_comments = AST::Ruby::Declarations::ClassDecl::SuperAnnotation.build(leading_comments)

        push_type_params(generics.type_params) do
          if super_node_ = node.superclass
            trailing_block = comments.trailing_block(super_node_)

            visit super_node_

            if super_class_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(super_node_)
              super_class_name_location = buffer.rbs_location(super_node_.location)

              open_paren_location = nil #: Location?
              type_args = [] #: Array[Types::t]
              close_paren_location = nil #: Location?

              if trailing_block
                if (app = trailing_block.trailing_annotation([])).is_a?(AST::Ruby::Annotation::NodeApplication)
                  open_paren_location = app.prefix_location
                  type_args = app.types
                  close_paren_location = app.suffix_location
                end
              end

              super_node = AST::Ruby::Declarations::ClassDecl::SuperNode.new(
                class_name: super_class_name,
                class_name_location: super_class_name_location,
                location: class_name_location,
                type_args: type_args,
                open_paren_location: open_paren_location,
                close_paren_location: close_paren_location
              )
            else
              unless super_annotation
                diagnostics << Diagnostics::NonConstantSuperClass.new(
                  buffer.rbs_location(super_node_.location),
                  "Super class of #{class_name} should be constant"
                )
              end
            end
          end

          if leading_block
            leading_comments.each do |annotation|
              report_unused_annotation(annotation)
            end
          end

          decl = AST::Ruby::Declarations::ClassDecl.new(
            buffer,
            node,
            class_name: class_name,
            location: buffer.rbs_location(node.location),
            class_name_location: class_name_location,
            generics: generics,
            super_node: super_node,
            super_annotation: super_annotation
          )

          insert_class_module_decl(decl)
          push_decl_context(decl) do
            visit node.body
          end

          comments.each_enclosed_block(node) do |block|
            block.each_paragraph(current_type_param_names) do |paragraph|
              case paragraph
              when Location
                # skip
              when AST::Ruby::CommentBlock::AnnotationSyntaxError
                report_annotation_syntax_error(paragraph)
              when AST::Ruby::Annotation::IvarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::InstanceVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::ClassIvarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::ClassInstanceVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::ClassVarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::ClassVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::EmbeddedRBSAnnotation
                decl.members << AST::Ruby::Declarations::EmbeddedRBSDecl.new(
                  buffer,
                  paragraph.location.absolute_location,
                  paragraph.members
                )
              else
                report_unused_annotation(paragraph)
              end
            end
          end

          decl.members.sort_by! { _1.location.absolute_location.start_line }
        end
      end

      def visit_singleton_class_node(node)
        unless node.expression.is_a?(Prism::SelfNode)
          diagnostics << Diagnostics::NonSelfSingletonClass.new(
            buffer.rbs_location(node.expression.location),
            "Singleton class should be defined with `self` is ignored"
          )
          return
        end
        unless current_context
          diagnostics << Diagnostics::ToplevelSingletonClass.new(
            buffer.rbs_location(node.operator_loc, node.expression.location),
            "Toplevel singleton class definition is ignored"
          )
          return
        end
        if current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl)
          diagnostics << Diagnostics::DeclarationInsideSingletonClass.new(
            buffer.rbs_location(node.operator_loc, node.expression.location),
            "Singleton class definition inside another singleton class definition is ignored"
          )
          return
        end

        decl = AST::Ruby::Declarations::SingletonClassDecl.new(buffer, node)

        push_type_params([]) do
          current_context.members << decl
          push_decl_context(decl) do
            visit node.body
          end

          comments.each_enclosed_block(node) do |block|
            block.each_paragraph(current_type_param_names) do |paragraph|
              case paragraph
              when Location
                # skip
              when AST::Ruby::CommentBlock::AnnotationSyntaxError
                report_annotation_syntax_error(paragraph)
              when AST::Ruby::Annotation::IvarTypeAnnotation, AST::Ruby::Annotation::ClassIvarTypeAnnotation, AST::Ruby::Annotation::ClassVarTypeAnnotation
                diagnostics << Diagnostics::VariableAnnotationInSingletonClassError.new(
                  paragraph.location,
                  "Variable type definition cannot be included in singleton class definition",
                )
              else
                report_unused_annotation(paragraph)
              end
            end
          end
        end
      end

      def visit_module_node(node)
        unless module_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(node.constant_path)
          diagnostics << Diagnostics::NonConstantName.new(
            buffer.rbs_location(node.constant_path.location),
            "Module name should be constant"
          )
          return
        end
        module_name_location = buffer.rbs_location(node.constant_path.location)

        if current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl)
          diagnostics << Diagnostics::DeclarationInsideSingletonClass.new(
            module_name_location,
            "Module definition inside singleton class definition is ignored"
          )
          return
        end

        leading_block = comments.leading_block(node)
        leading_comments = [] #: Array[AST::Ruby::Annotation::leading_annotation]
        leading_block&.each_paragraph([]) do |paragraph|
          case paragraph
          when Location
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            report_annotation_syntax_error(paragraph)
          else
            leading_comments << paragraph
          end
        end

        generics, leading_comments = AST::Ruby::Declarations::GenericsTypeParams.build(leading_comments)
        push_type_params(generics.type_params) do
          self_constraints, leading_comments = AST::Ruby::Declarations::ModuleDecl::SelfConstraint.build(leading_comments)

          if leading_block
            leading_comments.each do |comment|
              report_unused_annotation(comment)
            end
          end

          decl = AST::Ruby::Declarations::ModuleDecl.new(
            buffer,
            node,
            location: buffer.rbs_location(node.location),
            module_name: module_name,
            module_name_location: module_name_location,
            generics: generics,
            self_constraints: self_constraints
          )

          insert_class_module_decl(decl)
          push_decl_context(decl) do
            visit node.body
          end

          comments.each_enclosed_block(node) do |block|
            block.each_paragraph(current_type_param_names) do |paragraph|
              case paragraph
              when Location
                # skip
              when AST::Ruby::CommentBlock::AnnotationSyntaxError
                report_annotation_syntax_error(paragraph)
              when AST::Ruby::Annotation::IvarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::InstanceVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::ClassIvarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::ClassInstanceVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::ClassVarTypeAnnotation
                name = paragraph.var_name_location.source.to_sym
                type = paragraph.type
                decl.members << AST::Ruby::Members::ClassVariableMember.new(buffer, name, type, paragraph)
              when AST::Ruby::Annotation::EmbeddedRBSAnnotation
                decl.members << AST::Ruby::Declarations::EmbeddedRBSDecl.new(
                  buffer,
                  paragraph.location.absolute_location,
                  paragraph.members
                )
              else
                report_unused_annotation(paragraph)
              end
            end
          end

          decl.members.sort_by! { _1.location.absolute_location.start_line }
        end
      end

      def visit_def_node(node)
        leading_block = comments.leading_block(node)
        trailing_block = comments.trailing_block(node.parameters ? node.parameters.location : node.name_loc)
        annotations, unused_annots, unused_trailing_annot = AST::Ruby::Members::DefAnnotations.build(leading_block, trailing_block, current_type_param_names)

        pairs = [] #: Array[[AST::Ruby::CommentBlock, AST::Ruby::Annotation::t | AST::Ruby::CommentBlock::AnnotationSyntaxError]]
        if leading_block
          pairs.concat unused_annots.map { [leading_block, _1] }
        end
        if trailing_block && unused_trailing_annot
          pairs << [trailing_block, unused_trailing_annot]
        end

        pairs.each do |block, annot|
          case annot
          when AST::Ruby::CommentBlock::AnnotationSyntaxError
            report_annotation_syntax_error(annot)
          else
            report_unused_annotation(annot)
          end
        end

        if node.receiver
          member = AST::Ruby::Members::DefSingletonMember.new(buffer, node)
          return unless member.self?
        else
          member = AST::Ruby::Members::DefMember.new(buffer, node, name: node.name, inline_annotations: annotations)
        end

        if current_context
          current_context.members << member
        end
      end

      def visit_constant_write_node(node)
        decl = AST::Ruby::Declarations::ConstantDecl.new(buffer, node)

        if current_context
          unless current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl)
            current_context.members << decl
          end
        else
          result.declarations << decl
        end

        visit_child_nodes node
      end

      def visit_call_node(node)
        member =
          visibility_member?(node) ||
            mixin_member?(node) ||
            nil

        if member
          current_context!.members << member
        end
      end

      def visibility_member?(node)
        if node.name == :private || node.name == :public
          unless current_context
            diagnostics << Diagnostics::InvalidVisibilityCall.new(
              buffer.rbs_location(node.message_loc || raise),
              "`#{node.name}` call outside of class/module definition is ignored"
            )
            return
          end
          unless self_call?(node)
            receiver = node.receiver or raise
            diagnostics << Diagnostics::InvalidVisibilityCall.new(
              buffer.rbs_location(receiver.location),
              "`#{node.name}` call with non-self receiver is ignored"
            )
            return
          end

          if no_argument?(node)
            if node.name == :private
              AST::Ruby::Members::PrivateMember.new(buffer, node)
            else
              AST::Ruby::Members::PublicMember.new(buffer, node)
            end
          else
            args = node.arguments or raise
            diagnostics << Diagnostics::InvalidVisibilityCall.new(
              buffer.rbs_location(args.location),
              "`#{node.name}` call with arguments is ignored"
            )
            nil
          end
        end
      end

      def pop_type_params
        @type_params_stack.pop
      end

      def push_type_params(params, &block)
        @type_params_stack.push(params)

        if block
          begin
            yield
          ensure
            pop_type_params
          end
        end
      end

      def current_type_params
        @type_params_stack.last || []
      end

      def current_type_param_names
        current_type_params.map(&:name)
      end

      def current_type_param_names
        if context = current_context
          case context
          when AST::Ruby::Declarations::ClassDecl, AST::Ruby::Declarations::ModuleDecl
            context.type_params.map(&:name)
          else
            []
          end
        else
          []
        end
      end

      def mixin_member?(node)
        block = comments.trailing_block(node.location)

        case node.name
        when :include, :prepend, :extend
          unless current_context
            diagnostics << Diagnostics::InvalidMixinCall.new(
              buffer.rbs_location(node.message_loc || raise),
              "`#{node.name}` call outside of class/module definition is ignored"
            )
            return
          end
          unless self_call?(node)
            receiver = node.receiver or raise
            diagnostics << Diagnostics::InvalidMixinCall.new(
              buffer.rbs_location(receiver.location),
              "`#{node.name}` call with non-self receiver is ignored"
            )
            return
          end

          if arg = one_argument?(node)
            if const_node = constant_node?(arg)
              module_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(const_node) or return
              location = buffer.rbs_location(node.location)
              module_name_location = buffer.rbs_location(const_node.location)
              open_paren_location = nil #: Location?
              close_paren_location = nil #: Location?
              type_args = [] #: Array[Types::t]

              if block
                if (application = block.trailing_annotation([])).is_a?(AST::Ruby::Annotation::NodeApplication)
                  open_paren_location = application.prefix_location
                  close_paren_location = application.suffix_location
                  type_args = application.types
                end
              end

              case node.name
              when :include
                AST::Ruby::Members::IncludeMember.new(
                  buffer,
                  node,
                  location: location,
                  module_name: module_name,
                  module_name_location: module_name_location,
                  type_args: type_args,
                  open_paren_location: open_paren_location,
                  close_paren_location: close_paren_location
                )
              when :prepend
                AST::Ruby::Members::PrependMember.new(
                  buffer,
                  node,
                  location: location,
                  module_name: module_name,
                  module_name_location: module_name_location,
                  type_args: type_args,
                  open_paren_location: open_paren_location,
                  close_paren_location: close_paren_location
                )
              when :extend
                AST::Ruby::Members::ExtendMember.new(
                  buffer,
                  node,
                  location: location,
                  module_name: module_name,
                  module_name_location: module_name_location,
                  type_args: type_args,
                  open_paren_location: open_paren_location,
                  close_paren_location: close_paren_location
                )
              end
            else
              diagnostics << Diagnostics::InvalidMixinCall.new(
                buffer.rbs_location(arg.location),
                "`#{node.name}` call with non-constant argument is ignored"
              )
              nil
            end
          else
            diagnostics << Diagnostics::InvalidMixinCall.new(
              buffer.rbs_location(node.arguments&.location || node.location),
              "`#{node.name}` call without argument/with more than one arguments is ignored"
            )
            nil
          end
        end
      end

      def constant_node?(node)
        case node
        when Prism::ConstantReadNode
          node
        when Prism::ConstantPathNode
          if node.parent
            if constant_node?(node.parent)
              node
            end
          else
            node
          end
        end
      end

      def no_argument?(node)
        return true unless node.arguments

        return false if node.arguments.contains_forwarding?
        return false if node.arguments.contains_keywords?
        return false if node.arguments.contains_keyword_splat?
        return false if node.arguments.contains_splat?
        return false if node.arguments.contains_multiple_splats?
        return false if node.block

        return node.arguments.arguments.size == 0
      end

      def one_argument?(node)
        return unless node.arguments

        return if node.arguments.contains_forwarding?
        return if node.arguments.contains_keywords?
        return if node.arguments.contains_keyword_splat?
        return if node.arguments.contains_splat?
        return if node.arguments.contains_multiple_splats?
        return if node.block

        if node.arguments.arguments.size == 1
          node.arguments.arguments[0]
        end
      end

      def self_call?(node)
        !node.receiver || node.receiver.is_a?(Prism::SelfNode)
      end

      def report_annotation_syntax_error(error)
        diagnostics << Diagnostics::AnnotationSyntaxError.new(error.location, "Annotation syntax error: #{error.error.message}")
      end

      def report_unused_annotation(annot)
        diagnostics << Diagnostics::UnusedAnnotation.new(annot.location, "Unused annotation")
      end
    end
  end
end

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
          visit node.body
          return
        end
        class_name_location = buffer.rbs_location(node.constant_path.location)

        if super_node = node.superclass
          visit super_node

          if super_class_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(super_node)
            super_class_name_location = buffer.rbs_location(super_node.location)
            super_class = AST::Ruby::Declarations::ClassDecl::Super.new(
              class_name: super_class_name,
              class_name_location: super_class_name_location,
              location: class_name_location,
              type_args: [],
              open_paren_location: nil,
              close_paren_location: nil,
              args_separator_locations: []
            )
          end
        end


        decl = AST::Ruby::Declarations::ClassDecl.new(
          buffer,
          node,
          class_name: class_name,
          location: buffer.rbs_location(node.location),
          class_name_location: class_name_location,
          super_class: super_class
        )

        insert_class_module_decl(decl)
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_singleton_class_node(node)
        return unless node.expression.is_a?(Prism::SelfNode)
        return unless current_context
        return if current_context.is_a?(AST::Ruby::Declarations::SingletonClassDecl)

        decl = AST::Ruby::Declarations::SingletonClassDecl.new(node)

        current_context.members << decl
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_module_node(node)
        unless module_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(node.constant_path)
          visit node.body
          return
        end
        module_name_location = buffer.rbs_location(node.constant_path.location)

        decl = AST::Ruby::Declarations::ModuleDecl.new(
          buffer,
          node,
          location: buffer.rbs_location(node.location),
          module_name: module_name,
          module_name_location: module_name_location
        )

        insert_class_module_decl(decl)
        push_decl_context(decl) do
          visit node.body
        end
      end

      def visit_def_node(node)
        if node.receiver
          member = AST::Ruby::Members::DefSingletonMember.new(node)
          return unless member.self?
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
          private_member?(node) || public_member?(node) ||
            mixin_member?(node) ||
            nil

        if member
          current_context!.members << member
        end
      end

      def private_member?(node)
        return unless current_context
        return unless self_call?(node)

        if node.name == :private
          if no_argument?(node)
            AST::Ruby::Members::PrivateMember.new(buffer, node)
          end
        end
      end

      def public_member?(node)
        return unless current_context
        return unless self_call?(node)

        if node.name == :public
          if no_argument?(node)
            AST::Ruby::Members::PublicMember.new(buffer, node)
          end
        end
      end

      def mixin_member?(node)
        return unless current_context
        return unless self_call?(node)

        case node.name
        when :include, :prepend, :extend
          if arg = one_argument?(node)
            if const_node = constant_node?(arg)
              module_name = AST::Ruby::Helpers::ConstantHelper.constant_as_type_name(const_node) or return
              location = buffer.rbs_location(node.location)
              module_name_location = buffer.rbs_location(const_node.location)
              open_paren_location = nil
              close_paren_location = nil
              type_args = []
              args_separator_locations = []

              case node.name
              when :include
                AST::Ruby::Members::IncludeMember.new(
                  buffer,
                  node,
                  location: location,
                  module_name: module_name,
                  module_name_location: module_name_location,
                  type_args: type_args,
                  args_separator_locations: args_separator_locations,
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
                  args_separator_locations: args_separator_locations,
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
                  args_separator_locations: args_separator_locations,
                  open_paren_location: open_paren_location,
                  close_paren_location: close_paren_location
                )
              end
            end
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
    end
  end
end

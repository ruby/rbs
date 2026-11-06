# frozen_string_literal: true

module RBS
  module Prototype
    class RBI
      extend Helpers

      def self.parse(string)
        parse_result = Prism.parse(string, version: "current")
        raise SyntaxError unless parse_result.success?

        comments = process_comments(parse_result.comments, include_trailing: true)
        visitor = Visitor.new(comments)
        visitor.visit(parse_result.value)
        visitor.decls
      end

      class Context
        attr_accessor :singleton
        attr_accessor :visibility

        def initialize(singleton:, visibility:)
          @singleton = singleton
          @visibility = visibility
        end
      end

      class Visitor < Prism::Visitor
        attr_reader :decls
        attr_reader :modules
        attr_reader :last_sig

        def initialize(comments)
          @comments = comments

          @decls = []
          @modules = []
          @contexts = []
          @emitted_visibility = {}
        end

        def visit_class_node(node)
          comment = @comments[node.start_line - 1]
          push_class node.constant_path, node.superclass, comment: comment do
            visit(node.body)
          end
        end

        def visit_module_node(node)
          comment = @comments[node.start_line - 1]
          push_module node.constant_path, comment: comment do
            visit(node.body)
          end
        end

        def visit_singleton_class_node(node)
          if node.expression.is_a?(Prism::SelfNode)
            @contexts << Context.new(singleton: true, visibility: :public)
            begin
              visit(node.body)
            ensure
              @contexts.pop
            end
          end
        end

        def visit_call_node(node)
          return if node.receiver
          arguments = node.arguments&.arguments || []

          if node.variable_call?
            case node.name
            when :private, :protected, :public
              current_context!.visibility = node.name
            end
            return
          end

          case node.name
          when :include
            arguments.each do |arg|
              if arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
                name = const_to_name(arg)
                include_member = AST::Members::Include.new(
                  name: name,
                  args: [],
                  annotations: [],
                  location: nil,
                  comment: nil
                )
                current_module!.members << include_member
              end
            end
          when :extend
            arguments.each do |arg|
              if arg.is_a?(Prism::ConstantReadNode) || arg.is_a?(Prism::ConstantPathNode)
                name = const_to_name(arg)
                unless ["T::Generic", "T::Helpers", "T::Sig"].include?(name.to_s.delete_prefix("::"))
                  member = AST::Members::Extend.new(
                    name: name,
                    args: [],
                    annotations: [],
                    location: nil,
                    comment: nil
                  )
                  current_module!.members << member
                end
              end
            end
          when :sig
            case node.block
            in Prism::BlockNode[body: Prism::StatementsNode[body: [first, *]]]
              push_sig(first)
            else
              raise("malformed sig")
            end
          when :attr_reader, :attr_writer, :attr_accessor
            process_attribute node, node.name
          when :private, :protected, :public
            process_visibility node, node.name
          when :alias_method
            case arguments
            in [Prism::SymbolNode => new, Prism::SymbolNode => old]
              current_module!.members << AST::Members::Alias.new(
                new_name: new.value,
                old_name: old.value,
                location: nil,
                annotations: [],
                kind: current_context!.singleton ? :singleton : :instance,
                comment: nil
              )
            end
          end
        end

        def visit_alias_method_node(node)
          sync_visibility(current_context!.visibility)
          if node in { old_name: Prism::SymbolNode => old_name, new_name: Prism::SymbolNode => new_name }
            current_module!.members << AST::Members::Alias.new(
              new_name: new_name.value,
              old_name: old_name.value,
              location: nil,
              annotations: [],
              kind: current_context!.singleton ? :singleton : :instance,
              comment: nil
            )
          end
        end

        def visit_def_node(node)
          sigs = pop_sig
          return unless sigs

          comment = join_comments(sigs)
          if node.receiver
            types = sigs.map {|sig| method_type(node.parameters, sig, overloads: sigs.size) }.compact

            current_module!.members << AST::Members::MethodDefinition.new(
              name: node.name,
              location: nil,
              annotations: [],
              overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
              kind: :singleton,
              comment: comment,
              overloading: false,
              visibility: nil
            )
          else
            context = current_context!
            sync_visibility(context.visibility)

            types = sigs.map {|sig| method_type(node.parameters, sig, overloads: sigs.size) }.compact

            current_module!.members << AST::Members::MethodDefinition.new(
              name: node.name,
              location: nil,
              annotations: [],
              overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
              kind: context.singleton ? :singleton : :instance,
              comment: comment,
              overloading: false,
              visibility: member_visibility(context)
            )
          end
        end

        def visit_constant_write_node(node)
          if (send = node.value).is_a?(Prism::CallNode) && !send.receiver && send.name == :type_member
            arguments = send.arguments&.arguments || []
            not_fixed = arguments.none? do |node|
              node.is_a?(Prism::KeywordHashNode) &&
                node.elements.none? { |assoc| (assoc in Prism::AssocNode[key: Prism::SymbolNode => key]) && key.value == :fixed }
            end
            if not_fixed
              # @type var variance: AST::TypeParam::variance?
              if (first_arg = arguments.first).is_a?(Prism::SymbolNode)
                variance = case first_arg.value
                           when "out"
                             :covariant
                           when "in"
                             :contravariant
                           end
              end

              current_module!.type_params << AST::TypeParam.new(
                name: node.name,
                variance: variance || :invariant,
                location: nil,
                upper_bound: nil,
                lower_bound: nil,
                default_type: nil
              )
            end
          else
            name = if node.is_a?(Prism::ConstantWriteNode)
              TypeName.new(namespace: Namespace.empty, name: node.name)
            else
              const_to_name(node.target)
            end

            value_node = node.value
            type = if value_node.is_a?(Prism::CallNode) && value_node.name == :let
                    type_node = (value_node.arguments&.arguments || [])[1]
                    type_of type_node
                  else
                    Types::Bases::Any.new(location: nil)
                  end
            append_decl AST::Declarations::Constant.new(
              name: name,
              type: type,
              location: nil,
              comment: nil,
              annotations: []
            )
          end
        end
        alias visit_constant_path_write_node visit_constant_write_node

        def visit_constant_target_node(node)
          append_decl AST::Declarations::Constant.new(
            name: TypeName.new(namespace: Namespace.empty, name: node.name),
            type: Types::Bases::Any.new(location: nil),
            location: nil,
            comment: nil,
            annotations: []
          )
        end

        def append_decl(decl)
          if mod = current_module
            mod.members << decl
          else
            decls << decl
          end
        end

        def push_class(name, super_class, comment:)
          class_decl = AST::Declarations::Class.new(
            name: const_to_name(name),
            super_class: super_class && AST::Declarations::Class::Super.new(name: const_to_name(super_class), args: [], location: nil),
            type_params: [],
            members: [],
            annotations: [],
            location: nil,
            comment: comment
          )

          append_decl class_decl
          modules << class_decl
          @contexts << Context.new(singleton: false, visibility: :public)
          @emitted_visibility[class_decl.object_id] = :public

          yield
        ensure
          @contexts.pop
          modules.pop
        end

        def push_module(name, comment:)
          module_decl = AST::Declarations::Module.new(
            name: const_to_name(name),
            type_params: [],
            members: [],
            annotations: [],
            location: nil,
            self_types: [],
            comment: comment
          )

          append_decl module_decl
          modules << module_decl
          @contexts << Context.new(singleton: false, visibility: :public)
          @emitted_visibility[module_decl.object_id] = :public

          yield
        ensure
          @contexts.pop
          modules.pop
        end

        def current_module
          modules.last
        end

        def current_module!
          current_module or raise
        end

        def current_context
          @contexts.last
        end

        def current_context!
          current_context or raise
        end

        # Visibility of a member, given as `private def ...` in RBS
        #
        # Returns `nil` for members in a visibility _section_, which `sync_visibility` emits instead.
        def member_visibility(context)
          # RBS visibility sections don't apply to singleton members, so they need their own visibility.
          if context.singleton && context.visibility != :public
            :private
          end
        end

        def sync_visibility(visibility)
          # Visibility sections don't apply to singleton members in RBS.
          return if current_context!.singleton

          # RBS has no protected visibility. Private is the conservative fallback.
          visibility = :private if visibility == :protected

          mod = current_module!
          return if @emitted_visibility[mod.object_id] == visibility

          member = case visibility
                  when :public
                    AST::Members::Public.new(location: nil)
                  when :private
                    AST::Members::Private.new(location: nil)
                  else
                    raise "Unexpected visibility: #{visibility}"
                  end

          mod.members << member
          @emitted_visibility[mod.object_id] = visibility
        end

        def push_sig(node)
          if last_sig = @last_sig
            last_sig << node
          else
            @last_sig = [node]
          end
        end

        def pop_sig
          @last_sig.tap do
            @last_sig = nil
          end
        end

        def join_comments(nodes)
          cs = nodes.map {|node| @comments[node.start_line - 1] }.compact
          AST::Comment.new(string: cs.map(&:string).join("\n"), location: nil)
        end

        def process_visibility(node, visibility)
          args = node.arguments&.arguments || []
          context = current_context!

          if args.empty?
            context.visibility = visibility
          else
            previous_visibility = context.visibility
            context.visibility = visibility

            begin
              args.each do |arg|
                if arg.is_a?(Prism::DefNode)
                  visit(arg)
                end
              end
            ensure
              context.visibility = previous_visibility
            end
          end
        end

        def process_attribute(node, kind)
          sigs = pop_sig
          context = current_context!
          sync_visibility(context.visibility)

          type = attribute_type(kind, sigs)
          comment = join_comments(sigs) if sigs
          member_class = case kind
                         when :attr_reader
                           AST::Members::AttrReader
                         when :attr_writer
                           AST::Members::AttrWriter
                         when :attr_accessor
                           AST::Members::AttrAccessor
                         end

          node.arguments&.arguments&.each do |arg|
            if arg in Prism::SymbolNode => parameter
              current_module!.members << member_class.new(
                name: parameter.value,
                type: type,
                ivar_name: nil,
                kind: context.singleton ? :singleton : :instance,
                annotations: [],
                location: nil,
                comment: comment,
                visibility: member_visibility(context)
              )
            end
          end
        end

        def attribute_type(kind, sigs)
          any = Types::Bases::Any.new(location: nil)
          return any unless sigs

          method_types = sigs.filter_map do |sig|
            method_type(nil, sig, overloads: sigs.size)
          end
          function = method_types.last&.type
          return any unless function.is_a?(Types::Function)

          parameter_type = function.required_positionals.first&.type
          return_type = function.return_type

          case kind
          when :attr_reader
            return_type
          when :attr_writer
            parameter_type || return_type
          when :attr_accessor
            if return_type.is_a?(Types::Bases::Any) || return_type.is_a?(Types::Bases::Void)
              parameter_type || any
            else
              return_type
            end
          else
            any
          end
        end

        def method_type(args_node, type_node, overloads:)
          if type_node
            if type_node.is_a?(Prism::CallNode) && type_node.receiver
              method_type = method_type(args_node, type_node.receiver, overloads: overloads) or raise
            else
              method_type = MethodType.new(
                type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                block: nil,
                location: nil,
                type_params: []
              )
            end
            return method_type unless type_node.is_a?(Prism::CallNode)

            name = type_node.name
            args = type_node.arguments&.arguments || []

            case name
            when :returns
              return_type = args.first
              method_type.update(type: method_type.type.with_return_type(type_of(return_type)))
            when :params
              if args_node
                parse_params(args_node, args, method_type, overloads: overloads)
              else
                vars = keyword_args_to_hash(args.first).transform_values {|value| type_of(value) }
                required_positionals = vars.map do |name, type|
                  Types::Function::Param.new(name: name, type: type)
                end

                if method_type.type.is_a?(RBS::Types::Function)
                  method_type.update(type: method_type.type.update(required_positionals: required_positionals))
                else
                  method_type
                end
              end
            when :type_parameters
              type_params = [] #: Array[AST::TypeParam]

              args.each do |node|
                if node in Prism::SymbolNode => parameter
                  type_params << AST::TypeParam.new(
                    name: parameter.value,
                    variance: :invariant,
                    upper_bound: nil,
                    lower_bound: nil,
                    location: nil,
                    default_type: nil
                  )
                end
              end

              method_type.update(type_params: type_params)
            when :void
              method_type.update(type: method_type.type.with_return_type(Types::Bases::Void.new(location: nil)))
            when :proc
              method_type
            else
              method_type
            end
          end
        end

        def parse_params(args_node, args, method_type, overloads:)
          vars = keyword_args_to_hash(args.first).transform_values {|value| type_of(value) }

          # @type var required_positionals: Array[Types::Function::Param]
          required_positionals = args_node.requireds.filter_map do |arg|
            next unless arg.is_a?(Prism::RequiredParameterNode)
            type = vars[arg.name] || Types::Bases::Any.new(location: nil)
            Types::Function::Param.new(type: type, name: arg.name)
          end

          # @type var optional_positionals: Array[Types::Function::Param]
          optional_positionals = args_node.optionals.filter_map do |arg|
            if (type = vars[arg.name])
              Types::Function::Param.new(type: type, name: arg.name)
            end
          end

          # @type var rest_positionals: Types::Function::Param?
          rest_positionals = nil
          if args_node in { rest: { name: Symbol => name } }
            if (type = vars[name])
              rest_positionals = Types::Function::Param.new(type: type, name: name)
            end 
          end

          # @type var trailing_positionals: Array[Types::Function::Param]
          trailing_positionals = args_node.posts.filter_map do |arg|
            next unless arg.is_a?(Prism::RequiredParameterNode)
            if (type = vars[arg.name])
              Types::Function::Param.new(type: type, name: arg.name)
            end
          end

          # @type var required_keywords: Hash[Symbol, Types::Function::Param]
          required_keywords = {}
          # @type var optional_keywords: Hash[Symbol, Types::Function::Param]
          optional_keywords = {}
          args_node.keywords.each do |arg|
            next unless (type = vars[arg.name])
            if arg.is_a?(Prism::RequiredParameterNode)
              required_keywords[arg.name] = Types::Function::Param.new(type: type, name: arg.name)
            else
              optional_keywords[arg.name] = Types::Function::Param.new(type: type, name: arg.name)
            end
          end
          
          # @type var rest_keywords: Types::Function::Param?
          rest_keywords = nil

          if args_node in { keyword_rest: Prism::KeywordRestParameterNode(name: Symbol => name) }
            if (type = vars[name])
              rest_keywords = Types::Function::Param.new(type: type, name: name)
            end
          end

          method_block = nil
          if (block_name = args_node.block&.name)
            if (type = vars[block_name])
              if type.is_a?(Types::Proc)
                method_block = Types::Block.new(required: true, type: type.type, self_type: nil)
              elsif type.is_a?(Types::Bases::Any)
                method_block = Types::Block.new(
                  required: true,
                  type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                  self_type: nil
                )
              # Handle an optional block like `T.nilable(T.proc.void)`.
              elsif type.is_a?(Types::Optional) && (proc_type = type.type).is_a?(Types::Proc)
                method_block = Types::Block.new(required: false, type: proc_type.type, self_type: nil)
              else
                STDERR.puts "Unexpected block type: #{type}"
                PP.pp args_node, STDERR
                method_block = Types::Block.new(
                  required: true,
                  type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                  self_type: nil
                )
              end
            else
              if overloads == 1
                method_block = Types::Block.new(
                  required: false,
                  type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                  self_type: nil
                )
              end
            end
          end

          if method_type.type.is_a?(Types::Function)
            method_type.update(
              type: method_type.type.update(
                required_positionals: required_positionals,
                optional_positionals: optional_positionals,
                rest_positionals: rest_positionals,
                trailing_positionals: trailing_positionals,
                required_keywords: required_keywords,
                optional_keywords: optional_keywords,
                rest_keywords: rest_keywords
              ),
              block: method_block
            )
          else
            method_type
          end
        end

        def type_of(type_node)
          type = type_of0(type_node)

          case
          when type.is_a?(Types::ClassInstance) && type.name.name == BuiltinNames::BasicObject.name.name
            Types::Bases::Any.new(location: nil)
          when type.is_a?(Types::ClassInstance) && type.name.to_s.delete_prefix("::") == "T::Boolean"
            Types::Bases::Bool.new(location: nil)
          when type.is_a?(Types::ClassInstance) && type.name.to_s.delete_prefix("::") == "T::Class"
            Types::Bases::Any.new(location: nil)
          else
            type
          end
        end

        def type_of0(type_node)
          case type_node
          when Prism::ArrayNode
            types = type_node.elements.map {|node| type_of(node) }
            Types::Tuple.new(types: types, location: nil)
          when Prism::ConstantReadNode, Prism::ConstantPathNode
            Types::ClassInstance.new(name: const_to_name(type_node), args: [], location: nil)
          when Prism::CallNode
            arguments = type_node.arguments&.arguments || []
            if (receiver = type_node.receiver) in Prism::ConstantReadNode[name: :T]
              case type_node.name
              when :nilable
                type = type_of(arguments.first)
                Types::Optional.new(type: type, location: nil)
              when :untyped
                Types::Bases::Any.new(location: nil)
              when :type_parameter
                if arguments in [Prism::SymbolNode => first_arg]
                  Types::Variable.new(name: first_arg.value, location: nil)
                else
                  STDERR.puts "Unexpected type_node: #{type_node.slice}"
                  Types::Bases::Any.new(location: nil)
                end
              when :all
                types = arguments.map {|node| type_of(node) }
                Types::Intersection.new(types: types, location: nil)
              when :any
                types = arguments.map {|node| type_of(node) }
                Types::Union.new(types: types, location: nil)
              when :class_of
                type = type_of arguments.first
                case type
                when Types::ClassInstance
                  Types::ClassSingleton.new(name: type.name, location: nil)
                else
                  STDERR.puts "Unexpected type_node: #{type_node.slice}"
                  Types::Bases::Any.new(location: nil)
                end
              when :proc
                method_type = method_type(nil, type_node, overloads: 1) or raise
                Types::Proc.new(type: method_type.type, block: nil, location: nil, self_type: nil)
              when :attached_class
                Types::Bases::Instance.new(location: nil)
              when :self_type
                Types::Bases::Self.new(location: nil)
              when :noreturn
                Types::Bases::Bottom.new(location: nil)
              else
                STDERR.puts "Unexpected type_node: #{type_node.slice}"
                Types::Bases::Any.new(location: nil)
              end
            elsif receiver && type_node.name == :[]
              case receiver
              when Prism::ConstantReadNode, Prism::ConstantPathNode
                return Types::Bases::Any.new(location: nil) if const_to_name(receiver).to_s.delete_prefix("::") == "T::Class"
              end

              type = type_of(receiver)
              type.is_a?(Types::ClassInstance) or raise

              arguments.each do |arg|
                type.args << type_of(arg)
              end

              type
            elsif proc_type?(type_node)
              method_type = method_type(nil, type_node, overloads: 1) or raise
              Types::Proc.new(type: method_type.type, block: nil, location: nil, self_type: nil)
            else
              STDERR.puts "Unexpected type_node: #{type_node.slice}"
              Types::Bases::Any.new(location: nil)
            end
          else
            STDERR.puts "Unexpected type_node: #{type_node.slice}"
            Types::Bases::Any.new(location: nil)
          end
        end

        def proc_type?(type_node)
          return false unless type_node.is_a?(Prism::CallNode)

          case type_node.receiver
          in Prism::ConstantReadNode[name: :T]
            true
          else
            proc_type?(type_node.receiver)
          end
        end

        def const_to_name(node)
          case node
          when Prism::ConstantReadNode, Prism::ConstantPathNode
            parts = node.full_name_parts
            absolute = false
            if parts.first == :""
              absolute = true
              parts.shift
            end

            name = parts.pop or raise
            type_name = TypeName.new(name: name, namespace: Namespace[parts, absolute])

            case type_name.to_s.delete_prefix("::")
            when "T::Array"
              BuiltinNames::Array.name
            when "T::Hash"
              BuiltinNames::Hash.name
            when "T::Range"
              BuiltinNames::Range.name
            when "T::Enumerator"
              BuiltinNames::Enumerator.name
            when "T::Enumerable"
              BuiltinNames::Enumerable.name
            when "T::Set"
              BuiltinNames::Set.name
            else
              type_name
            end
          else
            raise "Unexpected node type: #{node.type}"
          end
        end

        def keyword_args_to_hash(node)
          return {} unless node.is_a?(Prism::KeywordHashNode)

          node.elements.filter_map do |element|
            case element
            in Prism::AssocNode[key: Prism::SymbolNode]
              [element.key.value.to_sym, element.value]
            else
              next
            end
          end.to_h
        end
      end
    end
  end
end

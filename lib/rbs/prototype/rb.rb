# frozen_string_literal: true

module RBS
  module Prototype
    class RB
      extend Helpers

      def self.parse(string)
        parse_result = Prism.parse(string, version: "current")
        raise SyntaxError unless parse_result.success?

        comments = process_comments(parse_result.comments, include_trailing: false)
        visitor = Visitor.new(comments)
        visitor.visit(parse_result.value)
        process_decls(visitor.decls)
      end

      def self.process_decls(decls)
        # @type var processed_decls: Array[AST::Declarations::t]
        processed_decls = []

        # @type var top_decls: Array[AST::Declarations::t]
        # @type var top_members: Array[AST::Members::t]
        top_decls, top_members = _ = decls.partition {|decl| decl.is_a?(AST::Declarations::Base) }

        processed_decls.push(*top_decls)

        unless top_members.empty?
          top = AST::Declarations::Class.new(
            name: TypeName.new(name: :Object, namespace: Namespace.empty),
            super_class: nil,
            members: top_members,
            annotations: [],
            comment: nil,
            location: nil,
            type_params: []
          )
          processed_decls << top
        end

        processed_decls
      end

      class Context < Struct.new(:module_function, :singleton, :namespace, :in_def, keyword_init: true)
        # @implements Context

        def self.initial(namespace: Namespace.root)
          self.new(module_function: false, singleton: false, namespace: namespace, in_def: false)
        end

        def method_kind
          if singleton
            :singleton
          elsif module_function
            :singleton_instance
          else
            :instance
          end
        end

        def attribute_kind
          if singleton
            :singleton
          else
            :instance
          end
        end

        def enter_namespace(namespace)
          Context.initial(namespace: self.namespace + namespace)
        end

        def update(module_function: self.module_function, singleton: self.singleton, in_def: self.in_def)
          Context.new(module_function: module_function, singleton: singleton, namespace: namespace, in_def: in_def)
        end
      end

      class Visitor < Prism::Visitor
        attr_reader :context
        attr_reader :comments
        attr_reader :decls

        def initialize(comments)
          @comments = comments
          @decls = []
          @context = Context.initial
        end

        def visit_class_node(node)
          super_class_name = const_to_name(node.superclass, context: context)
          super_class =
            if super_class_name
              AST::Declarations::Class::Super.new(name: super_class_name, args: [], location: nil)
            else
              # Give up detect super class e.g. `class Foo < Struct.new(:bar)`
              nil
            end
          kls = AST::Declarations::Class.new(
            name: const_to_name!(node.constant_path),
            super_class: super_class,
            type_params: [],
            members: [],
            annotations: [],
            location: nil,
            comment: comments[node.start_line - 1]
          )

          decls.push kls

          new_ctx = context.enter_namespace(kls.name.to_namespace)
          with(decls: kls.members, context: new_ctx) do
            visit(node.body)            
          end
          remove_unnecessary_accessibility_methods! kls.members
          sort_members! kls.members
        end

        def visit_module_node(node)
          mod = AST::Declarations::Module.new(
            name: const_to_name!(node.constant_path),
            type_params: [],
            self_types: [],
            members: [],
            annotations: [],
            location: nil,
            comment: comments[node.start_line - 1]
          )

          decls.push mod

          new_ctx = context.enter_namespace(mod.name.to_namespace)
          with(decls: mod.members, context: new_ctx) do
            visit(node.body)
          end

          remove_unnecessary_accessibility_methods! mod.members
          sort_members! mod.members
        end

        def visit_singleton_class_node(node)
          unless node.expression.is_a?(Prism::SelfNode)
            RBS.logger.warn "`class <<` syntax with not-self may be compiled to incorrect code: #{node.expression.slice}"
          end

          accessibility = current_accessibility(decls)

          ctx = Context.initial.tap { |ctx| ctx.singleton = true }
          with(decls: decls, context: ctx) do
            visit(node.body)
          end

          decls << accessibility
        end

        def visit_def_node(node)
          # @type var kind: Context::method_kind
          kind = node.receiver ? :singleton : context.method_kind

          types = [
            MethodType.new(
              type_params: [],
              type: function_type_from_def_node(node),
              block: block_from_body(node.body, node.parameters),
              location: nil
            )
          ]

          member = AST::Members::MethodDefinition.new(
            name: node.name,
            location: nil,
            annotations: [],
            overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type )},
            kind: kind,
            comment: comments[node.start_line - 1],
            overloading: false,
            visibility: nil
          )

          decls.push member unless decls.include?(member)

          new_ctx = context.update(singleton: kind == :singleton, in_def: true)
          with(decls: decls, context: new_ctx) do
            visit(node.body)
          end
        end

        def visit_alias_method_node(node)
          new_name = literal_to_symbol(node.new_name)
          old_name = literal_to_symbol(node.old_name)
          if new_name && old_name
            member = AST::Members::Alias.new(
              new_name: new_name,
              old_name: old_name,
              kind: context.singleton ? :singleton : :instance,
              annotations: [],
              location: nil,
              comment: comments[node.start_line - 1],
            )
            decls.push member unless decls.include?(member)
          end
        end

        def visit_call_node(node)
          visit(node.receiver)
          return if node.block || node.receiver

          # Inside method definition cannot reach here.
          args = node.arguments&.arguments || []

          case node.name
          when :include
            args.each do |arg|
              if (name = const_to_name(arg, context: context))
                klass = context.singleton ? AST::Members::Extend : AST::Members::Include
                decls << klass.new(
                  name: name,
                  args: [],
                  annotations: [],
                  location: nil,
                  comment: comments[node.start_line - 1]
                )
              end
            end
          when :prepend
            args.each do |arg|
              if (name = const_to_name(arg, context: context))
                decls << AST::Members::Prepend.new(
                  name: name,
                  args: [],
                  annotations: [],
                  location: nil,
                  comment: comments[node.start_line - 1]
                )
              end
            end
          when :extend
            args.each do |arg|
              if (name = const_to_name(arg, context: context))
                decls << AST::Members::Extend.new(
                  name: name,
                  args: [],
                  annotations: [],
                  location: nil,
                  comment: comments[node.start_line - 1]
                )
              end
            end
          when :attr_reader
            args.each do |arg|
              if (name = literal_to_symbol(arg))
                decls << AST::Members::AttrReader.new(
                  name: name,
                  ivar_name: nil,
                  type: Types::Bases::Any.new(location: nil),
                  kind: context.attribute_kind,
                  location: nil,
                  comment: comments[node.start_line - 1],
                  annotations: []
                )
              end
            end
          when :attr_accessor
            args.each do |arg|
              if (name = literal_to_symbol(arg))
                decls << AST::Members::AttrAccessor.new(
                  name: name,
                  ivar_name: nil,
                  type: Types::Bases::Any.new(location: nil),
                  kind: context.attribute_kind,
                  location: nil,
                  comment: comments[node.start_line - 1],
                  annotations: []
                )
              end
            end
          when :attr_writer
            args.each do |arg|
              if arg && (name = literal_to_symbol(arg))
                decls << AST::Members::AttrWriter.new(
                  name: name,
                  ivar_name: nil,
                  type: Types::Bases::Any.new(location: nil),
                  kind: context.attribute_kind,
                  location: nil,
                  comment: comments[node.start_line - 1],
                  annotations: []
                )
              end
            end
          when :alias_method
            if args.size == 2 && (new_name = literal_to_symbol(args[0])) && (old_name = literal_to_symbol(args[1]))
              decls << AST::Members::Alias.new(
                new_name: new_name,
                old_name: old_name,
                kind: context.singleton ? :singleton : :instance,
                annotations: [],
                location: nil,
                comment: comments[node.start_line - 1],
              )
            end
          when :module_function
            if args.empty?
              context.module_function = true
            else
              module_func_context = context.update(module_function: true)
              args.each do |arg|
                if (name = literal_to_symbol(arg))
                  if (i, defn = find_def_index_by_name(decls, name))
                    if defn.is_a?(AST::Members::MethodDefinition)
                      decls[i] = defn.update(kind: :singleton_instance)
                    end
                  end
                elsif arg
                  with(decls: decls, context: module_func_context) do
                    visit(arg)
                  end
                end
              end
            end
          when :public, :private
            accessibility = __send__(node.name)
            if args.empty?
              decls << accessibility
            else
              args.each do |arg|
                if (name = literal_to_symbol(arg))
                  if (i, _ = find_def_index_by_name(decls, name))
                    current = current_accessibility(decls, i)
                    if current != accessibility
                      decls.insert(i + 1, current)
                      decls.insert(i, accessibility)
                    end
                  end
                end
              end

              # For `private def foo` syntax
              current = current_accessibility(decls)
              decls << accessibility
              visit(node.arguments)
              decls << current
            end
          else
            visit(node.arguments)
          end
        end

        def visit_constant_write_node(node)
          const_name = const_to_name!(node, context: context)

          value_node = node.value
          type = if value_node.is_a?(Prism::SelfNode)
                  # Give up type prediction.
                  Types::Bases::Any.new(location: nil)
                else
                  literal_to_type(value_node)
                end
          decls << AST::Declarations::Constant.new(
            name: const_name,
            type: type,
            location: nil,
            comment: comments[node.start_line - 1],
            annotations: []
          )
        end
        alias visit_constant_path_write_node visit_constant_write_node

        def visit_constant_target_node(node)
          decls << AST::Declarations::Constant.new(
            name: TypeName.new(name: node.name, namespace: Namespace.empty),
            type: Types::Bases::Any.new(location: nil),
            location: nil,
            comment: comments[node.start_line - 1],
            annotations: []
          )
        end

        def visit_instance_variable_write_node(node)
          case [context.singleton, context.in_def]
          when [true, true], [false, false]
            member = AST::Members::ClassInstanceVariable.new(
              name: node.name,
              type: Types::Bases::Any.new(location: nil),
              location: nil,
              comment: comments[node.start_line - 1]
            )
          when [false, true]
            member = AST::Members::InstanceVariable.new(
              name: node.name,
              type: Types::Bases::Any.new(location: nil),
              location: nil,
              comment: comments[node.start_line - 1]
            )
          when [true, false]
            # The variable is for the singleton class of the class object.
            # RBS does not have a way to represent it. So we ignore it.
          else
            raise 'unreachable'
          end

          decls.push member if member && !decls.include?(member)
        end
        alias visit_instance_variable_or_write_node visit_instance_variable_write_node
        alias visit_instance_variable_and_write_node visit_instance_variable_write_node
        alias visit_instance_variable_operator_write_node visit_instance_variable_write_node
        alias visit_instance_variable_target_node visit_instance_variable_write_node

        def visit_class_variable_write_node(node)
          member = AST::Members::ClassVariable.new(
            name: node.name,
            type: Types::Bases::Any.new(location: nil),
            location: nil,
            comment: comments[node.start_line - 1]
          )
          decls.push member unless decls.include?(member)
        end
        alias visit_class_variable_or_write_node visit_class_variable_write_node
        alias visit_class_variable_and_write_node visit_class_variable_write_node
        alias visit_class_variable_operator_write_node visit_class_variable_write_node
        alias visit_class_variable_target_node visit_class_variable_write_node

        def with(decls:, context:)
          orig_decls, orig_context = @decls, @context
          @decls, @context = decls, context
          yield
        ensure
          @decls, @context = orig_decls, orig_context
        end

        def untyped
          @untyped ||= Types::Bases::Any.new(location: nil)
        end

        def private
          @private ||= AST::Members::Private.new(location: nil)
        end

        def public
          @public ||= AST::Members::Public.new(location: nil)
        end

        def current_accessibility(decls, index = decls.size)
          slice = decls.slice(0, index) or raise
          idx = slice.rindex { |decl| decl == private || decl == public }
          if idx
            _ = decls[idx]
          else
            public
          end
        end

        def remove_unnecessary_accessibility_methods!(decls)
          # @type var current: decl
          current = public
          idx = 0

          loop do
            decl = decls[idx] or break
            if current == decl
              decls.delete_at(idx)
              next
            end

            if 0 < idx && is_accessibility?(decls[idx - 1]) && is_accessibility?(decl)
              decls.delete_at(idx - 1)
              idx -= 1
              current = current_accessibility(decls, idx)
              next
            end

            current = decl if is_accessibility?(decl)
            idx += 1
          end

          decls.pop while decls.last && is_accessibility?(decls.last || raise)
        end

        def is_accessibility?(decl)
          decl == public || decl == private
        end

        def find_def_index_by_name(decls, name)
          index = decls.find_index do |decl|
            case decl
            when AST::Members::MethodDefinition, AST::Members::AttrReader
              decl.name == name
            when AST::Members::AttrWriter
              :"#{decl.name}=" == name
            end
          end

          if index
            [
              index,
              _ = decls[index]
            ]
          end
        end

        def sort_members!(decls)
          i = 0
          orders = {
            AST::Members::ClassVariable => -3,
            AST::Members::ClassInstanceVariable => -2,
            AST::Members::InstanceVariable => -1,
          } #: Hash[Class, Integer]
          decls.sort_by! { |decl| [orders.fetch(decl.class, 0), i += 1] }
        end

        def const_to_name!(node, context: nil)
          case node
          when Prism::ConstantReadNode, Prism::ConstantWriteNode
            TypeName.new(name: node.name, namespace: Namespace.empty)
          when Prism::ConstantPathWriteNode
            const_to_name!(node.target, context: context)
          when Prism::ConstantPathNode
            if node.parent
              namespace = const_to_name!(node.parent, context: context).to_namespace
            else
              namespace = Namespace.root
            end

            TypeName.new(name: node.name || raise, namespace: namespace)
          when Prism::SelfNode
            raise if context.nil?

            context.namespace.to_type_name
          else
            raise node.class.to_s
          end
        end

        def const_to_name(node, context:)
          case node
          when Prism::SelfNode
            context.namespace.to_type_name
          when Prism::ConstantReadNode, Prism::ConstantPathNode
            const_to_name!(node) rescue nil
          end
        end

        def function_type_from_def_node(node)
          return_type = if node.name == :initialize
                          Types::Bases::Void.new(location: nil)
                        else
                          body_type(node.body)
                        end

          fun = Types::Function.empty(return_type)

          node.parameters&.requireds&.each do |arg|
            next unless arg.is_a?(Prism::RequiredParameterNode)
            fun.required_positionals << Types::Function::Param.new(name: arg.name, type: untyped)
          end

          node.parameters&.optionals&.each do |arg|
            fun.optional_positionals << Types::Function::Param.new(
              name: arg.name,
              type: param_type(arg.value)
            )
          end

          if (rest = node.parameters&.rest)
            rest_name = rest.is_a?(Prism::RestParameterNode) ? rest.name : nil
            fun = fun.update(rest_positionals: Types::Function::Param.new(name: rest_name, type: untyped))
          end

          node.parameters&.posts&.each do |post|
            next unless post.is_a?(Prism::RequiredParameterNode)
            fun.trailing_positionals << Types::Function::Param.new(name: post.name, type: untyped)
          end

          node.parameters&.keywords&.each do |kw|
            if kw.is_a?(Prism::RequiredKeywordParameterNode)
              fun.required_keywords[kw.name] = Types::Function::Param.new(name: nil, type: untyped)
            else
              fun.optional_keywords[kw.name] = Types::Function::Param.new(name: nil, type: param_type(kw.value))
            end
          end

          if (kw_rest = node.parameters&.keyword_rest)
            case kw_rest
            when Prism::KeywordRestParameterNode
              fun = fun.update(rest_keywords: Types::Function::Param.new(name: kw_rest.name, type: untyped))
            when Prism::ForwardingParameterNode
              fun = fun.update(rest_positionals: Types::Function::Param.new(name: nil, type: untyped))
              fun = fun.update(rest_keywords: Types::Function::Param.new(name: nil, type: untyped))
            end
          end

          fun
        end

        def block_from_body(body_node, parameters)
          # @type var body_node: node?
          if body_node
            yields = any_node?(body_node) {|n| n.is_a?(Prism::YieldNode) }
          end
          triple_dot = parameters&.keyword_rest.is_a?(Prism::ForwardingParameterNode)

          if yields || parameters&.block || triple_dot
            block_var = parameters&.block&.name
            required = !triple_dot

            if body_node
              if any_node?(body_node) {|n| n.is_a?(Prism::CallNode) && n.name == :block_given? && !n.receiver && !n.arguments }
                required = false
              end
            end

            if block_var && body_node
              usage = NodeUsage.new(body_node)
              if usage.each_conditional_node.any? {|n| n.is_a?(Prism::LocalVariableReadNode) && n.name == block_var }
                required = false
              end
            end

            if yields
              function = Types::Function.empty(untyped)

              yields.each do |yield_node|
                yield_args = yield_node.arguments&.arguments || []

                # @type var keywords: node?
                positionals, keywords = if keyword_hash?(yield_args.last)
                                          [yield_args.take(yield_args.size - 1), yield_args.last]
                                        else
                                          [yield_args, nil]
                                        end

                if (diff = positionals.size - function.required_positionals.size) > 0
                  diff.times do
                    function.required_positionals << Types::Function::Param.new(
                      type: untyped,
                      name: nil
                    )
                  end
                end

                if keywords
                  keywords.elements.each do |assoc_node|
                    key = assoc_node.key.value.to_sym
                    function.required_keywords[key] ||=
                      Types::Function::Param.new(
                        type: untyped,
                        name: nil
                      )
                  end
                end
              end
            else
              function = Types::UntypedFunction.new(return_type: untyped)
            end

            Types::Block.new(required: required, type: function, self_type: nil)
          end
        end

        def body_type(node)
          return Types::Bases::Nil.new(location: nil) unless node

          node = node.body.first if node.is_a?(Prism::StatementsNode) && node.body.size == 1
          case node
          when Prism::IfNode
            types_to_union_type([body_type(node.statements), body_type(node.subsequent)])
          when Prism::UnlessNode
            types_to_union_type([body_type(node.statements), body_type(node.else_clause)])
          when Prism::ElseNode
            body_type(node.statements)
          when Prism::StatementsNode
            block_type(node)
          when Prism::ReturnNode
            return_node_to_type(node)
          else
            literal_to_type(node)
          end
        end

        def block_type(node)
          return_stmts = any_node?(node) do |n|
            n.is_a?(Prism::ReturnNode)
          end&.map do |return_node|
            return_node_to_type(return_node)
          end || []

          last_node = node.compact_child_nodes.last
          case last_node
          when nil, Prism::ReturnNode
            types_to_union_type(return_stmts)
          else
            types_to_union_type([*return_stmts, literal_to_type(last_node)])
          end
        end

        def literal_to_symbol(node)
          case node
          when Prism::SymbolNode, Prism::StringNode
            node.unescaped.to_sym
          end
        end

        def literal_to_type(node)
          case node
          in Prism::StringNode
            lit = node.unescaped
            if lit.ascii_only?
              Types::Literal.new(literal: lit, location: nil)
            else
              BuiltinNames::String.instance_type
            end
          in Prism::InterpolatedStringNode | Prism::XStringNode | Prism::InterpolatedXStringNode
            BuiltinNames::String.instance_type
          in Prism::SymbolNode
            lit = node.unescaped.to_sym
            if lit.to_s.ascii_only?
              Types::Literal.new(literal: lit, location: nil)
            else
              BuiltinNames::Symbol.instance_type
            end
          in Prism::InterpolatedSymbolNode
            BuiltinNames::Symbol.instance_type
          in Prism::RegularExpressionNode | Prism::InterpolatedRegularExpressionNode
            BuiltinNames::Regexp.instance_type
          in Prism::TrueNode
            Types::Literal.new(literal: true, location: nil)
          in Prism::FalseNode
            Types::Literal.new(literal: false, location: nil)
          in Prism::NilNode
            Types::Bases::Nil.new(location: nil)
          in Prism::IntegerNode
            Types::Literal.new(literal: node.value, location: nil)
          in Prism::FloatNode
            BuiltinNames::Float.instance_type
          in Prism::RationalNode | Prism::ImaginaryNode
            lit = node.value
            type_name = TypeName.new(name: lit.class.name.to_sym, namespace: Namespace.root)
            Types::ClassInstance.new(name: type_name, args: [], location: nil)
          in Prism::ArrayNode
            elem_types = node.compact_child_nodes.map { |e| literal_to_type(e) }
            t = types_to_union_type(elem_types)
            BuiltinNames::Array.instance_type(t)
          in Prism::RangeNode
            types = [literal_to_type(node.left), literal_to_type(node.right)]
            type = range_element_type(types)
            BuiltinNames::Range.instance_type(type)
          in Prism::HashNode | Prism::KeywordHashNode
            key_types = [] #: Array[Types::t]
            value_types = [] #: Array[Types::t]
            node.elements.each do |element|
              if element.is_a?(Prism::AssocNode)
                key_types << literal_to_type(element.key)
                value_types << literal_to_type(element.value)
              else
                key_types << untyped
                value_types << untyped
              end
            end

            if !key_types.empty? && key_types.all? { |t| t.is_a?(Types::Literal) }
              fields = key_types.map {|t|
                t.is_a?(Types::Literal) or raise
                t.literal
              }.zip(value_types).to_h #: Hash[Types::Literal::literal, Types::t]
              Types::Record.new(fields: fields, location: nil)
            else
              key_type = types_to_union_type(key_types)
              value_type = types_to_union_type(value_types)
              BuiltinNames::Hash.instance_type(key_type, value_type)
            end
          in Prism::SelfNode
            Types::Bases::Self.new(location: nil)
          in Prism::CallNode[receiver: receiver]
            case node.name
            when :freeze, :tap, :itself, :dup, :clone, :taint, :untaint, :extend
              literal_to_type(receiver)
            else
              untyped
            end
          else
            untyped
          end
        end

        def return_node_to_type(node)
          return_args = node.arguments&.arguments || []
          return_types =  return_args.map { |arg| literal_to_type(arg) }

          if return_types.size >= 2
            t = types_to_union_type(return_types)
            BuiltinNames::Array.instance_type(t)
          else
            return_types.first || Types::Bases::Nil.new(location: nil)
          end
        end

        def types_to_union_type(types)
          return untyped if types.empty?

          uniq = types.uniq
          if uniq.size == 1
            return uniq.first || raise
          end

          Types::Union.new(types: uniq, location: nil)
        end

        def range_element_type(types)
          types = types.reject { |t| t == untyped }
          return untyped if types.empty?

          types = types.map do |t|
            if t.is_a?(Types::Literal)
              type_name = TypeName.new(name: t.literal.class.name&.to_sym || raise, namespace: Namespace.root)
              Types::ClassInstance.new(name: type_name, args: [], location: nil)
            else
              t
            end
          end.uniq

          if types.size == 1
            types.first or raise
          else
            untyped
          end
        end

        def param_type(node, default: Types::Bases::Any.new(location: nil))
          case node
          when Prism::IntegerNode
            BuiltinNames::Integer.instance_type
          when Prism::FloatNode
            BuiltinNames::Float.instance_type
          when Prism::RationalNode
            Types::ClassInstance.new(name: TypeName.parse("::Rational"), args: [], location: nil)
          when Prism::ImaginaryNode
            Types::ClassInstance.new(name: TypeName.parse("::Complex"), args: [], location: nil)
          when Prism::SymbolNode, Prism::InterpolatedSymbolNode
            BuiltinNames::Symbol.instance_type
          when Prism::StringNode, Prism::InterpolatedStringNode, Prism::XStringNode, Prism::InterpolatedStringNode
            BuiltinNames::String.instance_type
          when Prism::NilNode
            # This type is technical non-sense, but may help practically.
            Types::Optional.new(
              type: Types::Bases::Any.new(location: nil),
              location: nil
            )
          when Prism::TrueNode, Prism::FalseNode
            Types::Bases::Bool.new(location: nil)
          when Prism::ArrayNode
            BuiltinNames::Array.instance_type(default)
          when Prism::HashNode
            BuiltinNames::Hash.instance_type(default, default)
          else
            default
          end
        end

        # backward compatible
        alias node_type param_type

        def any_node?(node, nodes: [], &block)
          if yield(node)
            nodes << node
          end

          node.compact_child_nodes.each do |child|
            any_node? child, nodes: nodes, &block
          end

          nodes.empty? ? nil : nodes
        end

        def keyword_hash?(node)
          return false unless node.is_a?(Prism::KeywordHashNode)

          node.elements.all? do |element|
            element.is_a?(Prism::AssocNode) && element.key.is_a?(Prism::SymbolNode)
          end
        end
      end
    end
  end
end

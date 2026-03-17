# frozen_string_literal: true

module RBS
  module Prototype
    module RB
      class Prism < Base
        class NodeUsage
          attr_reader :conditional_nodes

          def initialize(node)
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

          private

          def calculate(node, conditional:)
            conditional_nodes << node if conditional

            case node.type
            when :if_node, :unless_node
              calculate(node.predicate, conditional: true)

              if node.type == :if_node
                calculate_statements(node.statements, conditional: conditional)
                case node.subsequent&.type
                when :else_node
                  calculate_statements(node.subsequent.statements, conditional: conditional)
                when :if_node
                  calculate(node.subsequent, conditional: conditional)
                end
              else
                calculate_statements(node.statements, conditional: conditional)
                calculate_statements(node.else_clause&.statements, conditional: conditional)
              end

            when :and_node, :or_node
              calculate(node.left, conditional: true)
              calculate(node.right, conditional: conditional)

            when :call_node
              if node.safe_navigation? && node.receiver
                calculate(node.receiver, conditional: true)
                node.arguments&.arguments&.each { |a| calculate(a, conditional: false) }
              else
                node.each_child_node { |c| calculate(c, conditional: false) }
              end

            when :while_node, :until_node
              calculate(node.predicate, conditional: true)
              calculate_statements(node.statements, conditional: false)

            when :local_variable_or_write_node, :local_variable_and_write_node
              conditional_nodes << node
              calculate(node.value, conditional: conditional)

            when :local_variable_write_node, :instance_variable_write_node, :global_variable_write_node
              calculate(node.value, conditional: conditional)

            when :multi_write_node
              node.lefts.each { |t| calculate(t, conditional: conditional) }
              calculate(node.value, conditional: conditional)

            when :constant_write_node
              calculate(node.value, conditional: conditional)

            when :constant_path_write_node
              calculate(node.target, conditional: false)
              calculate(node.value, conditional: conditional)

            when :statements_node
              if node.body.size > 0
                node.body[0...-1].each { |n| calculate(n, conditional: false) }
                calculate(node.body.last, conditional: conditional) if node.body.last
              end

            when :case_match_node
              node.conditions.each do |cond|
                calculate(cond.pattern, conditional: true) if cond.respond_to?(:pattern)
                calculate_statements(cond.statements, conditional: conditional) if cond.respond_to?(:statements)
              end
              calculate_statements(node.else_clause&.statements, conditional: conditional)

            when :case_node
              node.conditions.each do |when_node|
                when_node.conditions.each { |c| calculate(c, conditional: true) }
                calculate_statements(when_node.statements, conditional: conditional)
              end
              calculate_statements(node.else_clause&.statements, conditional: conditional)

            when :def_node
              calculate(node.body, conditional: conditional) if node.body

            else
              node.each_child_node { |c| calculate(c, conditional: false) }
            end
          end

          def calculate_statements(node, conditional:)
            return unless node
            calculate(node, conditional: conditional)
          end
        end

        # Pre-scan a method body in a single pass, collecting yields,
        # block_given? calls, and return nodes so we don't walk the tree
        # multiple times.
        BodyInfo = Struct.new(:yields, :has_block_given, :returns, keyword_init: true)

        private_constant :NodeUsage, :BodyInfo

        def parse(string)
          result = ::Prism.parse(string)
          comments = build_comments_prism(result.comments, include_trailing: false)
          process(result.value, decls: source_decls, comments: comments, context: Context.initial)
        end

        def block_from_def(node, body_info = build_body_info(node.body))
          params = node.parameters
          body = node.body

          block_param = params&.block
          forwarding = params&.keyword_rest&.type == :forwarding_parameter_node

          yields = body_info.yields
          has_block_given = body_info.has_block_given

          if !yields.empty? || block_param || forwarding
            required = !has_block_given && !forwarding

            if required && block_param.is_a?(::Prism::BlockParameterNode)
              block_name = block_param.name
              if body && block_name
                usage = NodeUsage.new(body)
                if usage.each_conditional_node.any? { |n| n.type == :local_variable_read_node && n.name == block_name }
                  required = false
                end
              end
            end

            if !yields.empty?
              function = Types::Function.empty(untyped)

              yields.each do |yield_node|
                args = yield_node.arguments&.arguments || []
                positionals, keywords =
                  if args.last && keyword_hash?(args.last)
                    [args[0...-1] || [], args.last]
                  else
                    [args, nil]
                  end

                if (diff = positionals.size - function.required_positionals.size) > 0
                  diff.times do
                    function.required_positionals << Types::Function::Param.new(type: untyped, name: nil)
                  end
                end

                if keywords
                  elements =
                    case keywords
                    when ::Prism::KeywordHashNode, ::Prism::HashNode then keywords.elements
                    else [] #: Array[Prism::AssocNode | Prism::AssocSplatNode]
                    end

                  elements.each do |elem| #: Prism::node
                    if elem.is_a?(::Prism::AssocNode) && elem.key.is_a?(::Prism::SymbolNode)
                      function.required_keywords[elem.key.unescaped.to_sym] ||=
                        Types::Function::Param.new(type: untyped, name: nil)
                    end
                  end
                end
              end
            else
              function = Types::UntypedFunction.new(return_type: untyped)
            end

            Types::Block.new(required: required, type: function, self_type: nil)
          end
        end

        private

        def process(node, decls:, comments:, context:)
          case node.type
          when :program_node
            process(node.statements, decls: decls, comments: comments, context: context)
          when :statements_node
            node.body.each do |child|
              process(child, decls: decls, comments: comments, context: context)
            end
          when :begin_node
            if (statements = node.statements)
              process(statements, decls: decls, comments: comments, context: context)
            end
          when :class_node
            super_class_name = const_to_name(node.superclass, context: context)
            super_class =
              if super_class_name
                AST::Declarations::Class::Super.new(name: super_class_name, args: [], location: nil)
              end

            kls = AST::Declarations::Class.new(
              name: const_to_name!(node.constant_path),
              super_class: super_class,
              type_params: [],
              members: [],
              annotations: [],
              location: nil,
              comment: comments[node.location.start_line - 1]
            )

            decls.push(kls)

            new_ctx = context.enter_namespace(kls.name.to_namespace)
            if (body = node.body)
              process(body, decls: kls.members, comments: comments, context: new_ctx)
            end

            remove_unnecessary_accessibility_methods!(kls.members)
            sort_members!(kls.members)
          when :module_node
            mod = AST::Declarations::Module.new(
              name: const_to_name!(node.constant_path),
              type_params: [],
              self_types: [],
              members: [],
              annotations: [],
              location: nil,
              comment: comments[node.location.start_line - 1]
            )

            decls.push mod

            new_ctx = context.enter_namespace(mod.name.to_namespace)
            if (body = node.body)
              process(body, decls: mod.members, comments: comments, context: new_ctx)
            end

            remove_unnecessary_accessibility_methods!(mod.members)
            sort_members!(mod.members)
          when :singleton_class_node
            unless node.expression.is_a?(::Prism::SelfNode)
              RBS.logger.warn "`class <<` syntax with not-self may be compiled to incorrect code: #{node.expression}"
            end

            accessibility = current_accessibility(decls)
            ctx = Context.initial.tap { |c| c.singleton = true }
            if (body = node.body)
              process(body, decls: decls, comments: comments, context: ctx)
            end

            decls << accessibility
          when :def_node
            kind = node.receiver ? :singleton : context.method_kind #: AST::Members::MethodDefinition::kind
            body_info = build_body_info(node.body)

            types = [
              MethodType.new(
                type_params: [],
                type: function_type(node, body_info),
                block: block_from_def(node, body_info),
                location: nil
              )
            ]

            member = AST::Members::MethodDefinition.new(
              name: node.name,
              location: nil,
              annotations: [],
              overloads: types.map { |type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
              kind: kind,
              comment: comments[node.location.start_line - 1],
              overloading: false,
              visibility: nil
            )

            decls.push(member) unless decls.include?(member)

            new_ctx = context.update(singleton: kind == :singleton, in_def: true)
            if (body = node.body)
              process(body, decls: decls, comments: comments, context: new_ctx)
            end
          when :alias_method_node
            new_name = symbol_value(node.new_name)
            old_name = symbol_value(node.old_name)

            if new_name && old_name
              member = AST::Members::Alias.new(
                new_name: new_name,
                old_name: old_name,
                kind: context.singleton ? :singleton : :instance,
                annotations: [],
                location: nil,
                comment: comments[node.location.start_line - 1],
              )

              decls.push(member) unless decls.include?(member)
            end
          when :call_node
            return if node.block.is_a?(::Prism::BlockNode)
            return if node.receiver

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
                    comment: comments[node.location.start_line - 1]
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
                    comment: comments[node.location.start_line - 1]
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
                    comment: comments[node.location.start_line - 1]
                  )
                end
              end
            when :attr_reader, :attr_accessor, :attr_writer
              klass =
                case node.name
                when :attr_reader then AST::Members::AttrReader
                when :attr_accessor then AST::Members::AttrAccessor
                when :attr_writer then AST::Members::AttrWriter
                end

              args.each do |arg|
                if klass && (name = symbol_value(arg))
                  decls << klass.new(
                    name: name, ivar_name: nil,
                    type: Types::Bases::Any.new(location: nil),
                    kind: context.attribute_kind,
                    location: nil,
                    comment: comments[node.location.start_line - 1],
                    annotations: []
                  )
                end
              end
            when :alias_method
              if args.size >= 2 && (new_name = symbol_value(args[0])) && (old_name = symbol_value(args[1]))
                decls << AST::Members::Alias.new(
                  new_name: new_name,
                  old_name: old_name,
                  kind: context.singleton ? :singleton : :instance,
                  annotations: [],
                  location: nil,
                  comment: comments[node.location.start_line - 1],
                )
              end
            when :module_function
              if args.empty?
                context.module_function = true
              else
                module_func_context = context.update(module_function: true)
                args.each do |arg|
                  if (name = symbol_value(arg))
                    if (i, defn = find_def_index_by_name(decls, name))
                      if defn.is_a?(AST::Members::MethodDefinition)
                        decls[i] = defn.update(kind: :singleton_instance)
                      end
                    end
                  else
                    process(arg, decls: decls, comments: comments, context: module_func_context)
                  end
                end
              end
            when :public, :private
              accessibility = __send__(node.name)
              if args.empty?
                decls << accessibility
              else
                args.each do |arg|
                  if (name = symbol_value(arg))
                    if (i, _ = find_def_index_by_name(decls, name))
                      current = current_accessibility(decls, i)
                      if current != accessibility
                        decls.insert(i + 1, current)
                        decls.insert(i, accessibility)
                      end
                    end
                  end
                end

                current = current_accessibility(decls)
                decls << accessibility
                args.each do |arg|
                  process(arg, decls: decls, comments: comments, context: context)
                end
                decls << current
              end
            else
              args.each do |arg|
                process(arg, decls: decls, comments: comments, context: context)
              end
            end
          when :constant_write_node
            type = node.value.type == :self_node ? Types::Bases::Any.new(location: nil) : literal_to_type(node.value)
            decls << AST::Declarations::Constant.new(
              name: TypeName.new(name: node.name, namespace: Namespace.empty),
              type: type,
              location: nil,
              comment: comments[node.location.start_line - 1],
              annotations: []
            )
          when :constant_path_write_node
            type = node.value.type == :self_node ? Types::Bases::Any.new(location: nil) : literal_to_type(node.value)

            decls << AST::Declarations::Constant.new(
              name: const_to_name!(node.target, context: context),
              type: type,
              location: nil,
              comment: comments[node.location.start_line - 1],
              annotations: []
            )
          when :instance_variable_write_node, :instance_variable_or_write_node,
               :instance_variable_and_write_node, :instance_variable_operator_write_node
            case [context.singleton, context.in_def]
            when [true, true], [false, false]
              member = AST::Members::ClassInstanceVariable.new(
                name: node.name,
                type: Types::Bases::Any.new(location: nil),
                location: nil,
                comment: comments[node.location.start_line - 1]
              )
            when [false, true]
              member = AST::Members::InstanceVariable.new(
                name: node.name,
                type: Types::Bases::Any.new(location: nil),
                location: nil,
                comment: comments[node.location.start_line - 1]
              )
            when [true, false]
              # Singleton class ivar - RBS can't represent it
            else
              raise 'unreachable'
            end

            decls.push(member) if member && !decls.include?(member)
          when :class_variable_write_node, :class_variable_or_write_node,
               :class_variable_and_write_node, :class_variable_operator_write_node
            member = AST::Members::ClassVariable.new(
              name: node.name,
              type: Types::Bases::Any.new(location: nil),
              location: nil,
              comment: comments[node.location.start_line - 1]
            )

            decls.push(member) unless decls.include?(member)
          when :multi_write_node
            (node.lefts + node.rights).each do |target|
              if target.is_a?(::Prism::ConstantTargetNode)
                decls << AST::Declarations::Constant.new(
                  name: TypeName.new(name: target.name, namespace: Namespace.empty),
                  type: Types::Bases::Any.new(location: nil),
                  location: nil,
                  comment: comments[node.location.start_line - 1],
                  annotations: []
                )
              end
            end
          else
            node.each_child_node do |child|
              process(child, decls: decls, comments: comments, context: context)
            end
          end
        end

        def const_to_name!(node, context: nil)
          case node.type
          when :constant_read_node
            TypeName.new(name: node.name, namespace: Namespace.empty)
          when :constant_path_node
            if node.parent.nil?
              TypeName.new(name: node.name || raise, namespace: Namespace.root)
            else
              namespace = const_to_name!(node.parent, context: context).to_namespace
              TypeName.new(name: node.name || raise, namespace: namespace)
            end
          when :self_node
            raise if context.nil?
            context.namespace.to_type_name
          else
            raise "Unexpected node for const name: #{node.class}"
          end
        end

        def const_to_name(node, context:)
          return nil unless node

          case node.type
          when :self_node
            context.namespace.to_type_name
          when :constant_read_node, :constant_path_node
            const_to_name!(node) rescue nil
          end
        end

        def symbol_value(node)
          case node.type
          when :symbol_node then node.unescaped.to_sym
          when :string_node then node.unescaped.to_sym
          end
        end

        def build_body_info(body)
          yields = [] #: Array[::Prism::YieldNode]
          has_block_given = false
          returns = [] #: Array[::Prism::ReturnNode]

          if body
            queue = [body]
            while (node = queue.shift)
              if node.is_a?(::Prism::YieldNode)
                yields << node
              elsif node.is_a?(::Prism::ReturnNode)
                returns << node
              elsif node.is_a?(::Prism::CallNode)
                if node.name == :block_given? && node.receiver.nil? && node.arguments.nil?
                  has_block_given = true
                end
              end

              node.each_child_node { |child| queue << child }
            end
          end

          BodyInfo.new(yields: yields, has_block_given: has_block_given, returns: returns.empty? ? nil : returns)
        end

        def function_type(node, body_info)
          params = node.parameters
          return_type =
            if node.name == :initialize
              Types::Bases::Void.new(location: nil)
            else
              return_type_from_body(node.body, returns: body_info.returns)
            end

          fun = Types::Function.empty(return_type)
          return fun unless params

          if params.keyword_rest&.type == :forwarding_parameter_node
            return fun.update(
              rest_positionals: Types::Function::Param.new(name: nil, type: untyped),
              rest_keywords: Types::Function::Param.new(name: nil, type: untyped)
            )
          end

          params.requireds.each do |req| #: Prism::RequiredParameterNode | Prism::MultiTargetNode
            name = req.is_a?(::Prism::RequiredParameterNode) ? req.name : nil
            fun.required_positionals << Types::Function::Param.new(name: name, type: untyped)
          end

          params.optionals.each do |opt|
            fun.optional_positionals << Types::Function::Param.new(
              name: opt.name, type: param_type(opt.value)
            )
          end

          if (rest = params.rest).is_a?(::Prism::RestParameterNode)
            fun = fun.update(rest_positionals: Types::Function::Param.new(name: rest.name, type: untyped))
          end

          params.posts.each do |post| #: Prism::RequiredParameterNode | Prism::MultiTargetNode
            name = post.is_a?(::Prism::RequiredParameterNode) ? post.name : nil
            fun.trailing_positionals << Types::Function::Param.new(name: name, type: untyped)
          end

          params.keywords.each do |kw|
            case kw
            when ::Prism::RequiredKeywordParameterNode
              fun.required_keywords[kw.name] = Types::Function::Param.new(name: nil, type: untyped)
            when ::Prism::OptionalKeywordParameterNode
              fun.optional_keywords[kw.name] = Types::Function::Param.new(name: nil, type: param_type(kw.value))
            end
          end

          if (keyword_rest = params.keyword_rest).is_a?(::Prism::KeywordRestParameterNode)
            fun = fun.update(rest_keywords: Types::Function::Param.new(name: keyword_rest.name, type: untyped))
          end

          fun
        end

        def keyword_hash?(node)
          case node.type
          when :keyword_hash_node, :hash_node
            node.elements.all? { |e| e.type == :assoc_node && e.key.type == :symbol_node }
          else
            false
          end
        end

        def return_type_from_body(body, returns:)
          return Types::Bases::Nil.new(location: nil) unless body

          if body.type == :statements_node && body.body.size == 1
            return return_type_from_body(body.body.first, returns: returns)
          end

          case body.type
          when :if_node, :unless_node
            if_unless_type(body)
          when :statements_node
            statements_type(body, returns: returns)
          else
            literal_to_type(body)
          end
        end

        def if_unless_type(node)
          case node.type
          when :if_node
            true_type = return_type_from_body(node.statements, returns: nil)
            false_type =
              case (subsequent = node.subsequent)&.type
              when :else_node
                return_type_from_body(subsequent.statements, returns: nil)
              when :if_node
                if_unless_type(subsequent)
              else
                Types::Bases::Nil.new(location: nil)
              end

            types_to_union_type([true_type, false_type])
          when :unless_node
            true_type = return_type_from_body(node.statements, returns: nil)
            false_type =
              if (else_clause = node.else_clause)
                return_type_from_body(else_clause.statements, returns: nil)
              else
                Types::Bases::Nil.new(location: nil)
              end

            types_to_union_type([true_type, false_type])
          else
            untyped
          end
        end

        def statements_type(node, returns:)
          return Types::Bases::Nil.new(location: nil) unless node

          return_nodes = returns || node.find_all { |n| n.is_a?(::Prism::ReturnNode) }

          return_types = return_nodes.map do |return_node|
            args = return_node.arguments&.arguments
            if args && !args.empty?
              literal_to_type(args.first)
            else
              Types::Bases::Nil.new(location: nil)
            end
          end

          last_node = node.body.last
          last_evaluated = last_node ? literal_to_type(last_node) : Types::Bases::Nil.new(location: nil)

          types_to_union_type([*return_types, last_evaluated])
        end

        def literal_to_type(node)
          case node.type
          when :string_node
            if (unescaped = node.unescaped).ascii_only?
              Types::Literal.new(literal: unescaped, location: nil)
            else
              BuiltinNames::String.instance_type
            end
          when :interpolated_string_node, :x_string_node, :interpolated_x_string_node
            BuiltinNames::String.instance_type
          when :symbol_node
            if (unescaped = node.unescaped).ascii_only?
              Types::Literal.new(literal: unescaped.to_sym, location: nil)
            else
              BuiltinNames::Symbol.instance_type
            end
          when :interpolated_symbol_node
            BuiltinNames::Symbol.instance_type
          when :regular_expression_node, :interpolated_regular_expression_node
            BuiltinNames::Regexp.instance_type
          when :true_node
            Types::Literal.new(literal: true, location: nil)
          when :false_node
            Types::Literal.new(literal: false, location: nil)
          when :nil_node
            Types::Bases::Nil.new(location: nil)
          when :integer_node
            Types::Literal.new(literal: node.value, location: nil)
          when :float_node
            BuiltinNames::Float.instance_type
          when :rational_node
            Types::ClassInstance.new(name: TypeName.new(name: :Rational, namespace: Namespace.root), args: [], location: nil)
          when :imaginary_node
            Types::ClassInstance.new(name: TypeName.new(name: :Complex, namespace: Namespace.root), args: [], location: nil)
          when :array_node
            if node.elements.empty?
              BuiltinNames::Array.instance_type(untyped)
            else
              BuiltinNames::Array.instance_type(types_to_union_type(node.elements.map { |e| literal_to_type(e) }))
            end
          when :range_node
            types = [node.left, node.right].compact.map { |c| literal_to_type(c) }
            BuiltinNames::Range.instance_type(range_element_type(types))
          when :hash_node
            hash_type(node.elements)
          when :self_node
            Types::Bases::Self.new(location: nil)
          when :call_node
            if node.receiver
              case node.name
              when :freeze, :tap, :itself, :dup, :clone, :taint, :untaint, :extend
                literal_to_type(node.receiver)
              else
                untyped
              end
            else
              untyped
            end
          when :parentheses_node
            node.body ? literal_to_type(node.body) : Types::Bases::Nil.new(location: nil)
          when :statements_node
            node.body.last ? literal_to_type(node.body.last) : Types::Bases::Nil.new(location: nil)
          when :if_node, :unless_node
            if_unless_type(node) || untyped
          else
            untyped
          end
        end

        def hash_type(elements)
          key_types = [] #: Array[Types::t]
          value_types = [] #: Array[Types::t]

          elements.each do |elem|
            case elem.type
            when :assoc_node
              key_types << literal_to_type(elem.key)
              value_types << literal_to_type(elem.value)
            when :assoc_splat_node
              key_types << untyped
              value_types << untyped
            end
          end

          if !key_types.empty? && key_types.all? { |t| t.is_a?(Types::Literal) }
            fields = key_types.map { |t|
              t.is_a?(Types::Literal) or raise
              t.literal
            }.zip(value_types).to_h #: Hash[Types::Literal::literal, Types::t]

            Types::Record.new(fields: fields, location: nil)
          else
            BuiltinNames::Hash.instance_type(types_to_union_type(key_types), types_to_union_type(value_types))
          end
        end

        def param_type(node, default: Types::Bases::Any.new(location: nil))
          case node.type
          when :integer_node
            BuiltinNames::Integer.instance_type
          when :float_node
            BuiltinNames::Float.instance_type
          when :rational_node
            Types::ClassInstance.new(name: TypeName.parse("::Rational"), args: [], location: nil)
          when :imaginary_node
            Types::ClassInstance.new(name: TypeName.parse("::Complex"), args: [], location: nil)
          when :symbol_node
            BuiltinNames::Symbol.instance_type
          when :string_node, :interpolated_string_node
            BuiltinNames::String.instance_type
          when :nil_node
            Types::Optional.new(type: Types::Bases::Any.new(location: nil), location: nil)
          when :true_node, :false_node
            Types::Bases::Bool.new(location: nil)
          when :array_node
            BuiltinNames::Array.instance_type(default)
          when :hash_node
            BuiltinNames::Hash.instance_type(default, default)
          else
            default
          end
        end
      end
    end
  end
end

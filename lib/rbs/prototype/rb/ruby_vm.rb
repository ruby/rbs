# frozen_string_literal: true

module RBS
  module Prototype
    module RB
      class RubyVM < Base
        include RubyVMHelpers

        def parse(string)
          # @type var comments: Hash[Integer, AST::Comment]
          comments = parse_comments(string, include_trailing: false)
          process ::RubyVM::AbstractSyntaxTree.parse(string), decls: source_decls, comments: comments, context: Context.initial
        end

        def process(node, decls:, comments:, context:)
          case node.type
          when :CLASS
            class_name, super_class_node, *class_body = node.children
            super_class_name = const_to_name(super_class_node, context: context)
            super_class =
              if super_class_name
                AST::Declarations::Class::Super.new(name: super_class_name, args: [], location: nil)
              else
                nil
              end
            kls = AST::Declarations::Class.new(
              name: const_to_name!(class_name),
              super_class: super_class,
              type_params: [],
              members: [],
              annotations: [],
              location: nil,
              comment: comments[node.first_lineno - 1]
            )

            decls.push kls

            new_ctx = context.enter_namespace(kls.name.to_namespace)
            each_node class_body do |child|
              process child, decls: kls.members, comments: comments, context: new_ctx
            end
            remove_unnecessary_accessibility_methods! kls.members
            sort_members! kls.members

          when :MODULE
            module_name, *module_body = node.children

            mod = AST::Declarations::Module.new(
              name: const_to_name!(module_name),
              type_params: [],
              self_types: [],
              members: [],
              annotations: [],
              location: nil,
              comment: comments[node.first_lineno - 1]
            )

            decls.push mod

            new_ctx = context.enter_namespace(mod.name.to_namespace)
            each_node module_body do |child|
              process child, decls: mod.members, comments: comments, context: new_ctx
            end
            remove_unnecessary_accessibility_methods! mod.members
            sort_members! mod.members

          when :SCLASS
            this, body = node.children

            if this.type != :SELF
              RBS.logger.warn "`class <<` syntax with not-self may be compiled to incorrect code: #{this}"
            end

            accessibility = current_accessibility(decls)

            ctx = Context.initial.tap { |ctx| ctx.singleton = true }
            process_children(body, decls: decls, comments: comments, context: ctx)

            decls << accessibility

          when :DEFN, :DEFS
            # @type var kind: Context::method_kind

            if node.type == :DEFN
              def_name, def_body = node.children
              kind = context.method_kind
            else
              _, def_name, def_body = node.children
              kind = :singleton
            end

            types = [
              MethodType.new(
                type_params: [],
                type: function_type_from_body(def_body, def_name),
                block: block_from_body(def_body),
                location: nil
              )
            ]

            member = AST::Members::MethodDefinition.new(
              name: def_name,
              location: nil,
              annotations: [],
              overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type )},
              kind: kind,
              comment: comments[node.first_lineno - 1],
              overloading: false,
              visibility: nil
            )

            decls.push member unless decls.include?(member)

            new_ctx = context.update(singleton: kind == :singleton, in_def: true)
            each_node def_body.children do |child|
              process child, decls: decls, comments: comments, context: new_ctx
            end

          when :ALIAS
            new_name, old_name = node.children.map { |c| literal_to_symbol(c) }
            new_name or raise
            old_name or raise
            member = AST::Members::Alias.new(
              new_name: new_name,
              old_name: old_name,
              kind: context.singleton ? :singleton : :instance,
              annotations: [],
              location: nil,
              comment: comments[node.first_lineno - 1],
            )
            decls.push member unless decls.include?(member)

          when :FCALL, :VCALL
            args = node.children[1]&.children || []

            case node.children[0]
            when :include
              args.each do |arg|
                if (name = const_to_name(arg, context: context))
                  klass = context.singleton ? AST::Members::Extend : AST::Members::Include
                  decls << klass.new(
                    name: name, args: [], annotations: [],
                    location: nil, comment: comments[node.first_lineno - 1]
                  )
                end
              end
            when :prepend
              args.each do |arg|
                if (name = const_to_name(arg, context: context))
                  decls << AST::Members::Prepend.new(
                    name: name, args: [], annotations: [],
                    location: nil, comment: comments[node.first_lineno - 1]
                  )
                end
              end
            when :extend
              args.each do |arg|
                if (name = const_to_name(arg, context: context))
                  decls << AST::Members::Extend.new(
                    name: name, args: [], annotations: [],
                    location: nil, comment: comments[node.first_lineno - 1]
                  )
                end
              end
            when :attr_reader
              args.each do |arg|
                if arg && (name = literal_to_symbol(arg))
                  decls << AST::Members::AttrReader.new(
                    name: name, ivar_name: nil,
                    type: Types::Bases::Any.new(location: nil),
                    kind: context.attribute_kind,
                    location: nil, comment: comments[node.first_lineno - 1],
                    annotations: []
                  )
                end
              end
            when :attr_accessor
              args.each do |arg|
                if arg && (name = literal_to_symbol(arg))
                  decls << AST::Members::AttrAccessor.new(
                    name: name, ivar_name: nil,
                    type: Types::Bases::Any.new(location: nil),
                    kind: context.attribute_kind,
                    location: nil, comment: comments[node.first_lineno - 1],
                    annotations: []
                  )
                end
              end
            when :attr_writer
              args.each do |arg|
                if arg && (name = literal_to_symbol(arg))
                  decls << AST::Members::AttrWriter.new(
                    name: name, ivar_name: nil,
                    type: Types::Bases::Any.new(location: nil),
                    kind: context.attribute_kind,
                    location: nil, comment: comments[node.first_lineno - 1],
                    annotations: []
                  )
                end
              end
            when :alias_method
              if args[0] && args[1] && (new_name = literal_to_symbol(args[0])) && (old_name = literal_to_symbol(args[1]))
                decls << AST::Members::Alias.new(
                  new_name: new_name, old_name: old_name,
                  kind: context.singleton ? :singleton : :instance,
                  annotations: [], location: nil,
                  comment: comments[node.first_lineno - 1],
                )
              end
            when :module_function
              if args.empty?
                context.module_function = true
              else
                module_func_context = context.update(module_function: true)
                args.each do |arg|
                  if arg && (name = literal_to_symbol(arg))
                    if (i, defn = find_def_index_by_name(decls, name))
                      if defn.is_a?(AST::Members::MethodDefinition)
                        decls[i] = defn.update(kind: :singleton_instance)
                      end
                    end
                  elsif arg
                    process arg, decls: decls, comments: comments, context: module_func_context
                  end
                end
              end
            when :public, :private
              accessibility = __send__(node.children[0])
              if args.empty?
                decls << accessibility
              else
                args.each do |arg|
                  if arg && (name = literal_to_symbol(arg))
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
                process_children(node, decls: decls, comments: comments, context: context)
                decls << current
              end
            else
              process_children(node, decls: decls, comments: comments, context: context)
            end

          when :ITER
            # ignore

          when :CDECL
            const_name = case
                         when node.children[0].is_a?(Symbol)
                           TypeName.new(name: node.children[0], namespace: Namespace.empty)
                         else
                           const_to_name!(node.children[0], context: context)
                         end

            value_node = node.children.last
            type = if value_node.nil? || value_node.type == :SELF
                    Types::Bases::Any.new(location: nil)
                  else
                    literal_to_type(value_node)
                  end
            decls << AST::Declarations::Constant.new(
              name: const_name, type: type, location: nil,
              comment: comments[node.first_lineno - 1],
              annotations: []
            )

          when :IASGN
            case [context.singleton, context.in_def]
            when [true, true], [false, false]
              member = AST::Members::ClassInstanceVariable.new(
                name: node.children.first,
                type: Types::Bases::Any.new(location: nil),
                location: nil, comment: comments[node.first_lineno - 1]
              )
            when [false, true]
              member = AST::Members::InstanceVariable.new(
                name: node.children.first,
                type: Types::Bases::Any.new(location: nil),
                location: nil, comment: comments[node.first_lineno - 1]
              )
            when [true, false]
              # Singleton class ivar - RBS can't represent it
            else
              raise 'unreachable'
            end

            decls.push member if member && !decls.include?(member)

          when :CVASGN
            member = AST::Members::ClassVariable.new(
              name: node.children.first,
              type: Types::Bases::Any.new(location: nil),
              location: nil, comment: comments[node.first_lineno - 1]
            )
            decls.push member unless decls.include?(member)
          else
            process_children(node, decls: decls, comments: comments, context: context)
          end
        end

        def process_children(node, decls:, comments:, context:)
          each_child node do |child|
            process child, decls: decls, comments: comments, context: context
          end
        end

        def const_to_name!(node, context: nil)
          case node.type
          when :CONST
            TypeName.new(name: node.children[0], namespace: Namespace.empty)
          when :COLON2
            if node.children[0]
              namespace = const_to_name!(node.children[0], context: context).to_namespace
            else
              namespace = Namespace.empty
            end
            TypeName.new(name: node.children[1], namespace: namespace)
          when :COLON3
            TypeName.new(name: node.children[0], namespace: Namespace.root)
          when :SELF
            raise if context.nil?
            context.namespace.to_type_name
          else
            raise
          end
        end

        def const_to_name(node, context:)
          if node
            case node.type
            when :SELF
              context.namespace.to_type_name
            when :CONST, :COLON2, :COLON3
              const_to_name!(node) rescue nil
            end
          end
        end

        def literal_to_symbol(node)
          case node.type
          when :SYM
            node.children[0]
          when :LIT
            node.children[0] if node.children[0].is_a?(Symbol)
          when :STR
            node.children[0].to_sym
          end
        end

        def function_type_from_body(node, def_name)
          table_node, args_node, *_ = node.children

          pre_num, _pre_init, opt, _first_post, post_num, _post_init, rest, kw, kwrest, _block = args_from_node(args_node)

          return_type = if def_name == :initialize
                          Types::Bases::Void.new(location: nil)
                        else
                          function_return_type_from_body(node)
                        end

          fun = Types::Function.empty(return_type)

          table_node.take(pre_num).each do |name|
            fun.required_positionals << Types::Function::Param.new(name: name, type: untyped)
          end

          while opt&.type == :OPT_ARG
            lvasgn, opt = opt.children
            name = lvasgn.children[0]
            fun.optional_positionals << Types::Function::Param.new(
              name: name,
              type: param_type(lvasgn.children[1])
            )
          end

          if rest
            rest_name = rest == :* ? nil : rest
            fun = fun.update(rest_positionals: Types::Function::Param.new(name: rest_name, type: untyped))
          end

          table_node.drop(fun.required_positionals.size + fun.optional_positionals.size + (fun.rest_positionals ? 1 : 0)).take(post_num).each do |name|
            fun.trailing_positionals << Types::Function::Param.new(name: name, type: untyped)
          end

          while kw
            lvasgn, kw = kw.children
            name, value = lvasgn.children

            case value
            when nil, :NODE_SPECIAL_REQUIRED_KEYWORD
              fun.required_keywords[name] = Types::Function::Param.new(name: nil, type: untyped)
            when ::RubyVM::AbstractSyntaxTree::Node
              fun.optional_keywords[name] = Types::Function::Param.new(name: nil, type: param_type(value))
            else
              raise "Unexpected keyword arg value: #{value}"
            end
          end

          if kwrest && kwrest.children.any?
            kwrest_name = kwrest.children[0] #: Symbol?
            kwrest_name = nil if kwrest_name == :**
            fun = fun.update(rest_keywords: Types::Function::Param.new(name: kwrest_name, type: untyped))
          end

          fun
        end

        def function_return_type_from_body(node)
          body = node.children[2]
          body_type(body)
        end

        def body_type(node)
          return Types::Bases::Nil.new(location: nil) unless node

          case node.type
          when :IF, :UNLESS
            if_unless_type(node)
          when :BLOCK
            block_type(node)
          else
            literal_to_type(node)
          end
        end

        def if_unless_type(node)
          raise unless node.type == :IF || node.type == :UNLESS

          _exp_node, true_node, false_node = node.children
          types_to_union_type([body_type(true_node), body_type(false_node)])
        end

        def block_type(node)
          raise unless node.type == :BLOCK

          return_stmts = any_node?(node) do |n|
            n.type == :RETURN
          end&.map do |return_node|
            returned_value = return_node.children[0]
            returned_value ? literal_to_type(returned_value) : Types::Bases::Nil.new(location: nil)
          end || []
          last_node = node.children.last
          last_evaluated = last_node ? literal_to_type(last_node) : Types::Bases::Nil.new(location: nil)
          types_to_union_type([*return_stmts, last_evaluated])
        end

        def literal_to_type(node)
          case node.type
          when :STR
            lit = node.children[0]
            if lit.ascii_only?
              Types::Literal.new(literal: lit, location: nil)
            else
              BuiltinNames::String.instance_type
            end
          when :DSTR, :XSTR
            BuiltinNames::String.instance_type
          when :SYM
            lit = node.children[0]
            if lit.to_s.ascii_only?
              Types::Literal.new(literal: lit, location: nil)
            else
              BuiltinNames::Symbol.instance_type
            end
          when :DSYM
            BuiltinNames::Symbol.instance_type
          when :DREGX, :REGX
            BuiltinNames::Regexp.instance_type
          when :TRUE
            Types::Literal.new(literal: true, location: nil)
          when :FALSE
            Types::Literal.new(literal: false, location: nil)
          when :NIL
            Types::Bases::Nil.new(location: nil)
          when :INTEGER
            Types::Literal.new(literal: node.children[0], location: nil)
          when :FLOAT
            BuiltinNames::Float.instance_type
          when :RATIONAL, :IMAGINARY
            lit = node.children[0]
            type_name = TypeName.new(name: lit.class.name.to_sym, namespace: Namespace.root)
            Types::ClassInstance.new(name: type_name, args: [], location: nil)
          when :LIT
            lit = node.children[0]
            case lit
            when Symbol
              if lit.to_s.ascii_only?
                Types::Literal.new(literal: lit, location: nil)
              else
                BuiltinNames::Symbol.instance_type
              end
            when Integer
              Types::Literal.new(literal: lit, location: nil)
            when String
              Types::Literal.new(literal: lit, location: nil)
            else
              type_name = TypeName.new(name: lit.class.name.to_sym, namespace: Namespace.root)
              Types::ClassInstance.new(name: type_name, args: [], location: nil)
            end
          when :ZLIST, :ZARRAY
            BuiltinNames::Array.instance_type(untyped)
          when :LIST, :ARRAY
            elem_types = node.children.compact.map { |e| literal_to_type(e) }
            t = types_to_union_type(elem_types)
            BuiltinNames::Array.instance_type(t)
          when :DOT2, :DOT3
            types = node.children.map { |c| literal_to_type(c) }
            type = range_element_type(types)
            BuiltinNames::Range.instance_type(type)
          when :HASH
            list = node.children[0]
            if list
              children = list.children
              children.pop
            else
              children = [] #: Array[untyped]
            end

            key_types = [] #: Array[Types::t]
            value_types = [] #: Array[Types::t]
            children.each_slice(2) do |k, v|
              if k
                key_types << literal_to_type(k)
                value_types << literal_to_type(v)
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
          when :SELF
            Types::Bases::Self.new(location: nil)
          when :CALL
            receiver, method_name, * = node.children
            case method_name
            when :freeze, :tap, :itself, :dup, :clone, :taint, :untaint, :extend
              literal_to_type(receiver)
            else
              untyped
            end
          else
            untyped
          end
        end

        def param_type(node, default: Types::Bases::Any.new(location: nil))
          case node.type
          when :INTEGER
            BuiltinNames::Integer.instance_type
          when :FLOAT
            BuiltinNames::Float.instance_type
          when :RATIONAL
            Types::ClassInstance.new(name: TypeName.parse("::Rational"), args: [], location: nil)
          when :IMAGINARY
            Types::ClassInstance.new(name: TypeName.parse("::Complex"), args: [], location: nil)
          when :LIT
            case node.children[0]
            when Symbol
              BuiltinNames::Symbol.instance_type
            when Integer
              BuiltinNames::Integer.instance_type
            when Float
              BuiltinNames::Float.instance_type
            else
              default
            end
          when :SYM
            BuiltinNames::Symbol.instance_type
          when :STR, :DSTR
            BuiltinNames::String.instance_type
          when :NIL
            Types::Optional.new(
              type: Types::Bases::Any.new(location: nil),
              location: nil
            )
          when :TRUE, :FALSE
            Types::Bases::Bool.new(location: nil)
          when :ARRAY, :LIST
            BuiltinNames::Array.instance_type(default)
          when :HASH
            BuiltinNames::Hash.instance_type(default, default)
          else
            default
          end
        end
      end
    end
  end
end

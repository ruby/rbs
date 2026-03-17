# frozen_string_literal: true

module RBS
  module Prototype
    module RBI
      class Prism < Base
        def parse(string)
          result = ::Prism.parse(string)
          comments = build_comments_prism(result.comments, include_trailing: true)
          process result.value, comments: comments
        end

        def process(node, outer: [], comments:)
          case node.type
          when :program_node
            process(node.statements, outer: outer, comments: comments)
          when :statements_node
            node.body.each do |child|
              process(child, outer: outer + [node], comments: comments)
            end
          when :begin_node
            if node.statements
              process(node.statements, outer: outer + [node], comments: comments)
            end
          when :class_node
            comment = comments[node.location.start_line - 1]
            push_class(node.constant_path, node.superclass, comment: comment) do
              if node.body
                process(node.body, outer: outer + [node], comments: comments)
              end
            end
          when :module_node
            comment = comments[node.location.start_line - 1]
            push_module(node.constant_path, comment: comment) do
              if node.body
                process(node.body, outer: outer + [node], comments: comments)
              end
            end
          when :call_node
            if node.receiver.nil? && node.block.nil?
              handle_fcall(node, outer: outer, comments: comments)
            elsif node.receiver.nil? && node.block
              if node.name == :sig
                handle_sig(node)
              else
                if node.block.is_a?(::Prism::BlockNode) && node.block.body
                  process(node.block.body, outer: outer + [node], comments: comments)
                end
              end
            else
              node.each_child_node do |child|
                process(child, outer: outer + [node], comments: comments)
              end
            end
          when :def_node
            sigs = pop_sig

            if sigs
              comment = join_comments(sigs, comments)
              kind = node.receiver ? :singleton : :instance #: AST::Members::MethodDefinition::kind
              types = sigs.map { |sig| method_type(node, sig, variables: current_module!.type_params, overloads: sigs.size) }.compact

              current_module!.members << AST::Members::MethodDefinition.new(
                name: node.name,
                location: nil,
                annotations: [],
                overloads: types.map { |type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
                kind: kind,
                comment: comment,
                overloading: false,
                visibility: nil
              )
            end
          when :constant_write_node
            handle_cdecl(node)
          when :multi_write_node
            node.lefts.each do |target|
              if target.type == :constant_target_node
                name =
                  if current_module
                    TypeName.new(namespace: current_namespace, name: target.name)
                  else
                    TypeName.new(namespace: Namespace.empty, name: target.name)
                  end

                decls << AST::Declarations::Constant.new(
                  name: name, type: Types::Bases::Any.new(location: nil),
                  location: nil, comment: nil, annotations: []
                )
              end
            end
          when :alias_method_node
            current_module!.members << AST::Members::Alias.new(
              new_name: node.new_name.unescaped.to_sym,
              old_name: node.old_name.unescaped.to_sym,
              location: nil,
              annotations: [],
              kind: :instance,
              comment: nil
            )
          else
            node.each_child_node do |child|
              process(child, outer: outer + [node], comments: comments)
            end
          end
        end

        private

        def handle_fcall(node, outer:, comments:)
          args = node.arguments&.arguments || []

          case node.name
          when :include
            args.each do |arg|
              case arg.type
              when :constant_read_node, :constant_path_node
                name = const_to_name(arg)
                current_module!.members << AST::Members::Include.new(
                  name: name, args: [], annotations: [],
                  location: nil, comment: nil
                )
              end
            end
          when :extend
            args.each do |arg|
              case arg.type
              when :constant_read_node, :constant_path_node
                name = const_to_name(arg)
                unless name.to_s == "T::Generic" || name.to_s == "T::Sig"
                  current_module!.members << AST::Members::Extend.new(
                    name: name, args: [], annotations: [],
                    location: nil, comment: nil
                  )
                end
              end
            end
          when :alias_method
            if args.size >= 2
              new_name = symbol_value(args[0])
              old_name = symbol_value(args[1])
              if new_name && old_name
                current_module!.members << AST::Members::Alias.new(
                  new_name: new_name, old_name: old_name,
                  location: nil, annotations: [],
                  kind: :instance, comment: nil
                )
              end
            end
          end
        end

        def handle_sig(node)
          block = node.block
          return unless block.is_a?(::Prism::BlockNode)

          body = block.body
          return unless body

          sig_chain = body.is_a?(::Prism::StatementsNode) ? body.body.last : body
          push_sig(sig_chain) if sig_chain
        end

        def join_comments(sig_nodes, comments)
          cs = sig_nodes.map { |node| comments[node.location.start_line - 1] }.compact
          AST::Comment.new(string: cs.map(&:string).join("\n"), location: nil)
        end

        def method_type(def_node, sig_node, variables:, overloads:)
          return nil unless sig_node

          method_type = MethodType.new(
            type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
            block: nil,
            location: nil,
            type_params: []
          )

          walk_sig_chain(def_node, sig_node, method_type, variables: variables, overloads: overloads)
        end

        # Walk a sig chain recursively. The chain looks like:
        #   returns(String)           - call_node name=returns, receiver=nil
        #   params(x: T).returns(Y)   - call_node name=returns, receiver=call_node(name=params)
        def walk_sig_chain(def_node, node, method_type, variables:, overloads:)
          return method_type unless node

          case node.type
          when :call_node
            if node.receiver&.type == :call_node
              method_type = walk_sig_chain(def_node, node.receiver, method_type, variables: variables, overloads: overloads)
            end

            args = node.arguments&.arguments || []

            case node.name
            when :returns
              if args[0]
                return_type = type_of(args[0], variables: variables)
                method_type = method_type.update(type: method_type.type.with_return_type(return_type))
              end
            when :params
              if def_node
                method_type = parse_params(def_node, args, method_type, variables: variables, overloads: overloads)
              else
                hash = args_to_hash(args[0], variables: variables)
                required_positionals = hash.map do |name, type|
                  Types::Function::Param.new(name: name, type: type)
                end
                if method_type.type.is_a?(RBS::Types::Function)
                  method_type = method_type.update(type: method_type.type.update(required_positionals: required_positionals))
                end
              end
            when :type_parameters
              type_params = args.filter_map do |arg|
                if (name = symbol_value(arg))
                  AST::TypeParam.new(
                    name: name, variance: :invariant,
                    upper_bound: nil, lower_bound: nil,
                    location: nil, default_type: nil
                  )
                end
              end
              method_type = method_type.update(type_params: type_params)
            when :void
              method_type = method_type.update(type: method_type.type.with_return_type(Types::Bases::Void.new(location: nil)))
            when :proc
              # T.proc - continue, the chain will fill in params/returns
            end
          end

          method_type
        end

        def parse_params(def_node, sig_args, method_type, variables:, overloads:)
          vars = args_to_hash(sig_args[0], variables: variables)
          params = def_node.parameters

          required_positionals = [] #: Array[Types::Function::Param]
          optional_positionals = [] #: Array[Types::Function::Param]
          rest_positionals = nil #: Types::Function::Param | nil
          trailing_positionals = [] #: Array[Types::Function::Param]
          required_keywords = {} #: Hash[Symbol, Types::Function::Param]
          optional_keywords = {} #: Hash[Symbol, Types::Function::Param]
          rest_keywords = nil #: Types::Function::Param | nil
          method_block = nil #: Types::Block | nil

          if params
            params.requireds.each do |req| #: Prism::RequiredParameterNode | Prism::MultiTargetNode
              name = req.is_a?(::Prism::RequiredParameterNode) ? req.name : nil
              type = (name && vars[name]) || Types::Bases::Any.new(location: nil)
              required_positionals << Types::Function::Param.new(type: type, name: name)
            end

            params.optionals.each do |opt|
              type = vars[opt.name]
              if type
                optional_positionals << Types::Function::Param.new(type: type, name: opt.name)
              end
            end

            if (rest = params.rest).is_a?(::Prism::RestParameterNode) && (rest_name = rest.name)
              if (type = vars[rest_name])
                rest_positionals = Types::Function::Param.new(type: type, name: rest_name)
              end
            end

            params.posts.each do |post| #: Prism::RequiredParameterNode | Prism::MultiTargetNode
              name = post.is_a?(::Prism::RequiredParameterNode) ? post.name : nil
              if name && (type = vars[name])
                trailing_positionals << Types::Function::Param.new(type: type, name: name)
              end
            end

            params.keywords.each do |kw|
              case kw.type
              when :required_keyword_parameter_node
                if (type = vars[kw.name])
                  required_keywords[kw.name] = Types::Function::Param.new(type: type, name: kw.name)
                end
              when :optional_keyword_parameter_node
                if (type = vars[kw.name])
                  optional_keywords[kw.name] = Types::Function::Param.new(type: type, name: kw.name)
                end
              end
            end

            if (keyword_rest = params.keyword_rest).is_a?(::Prism::KeywordRestParameterNode) && (kw_rest_name = keyword_rest.name)
              if (type = vars[kw_rest_name])
                rest_keywords = Types::Function::Param.new(type: type, name: kw_rest_name)
              end
            end

            if (block_param = params.block).is_a?(::Prism::BlockParameterNode)
              block_name = block_param.name
              if block_name && (type = vars[block_name])
                if type.is_a?(Types::Proc)
                  method_block = Types::Block.new(required: true, type: type.type, self_type: nil)
                elsif type.is_a?(Types::Bases::Any)
                  method_block = Types::Block.new(
                    required: true,
                    type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                    self_type: nil
                  )
                elsif type.is_a?(Types::Optional) && (proc_type = type.type).is_a?(Types::Proc)
                  method_block = Types::Block.new(required: false, type: proc_type.type, self_type: nil)
                else
                  STDERR.puts "Unexpected block type: #{type}"
                  method_block = Types::Block.new(
                    required: true,
                    type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                    self_type: nil
                  )
                end
              elsif overloads == 1
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

        def args_to_hash(node, variables:)
          return {} unless node #: Hash[Symbol, Types::t]

          case node.type
          when :keyword_hash_node, :hash_node
            hash = {} #: Hash[Symbol, Types::t]
            node.elements.each do |elem|
              if elem.is_a?(::Prism::AssocNode) && (name = symbol_value(elem.key))
                hash[name] = type_of(elem.value, variables: variables)
              end
            end
            hash
          else
            {}
          end
        end

        def type_of(node, variables:)
          type = type_of0(node, variables: variables)

          case
          when type.is_a?(Types::ClassInstance) && type.name.name == BuiltinNames::BasicObject.name.name
            Types::Bases::Any.new(location: nil)
          when type.is_a?(Types::ClassInstance) && type.name.to_s == "T::Boolean"
            Types::Bases::Bool.new(location: nil)
          else
            type
          end
        end

        def type_of0(node, variables:)
          case node.type
          when :constant_read_node
            if variables.any? { |tp| tp.name == node.name }
              Types::Variable.new(name: node.name, location: nil)
            else
              Types::ClassInstance.new(name: const_to_name(node), args: [], location: nil)
            end

          when :constant_path_node
            Types::ClassInstance.new(name: const_to_name(node), args: [], location: nil)

          when :call_node
            if t_call?(node)
              handle_t_call(node, variables: variables)
            elsif node.name == :[] && node.receiver
              type = type_of(node.receiver, variables: variables)
              type.is_a?(Types::ClassInstance) or raise

              (node.arguments&.arguments || []).each do |arg|
                type.args << type_of(arg, variables: variables)
              end

              type
            elsif proc_type?(node)
              mt = walk_sig_chain(nil, node, MethodType.new(
                type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                block: nil, location: nil, type_params: []
              ), variables: variables, overloads: 1)
              Types::Proc.new(type: mt.type, block: nil, location: nil, self_type: nil)
            else
              STDERR.puts "Unexpected type_node:"
              PP.pp node, STDERR
              Types::Bases::Any.new(location: nil)
            end

          when :array_node
            types = node.elements.map { |e| type_of(e, variables: variables) }
            Types::Tuple.new(types: types, location: nil)

          else
            STDERR.puts "Unexpected type_node:"
            PP.pp node, STDERR
            Types::Bases::Any.new(location: nil)
          end
        end

        def t_call?(node)
          node.type == :call_node && node.receiver&.type == :constant_read_node && node.receiver.name == :T
        end

        def handle_t_call(node, variables:)
          args = node.arguments&.arguments || []

          case node.name
          when :any
            types = args.map { |a| type_of(a, variables: variables) }
            Types::Union.new(types: types, location: nil)
          when :all
            types = args.map { |a| type_of(a, variables: variables) }
            Types::Intersection.new(types: types, location: nil)
          when :untyped
            Types::Bases::Any.new(location: nil)
          when :nilable
            type = type_of(args[0], variables: variables)
            Types::Optional.new(type: type, location: nil)
          when :self_type
            Types::Bases::Self.new(location: nil)
          when :attached_class
            Types::Bases::Instance.new(location: nil)
          when :noreturn
            Types::Bases::Bottom.new(location: nil)
          when :class_of
            type = type_of(args[0], variables: variables)
            if type.is_a?(Types::ClassInstance)
              Types::ClassSingleton.new(name: type.name, location: nil)
            else
              STDERR.puts "Unexpected type for `class_of`: #{type}"
              Types::Bases::Any.new(location: nil)
            end
          when :type_parameter
            name = symbol_value(args[0])
            Types::Variable.new(name: name || raise, location: nil)
          when :proc
            mt = walk_sig_chain(nil, node, MethodType.new(
              type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
              block: nil, location: nil, type_params: []
            ), variables: variables, overloads: 1)
            Types::Proc.new(type: mt.type, block: nil, location: nil, self_type: nil)
          else
            Types::Bases::Any.new(location: nil)
          end
        end

        def proc_type?(node)
          return true if t_call?(node) && node.name == :proc
          node.type == :call_node && node.receiver && proc_type?(node.receiver)
        end

        def handle_cdecl(node)
          value = node.value

          if value.is_a?(::Prism::CallNode) && value.receiver.nil? && value.name == :type_member
            args = value.arguments&.arguments || []
            has_fixed =
              args.any? do |a|
                (a.is_a?(::Prism::KeywordHashNode) || a.is_a?(::Prism::HashNode)) &&
                  a.elements.any? { |e| e.is_a?(::Prism::AssocNode) && symbol_value(e.key) == :fixed }
              end

            unless has_fixed
              variance = :invariant #: AST::TypeParam::variance
              if args[0] && (v = symbol_value(args[0]))
                variance =
                  case v
                  when :out then :covariant #: AST::TypeParam::variance
                  when :in then :contravariant #: AST::TypeParam::variance
                  else :invariant #: AST::TypeParam::variance
                  end
              end

              current_module!.type_params << AST::TypeParam.new(
                name: node.name,
                variance: variance,
                location: nil,
                upper_bound: nil,
                lower_bound: nil,
                default_type: nil
              )
            end
          else
            const_name = TypeName.new(namespace: current_namespace, name: node.name)

            type =
              if value.is_a?(::Prism::CallNode) && (recv = value.receiver).is_a?(::Prism::ConstantReadNode) &&
                recv.name == :T && value.name == :let
                type_arg = value.arguments&.arguments&.[](1)
                if type_arg
                  type_of(type_arg, variables: current_module&.type_params || [])
                else
                  Types::Bases::Any.new(location: nil)
                end
              else
                Types::Bases::Any.new(location: nil)
              end

            decls << AST::Declarations::Constant.new(
              name: const_name, type: type,
              location: nil, comment: nil, annotations: []
            )
          end
        end

        def const_to_name(node)
          case node.type
          when :constant_read_node
            TypeName.new(name: node.name, namespace: Namespace.empty)
          when :constant_path_node
            if node.parent.nil?
              TypeName.new(name: node.name || raise, namespace: Namespace.root)
            else
              namespace = const_to_name(node.parent).to_namespace
              type_name = TypeName.new(name: node.name || raise, namespace: namespace)

              case type_name.to_s
              when "T::Array" then BuiltinNames::Array.name
              when "T::Hash" then BuiltinNames::Hash.name
              when "T::Range" then BuiltinNames::Range.name
              when "T::Enumerator" then BuiltinNames::Enumerator.name
              when "T::Enumerable" then BuiltinNames::Enumerable.name
              when "T::Set" then BuiltinNames::Set.name
              else type_name
              end
            end
          else
            raise "Unexpected node type for const: #{node.type}"
          end
        end

        def symbol_value(node)
          node.unescaped.to_sym if node.is_a?(::Prism::SymbolNode)
        end
      end
    end
  end
end

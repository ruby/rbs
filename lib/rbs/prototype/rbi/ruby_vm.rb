# frozen_string_literal: true

module RBS
  module Prototype
    module RBI
      class RubyVM < Base
        include RubyVMHelpers

        def parse(string)
          comments = parse_comments(string, include_trailing: true)
          process ::RubyVM::AbstractSyntaxTree.parse(string), comments: comments
        end

        def join_comments(nodes, comments)
          cs = nodes.map {|node| comments[node.first_lineno - 1] }.compact
          AST::Comment.new(string: cs.map(&:string).join("\n"), location: nil)
        end

        def process(node, outer: [], comments:)
          case node.type
          when :CLASS
            comment = comments[node.first_lineno - 1]
            push_class node.children[0], node.children[1], comment: comment do
              process node.children[2], outer: outer + [node], comments: comments
            end
          when :MODULE
            comment = comments[node.first_lineno - 1]
            push_module node.children[0], comment: comment do
              process node.children[1], outer: outer + [node], comments: comments
            end
          when :FCALL
            case node.children[0]
            when :include
              each_arg node.children[1] do |arg|
                if arg.type == :CONST || arg.type == :COLON2 || arg.type == :COLON3
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
              each_arg node.children[1] do |arg|
                if arg.type == :CONST || arg.type == :COLON2
                  name = const_to_name(arg)
                  unless name.to_s == "T::Generic" || name.to_s == "T::Sig"
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
              out = outer.last or raise
              push_sig out.children.last.children.last
            when :alias_method
              new, old = each_arg(node.children[1]).map {|x| x.children[0] }
              current_module!.members << AST::Members::Alias.new(
                new_name: new,
                old_name: old,
                location: nil,
                annotations: [],
                kind: :instance,
                comment: nil
              )
            end
          when :DEFS
            sigs = pop_sig

            if sigs
              comment = join_comments(sigs, comments)

              args = node.children[2]
              types = sigs.map {|sig| method_type(args, sig, variables: current_module!.type_params, overloads: sigs.size) }.compact

              current_module!.members << AST::Members::MethodDefinition.new(
                name: node.children[1],
                location: nil,
                annotations: [],
                overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
                kind: :singleton,
                comment: comment,
                overloading: false,
                visibility: nil
              )
            end

          when :DEFN
            sigs = pop_sig

            if sigs
              comment = join_comments(sigs, comments)

              args = node.children[1]
              types = sigs.map {|sig| method_type(args, sig, variables: current_module!.type_params, overloads: sigs.size) }.compact

              current_module!.members << AST::Members::MethodDefinition.new(
                name: node.children[0],
                location: nil,
                annotations: [],
                overloads: types.map {|type| AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: type) },
                kind: :instance,
                comment: comment,
                overloading: false,
                visibility: nil
              )
            end

          when :CDECL
            if (send = node.children.last) && send.type == :FCALL && send.children[0] == :type_member
              unless each_arg(send.children[1]).any? {|node|
                node.type == :HASH &&
                  each_arg(node.children[0]).each_slice(2).any? {|a, _| symbol_literal_node?(a) == :fixed }
              }
                # @type var variance: AST::TypeParam::variance?
                if (a0 = each_arg(send.children[1]).to_a[0]) && (v = symbol_literal_node?(a0))
                  variance = case v
                             when :out
                               :covariant
                             when :in
                               :contravariant
                             end
                end

                current_module!.type_params << AST::TypeParam.new(
                  name: node.children[0],
                  variance: variance || :invariant,
                  location: nil,
                  upper_bound: nil,
                  lower_bound: nil,
                  default_type: nil
                )
              end
            else
              name = node.children[0].yield_self do |n|
                if n.is_a?(Symbol)
                  TypeName.new(namespace: current_namespace, name: n)
                else
                  const_to_name(n)
                end
              end
              value_node = node.children.last
              type = if value_node && value_node.type == :CALL && value_node.children[1] == :let
                       type_node = each_arg(value_node.children[2]).to_a[1]
                       type_of type_node, variables: current_module&.type_params || []
                     else
                       Types::Bases::Any.new(location: nil)
                     end
              decls << AST::Declarations::Constant.new(
                name: name,
                type: type,
                location: nil,
                comment: nil,
                annotations: []
              )
            end
          when :ALIAS
            current_module!.members << AST::Members::Alias.new(
              new_name: node.children[0].children[0],
              old_name: node.children[1].children[0],
              location: nil,
              annotations: [],
              kind: :instance,
              comment: nil
            )
          else
            each_child node do |child|
              process child, outer: outer + [node], comments: comments
            end
          end
        end

        def method_type(args_node, type_node, variables:, overloads:)
          if type_node
            if type_node.type == :CALL
              method_type = method_type(args_node, type_node.children[0], variables: variables, overloads: overloads) or raise
            else
              method_type = MethodType.new(
                type: Types::Function.empty(Types::Bases::Any.new(location: nil)),
                block: nil,
                location: nil,
                type_params: []
              )
            end

            name, args = case type_node.type
                         when :CALL
                           [
                             type_node.children[1],
                             type_node.children[2]
                           ]
                         when :FCALL, :VCALL
                           [
                             type_node.children[0],
                             type_node.children[1]
                           ]
                         end

            case name
            when :returns
              return_type = each_arg(args).to_a[0]
              method_type.update(type: method_type.type.with_return_type(type_of(return_type, variables: variables)))
            when :params
              if args_node
                parse_params(args_node, args, method_type, variables: variables, overloads: overloads)
              else
                vars = (node_to_hash(each_arg(args).to_a[0]) || {}).transform_values {|value| type_of(value, variables: variables) }

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

              each_arg args do |node|
                if name = symbol_literal_node?(node)
                  type_params << AST::TypeParam.new(
                    name: name,
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

        def parse_params(args_node, args, method_type, variables:, overloads:)
          vars = (node_to_hash(each_arg(args).to_a[0]) || {}).transform_values {|value| type_of(value, variables: variables) }

          required_positionals = [] #: Array[Types::Function::Param]
          optional_positionals = [] #: Array[Types::Function::Param]
          rest_positionals = nil #: Types::Function::Param | nil
          trailing_positionals = [] #: Array[Types::Function::Param]
          required_keywords = {} #: Hash[Symbol, Types::Function::Param]
          optional_keywords = {} #: Hash[Symbol, Types::Function::Param]
          rest_keywords = nil #: Types::Function::Param | nil

          var_names = args_node.children[0]
          pre_num, _pre_init, opt, _first_post, post_num, _post_init, rest, kw, kwrest, block = args_node.children[1].children

          pre_num.times.each do |i|
            name = var_names[i]
            type = vars[name] || Types::Bases::Any.new(location: nil)
            required_positionals << Types::Function::Param.new(type: type, name: name)
          end

          index = pre_num
          while opt
            name = var_names[index]
            if (type = vars[name])
              optional_positionals << Types::Function::Param.new(type: type, name: name)
            end
            index += 1
            opt = opt.children[1]
          end

          if rest
            name = var_names[index]
            if (type = vars[name])
              rest_positionals = Types::Function::Param.new(type: type, name: name)
            end
            index += 1
          end

          post_num.times do |i|
            name = var_names[i+index]
            if (type = vars[name])
              trailing_positionals << Types::Function::Param.new(type: type, name: name)
            end
            index += 1
          end

          while kw
            name, value = kw.children[0].children
            if (type = vars[name])
              if value
                optional_keywords[name] = Types::Function::Param.new(type: type, name: name)
              else
                required_keywords[name] = Types::Function::Param.new(type: type, name: name)
              end
            end

            kw = kw.children[1]
          end

          if kwrest
            name = kwrest.children[0]
            if (type = vars[name])
              rest_keywords = Types::Function::Param.new(type: type, name: name)
            end
          end

          method_block = nil
          if block
            if (type = vars[block])
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

        def type_of(type_node, variables:)
          type = type_of0(type_node, variables: variables)

          case
          when type.is_a?(Types::ClassInstance) && type.name.name == BuiltinNames::BasicObject.name.name
            Types::Bases::Any.new(location: nil)
          when type.is_a?(Types::ClassInstance) && type.name.to_s == "T::Boolean"
            Types::Bases::Bool.new(location: nil)
          else
            type
          end
        end

        def type_of0(type_node, variables:)
          case
          when type_node.type == :CONST
            if variables.include?(type_node.children[0])
              Types::Variable.new(name: type_node.children[0], location: nil)
            else
              Types::ClassInstance.new(name: const_to_name(type_node), args: [], location: nil)
            end
          when type_node.type == :COLON2 || type_node.type == :COLON3
            Types::ClassInstance.new(name: const_to_name(type_node), args: [], location: nil)
          when call_node?(type_node, name: :[], receiver: -> (_) { true })
            type = type_of(type_node.children[0], variables: variables)
            type.is_a?(Types::ClassInstance) or raise

            each_arg(type_node.children[2]) do |arg|
              type.args << type_of(arg, variables: variables)
            end

            type
          when call_node?(type_node, name: :type_parameter)
            name = each_arg(type_node.children[2]).to_a[0].children[0]
            Types::Variable.new(name: name, location: nil)
          when call_node?(type_node, name: :any)
            types = each_arg(type_node.children[2]).to_a.map {|node| type_of(node, variables: variables) }
            Types::Union.new(types: types, location: nil)
          when call_node?(type_node, name: :all)
            types = each_arg(type_node.children[2]).to_a.map {|node| type_of(node, variables: variables) }
            Types::Intersection.new(types: types, location: nil)
          when call_node?(type_node, name: :untyped)
            Types::Bases::Any.new(location: nil)
          when call_node?(type_node, name: :nilable)
            type = type_of each_arg(type_node.children[2]).to_a[0], variables: variables
            Types::Optional.new(type: type, location: nil)
          when call_node?(type_node, name: :self_type)
            Types::Bases::Self.new(location: nil)
          when call_node?(type_node, name: :attached_class)
            Types::Bases::Instance.new(location: nil)
          when call_node?(type_node, name: :noreturn)
            Types::Bases::Bottom.new(location: nil)
          when call_node?(type_node, name: :class_of)
            type = type_of each_arg(type_node.children[2]).to_a[0], variables: variables
            case type
            when Types::ClassInstance
              Types::ClassSingleton.new(name: type.name, location: nil)
            else
              STDERR.puts "Unexpected type for `class_of`: #{type}"
              Types::Bases::Any.new(location: nil)
            end
          when type_node.type == :ARRAY, type_node.type == :LIST
            types = each_arg(type_node).map {|node| type_of(node, variables: variables) }
            Types::Tuple.new(types: types, location: nil)
          else
            if proc_type?(type_node)
              method_type = method_type(nil, type_node, variables: variables, overloads: 1) or raise
              Types::Proc.new(type: method_type.type, block: nil, location: nil, self_type: nil)
            else
              STDERR.puts "Unexpected type_node:"
              PP.pp type_node, STDERR
              Types::Bases::Any.new(location: nil)
            end
          end
        end

        def proc_type?(type_node)
          if call_node?(type_node, name: :proc)
            true
          else
            type_node.type == :CALL && proc_type?(type_node.children[0])
          end
        end

        def call_node?(node, name:, receiver: -> (node) { node.type == :CONST && node.children[0] == :T }, args: -> (node) { true })
          node.type == :CALL && receiver[node.children[0]] && name == node.children[1] && args[node.children[2]]
        end

        def const_to_name(node)
          case node.type
          when :CONST
            TypeName.new(name: node.children[0], namespace: Namespace.empty)
          when :COLON2
            if node.children[0]
              namespace = const_to_name(node.children[0]).to_namespace
            else
              namespace = Namespace.empty
            end

            type_name = TypeName.new(name: node.children[1], namespace: namespace)

            case type_name.to_s
            when "T::Array" then BuiltinNames::Array.name
            when "T::Hash" then BuiltinNames::Hash.name
            when "T::Range" then BuiltinNames::Range.name
            when "T::Enumerator" then BuiltinNames::Enumerator.name
            when "T::Enumerable" then BuiltinNames::Enumerable.name
            when "T::Set" then BuiltinNames::Set.name
            else type_name
            end
          when :COLON3
            TypeName.new(name: node.children[0], namespace: Namespace.root)
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
            raise "Unexpected node type: #{node.type}"
          end
        end

        def each_arg(array, &block)
          if block_given?
            if array && (array.type == :ARRAY || array.type == :LIST)
              array.children.each do |arg|
                if arg
                  yield arg
                end
              end
            end
          else
            enum_for :each_arg, array
          end
        end

        def each_child(node)
          node.children.each do |child|
            if child.is_a?(::RubyVM::AbstractSyntaxTree::Node)
              yield child
            end
          end
        end

        def node_to_hash(node)
          if node && node.type == :HASH
            # @type var hash: Hash[Symbol, untyped]
            hash = {}

            each_arg(node.children[0]).each_slice(2) do |var, type|
              var or raise

              if (name = symbol_literal_node?(var)) && type
                hash[name] = type
              end
            end

            hash
          end
        end
      end
    end
  end
end

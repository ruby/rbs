module RBS
  module Bundle
    class Writer
      attr_reader :buffers

      def initialize
        @buffers = {}
      end

      def add_buffer(name, buffer, dirs, decls)
        buffers[name] = [buffer, dirs, decls]
      end

      def as_json
        buffers.transform_values do |(_, dirs, decls)|
          [
            dirs.map { directive_as_json(_1) },
            decls.map { declaration_as_json(_1) }
          ]
        end
      end

      def location_as_json(location)
        raise "location cannot be nil" unless location

        required_children = {} #: Hash[String, [Integer, Integer]]
        optional_children = {} #: Hash[String, [Integer, Integer]?]

        location.each_required_key do |key|
          loc = location[key] or raise
          required_children[key.to_s] = [loc.start_pos, loc.end_pos]
        end

        location.each_optional_key do |key|
          if loc = location[key]
            optional_children[key.to_s] = [loc.start_pos, loc.end_pos]
          else
            optional_children[key.to_s] = nil
          end
        end

        required_children = nil if required_children.empty?
        optional_children = nil if optional_children.empty?

        [location.start_pos, location.end_pos, required_children, optional_children]
      end

      def comment_as_json(comment)
        if comment
          [comment.string, location_as_json(comment.location)]
        end
      end

      def annotations_as_json(annotations)
        annotations.map do |annotation|
          [annotation.string, location_as_json(annotation.location)]
        end
      end

      def use_directive_as_json(directive)
        clauses = directive.clauses.map do |clause| #$ directives__use__clause__json
          case clause
          when AST::Directives::Use::SingleClause
            [
              clause.type_name.to_s,
              clause.new_name&.to_s,
              location_as_json(clause.location)
            ]
          when AST::Directives::Use::WildcardClause
            [
              clause.namespace.to_s,
              location_as_json(clause.location)
            ]
          end
        end

        [
          "use",
          clauses,
          location_as_json(directive.location)
        ]
      end

      def directive_as_json(directive)
        case directive
        when AST::Directives::Use
          use_directive_as_json(directive)
        end
      end

      def declaration_as_json(decl)
        case decl
        when AST::Declarations::Class
          class_declaration_as_json(decl)
        when AST::Declarations::Module
          module_declaration_as_json(decl)
        when AST::Declarations::Interface
          interface_declaration_as_json(decl)
        when AST::Declarations::TypeAlias
          type_alias_declaration_as_json(decl)
        when AST::Declarations::Constant
          constant_declaration_as_json(decl)
        when AST::Declarations::Global
          global_declaration_as_json(decl)
        when AST::Declarations::ClassAlias
          class_alias_declaration_as_json(decl)
        when AST::Declarations::ModuleAlias
          module_alias_declaration_as_json(decl)
        end
      end

      def class_declaration_as_json(decl)
        if decl.super_class
          super_class = [decl.super_class.name.to_s, types_as_json(decl.super_class.args), location_as_json(decl.super_class.location)] #: declarations__class__super_class__json
        end

        [
          "decls:class",
          decl.name.to_s,
          type_params_as_json(decl.type_params),
          decl.members.map { class_member_as_json(_1) },
          super_class,
          comment_as_json(decl.comment),
          annotations_as_json(decl.annotations),
          location_as_json(decl.location)
        ]
      end

      def module_declaration_as_json(decl)
        module_selfs = decl.self_types.map do |self_type|
          [
            self_type.name.to_s,
            types_as_json(self_type.args),
            location_as_json(self_type.location)
          ] #: declarations__module__self__json
        end

        [
          "decls:module",
          decl.name.to_s,
          type_params_as_json(decl.type_params),
          decl.members.map { module_member_as_json(_1) },
          module_selfs,
          comment_as_json(decl.comment),
          annotations_as_json(decl.annotations),
          location_as_json(decl.location)
        ]
      end

      def interface_declaration_as_json(decl)
        [
          "decls:interface",
          decl.name.to_s,
          type_params_as_json(decl.type_params),
          decl.members.map { member_as_json(_1) },
          comment_as_json(decl.comment),
          annotations_as_json(decl.annotations),
          location_as_json(decl.location)
        ]
      end

      def type_params_as_json(params)
        params.map do |param|
          [
            param.name.to_s,
            param.variance.to_s, #: type_param__variance__json
            param.unchecked?,
            location_as_json(param.location),
            type_opt_as_json(param.upper_bound),
            type_opt_as_json(param.default_type)
          ]
        end
      end

      def type_alias_declaration_as_json(decl)
        [
          "decls:type_alias",
          decl.name.to_s,
          type_params_as_json(decl.type_params),
          type_as_json(decl.type),
          comment_as_json(decl.comment),
          annotations_as_json(decl.annotations),
          location_as_json(decl.location)
        ]
      end

      def constant_declaration_as_json(decl)
        [
          "decls:constant",
          decl.name.to_s,
          type_as_json(decl.type),
          comment_as_json(decl.comment),
          location_as_json(decl.location)
        ]
      end

      def global_declaration_as_json(decl)
        [
          "decls:global",
          decl.name.to_s,
          type_as_json(decl.type),
          comment_as_json(decl.comment),
          location_as_json(decl.location)
        ]
      end

      def class_alias_declaration_as_json(decl)
        [
          "decls:class_alias",
          decl.new_name.to_s,
          decl.old_name.to_s,
          comment_as_json(decl.comment),
          location_as_json(decl.location)
        ]
      end

      def module_alias_declaration_as_json(decl)
        [
          "decls:module_alias",
          decl.new_name.to_s,
          decl.old_name.to_s,
          comment_as_json(decl.comment),
          location_as_json(decl.location)
        ]
      end

      def member_as_json(member)
        case member
        when AST::Members::MethodDefinition
          (
            [
              "members:method_definition",
              member.name.to_s,
              member.kind.to_s, #: members__method_definition__kind__json
              member.overloads.map do #$ members__method_definition__overload__json
                [
                  method_type_as_json(_1.method_type),
                  annotations_as_json(_1.annotations)
                ]
              end,
              member.overloading?,
              member.visibility&.to_s, #: members__visibility__json?
              annotations_as_json(member.annotations),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__method_definition__json
          )
        when AST::Members::InstanceVariable
          (
            [
              "members:instance_variable",
              member.name.to_s,
              type_as_json(member.type),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__instance_variable__json
          )
        when AST::Members::ClassInstanceVariable
          (
            [
              "members:class_instance_variable",
              member.name.to_s,
              type_as_json(member.type),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__class_instance_variable__json
          )
        when AST::Members::ClassVariable
          (
            [
              "members:class_variable",
              member.name.to_s,
              type_as_json(member.type),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__class_variable__json
          )
        when AST::Members::Include
          (
            [
              "members:include",
              member.name.to_s,
              types_as_json(member.args),
              annotations_as_json(member.annotations),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__include__json
          )
        when AST::Members::Prepend
          (
            [
              "members:prepend",
              member.name.to_s,
              types_as_json(member.args),
              annotations_as_json(member.annotations),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__prepend__json
          )
        when AST::Members::Extend
          (
            [
              "members:extend",
              member.name.to_s,
              types_as_json(member.args),
              annotations_as_json(member.annotations),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__extend__json
          )
        when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
          attribute_member_as_json(member)
        when AST::Members::Alias
          (
            [
              "members:alias",
              member.new_name.to_s,
              member.old_name.to_s,
              member.kind.to_s, #: members__alias__kind__json
              annotations_as_json(member.annotations),
              comment_as_json(member.comment),
              location_as_json(member.location)
            ] #: members__alias__json
          )
        when AST::Members::Public
          (
            ["members:public", location_as_json(member.location)] #: members__public__json
          )
        when AST::Members::Private
          (
            ["members:private", location_as_json(member.location)] #: members__private__json
          )
        end
      end

      def attribute_member_as_json(attr)
        tag =
          case attr
          when AST::Members::AttrReader
            "members:attr_reader"
          when AST::Members::AttrAccessor
            "members:attr_accessor"
          when AST::Members::AttrWriter
            "members:attr_writer"
          end

        var_name =
          case attr.ivar_name
          when Symbol
            attr.ivar_name.to_s
          else
            attr.ivar_name
          end

        [
          tag,
          attr.name.to_s,
          attr.kind.to_s, #: members__attribute__kind__json
          type_as_json(attr.type),
          var_name,
          attr.visibility&.to_s, #: members__visibility__json?
          annotations_as_json(attr.annotations),
          comment_as_json(attr.comment),
          location_as_json(attr.location)
        ] #: members__attr_reader__json | members__attr_writer__json | members__attr_accessor__json
      end

      def types_as_json(types)
        types.map { type_as_json(_1) }
      end

      def type_opt_as_json(type)
        if type
          type_as_json(type)
        end
      end

      def type_as_json(type)
        case type
        when Types::Bases::Any
          if type.to_s == "untyped"
            ["types:untyped", location_as_json(type.location)] #: types__bases__untyped__json
          else
            ["types:todo", location_as_json(type.location)] #: types__bases__todo__json
          end
        when Types::Bases::Bool
          (
            ["types:bool", location_as_json(type.location)] #: types__bases__bool__json
          )
        when Types::Bases::Void
          (
            ["types:void", location_as_json(type.location)] #: types__bases__void__json
          )
        when Types::Bases::Nil
          (
            ["types:nil", location_as_json(type.location)] #: types__bases__nil__json
          )
        when Types::Bases::Top
          (
            ["types:top", location_as_json(type.location)] #: types__bases__top__json
          )
        when Types::Bases::Bottom
          (
            ["types:bot", location_as_json(type.location)] #: types__bases__bot__json
          )
        when Types::Bases::Self
          (
            ["types:self", location_as_json(type.location)] #: types__bases__self__json
          )
        when Types::Bases::Instance
          (
            ["types:instance", location_as_json(type.location)] #: types__bases__instance__json
          )
        when Types::Bases::Class
          (
            ["types:class", location_as_json(type.location)] #: types__bases__class__json
          )
        when Types::Variable
          (
            ["types:variable", type.name.to_s, location_as_json(type.location)] #: types__variable__json
          )
        when Types::ClassSingleton
          (
            ["types:class_singleton", type.name.to_s, location_as_json(type.location)] #: types__class_singleton__json
          )
        when Types::Interface
          (
            ["types:interface", type.name.to_s, types_as_json(type.args), location_as_json(type.location)] #: types__interface__json
          )
        when Types::ClassInstance
          (
            ["types:class_instance", type.name.to_s, types_as_json(type.args), location_as_json(type.location)] #: types__class_instance__json
          )
        when Types::Alias
          (
            ["types:alias", type.name.to_s, types_as_json(type.args), location_as_json(type.location)] #: types__alias__json
          )
        when Types::Tuple
          (
            ["types:tuple", types_as_json(type.types), location_as_json(type.location)] #: types__tuple__json
          )
        when Types::Record
          (
            record = type.fields.each.with_object([]) do |(key, type), array| #$ Array[[types__record__key__json, type__json]]
              key =
                case key
                when Symbol
                  [key.to_s]
                else
                  key
                end

              key = key #: types__record__key__json

              array << [key, type_as_json(type)]
            end

            ["types:record", record, location_as_json(type.location)] #: types__record__json
          )
        when Types::Optional
          (
            ["types:optional", type_as_json(type.type), location_as_json(type.location)] #: types__optional__json
          )
        when Types::Union
          (
            ["types:union", types_as_json(type.types), location_as_json(type.location)] #: types__union__json
          )
        when Types::Intersection
          (
            ["types:intersection", types_as_json(type.types), location_as_json(type.location)] #: types__intersection__json
          )
        when Types::Proc
          (
            [
              "types:proc",
              function_as_json(type.type),
              block_as_json(type.block),
              type_opt_as_json(type.self_type),
              location_as_json(type.location)
            ] #: types__proc__json
          )
        when Types::Literal
          (
            literal =
              case type.literal
              when Symbol
                [type.literal.to_s]
              else
                type.literal
              end #: types__literal__json

            [
              "types:literal",
              literal,
              location_as_json(type.location)
            ] #: types__literal__json
          )
        else
          raise type.to_s
        end
      end

      def function_as_json(function)
        case function
        when Types::Function
          (
            [
              "function:typed",
              function.required_positionals.map { function_param_as_json(_1) },
              function.optional_positionals.map { function_param_as_json(_1) },
              function.rest_positionals&.yield_self { |param| function_param_as_json(param) },
              function.trailing_positionals.map { function_param_as_json(_1) },
              function.required_keywords.map { [_1.to_s, function_param_as_json(_2)] }.to_h, #: Hash[String, types__function__param__json]
              function.optional_keywords.map { [_1.to_s, function_param_as_json(_2)] }.to_h, #: Hash[String, types__function__param__json]
              function.rest_keywords&.yield_self { |param| function_param_as_json(param) },
              type_as_json(function.return_type)
            ] #: types__typed_function__json
          )
        when Types::UntypedFunction
          (
            ["function:untyped", type_as_json(function.return_type)] #: types__untyped_function__json
          )
        end
      end

      def function_param_as_json(param)
        [
          type_as_json(param.type),
          param.name&.to_s,
          location_as_json(param.location)
        ]
      end

      def block_as_json(block)
        if block
          [function_as_json(block.type), block.required, type_opt_as_json(block.self_type)]
        end
      end

      def class_member_as_json(member)
        if member.is_a?(AST::Members::Base)
          member_as_json(member)
        else
          declaration_as_json(member)
        end
      end

      def module_member_as_json(member)
        if member.is_a?(AST::Members::Base)
          member_as_json(member)
        else
          declaration_as_json(member)
        end
      end

      def method_type_as_json(method_type)
        [
          type_params_as_json(method_type.type_params),
          function_as_json(method_type.type),
          block_as_json(method_type.block),
          location_as_json(method_type.location)
        ]
      end
    end
  end
end

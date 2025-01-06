# frozen_string_literal: true

module RBS
  module Bundle
    class Loader
      attr_reader :json

      attr_reader :buffers

      def initialize(json)
        @json = json
        @buffers = json.each_key.with_object({}) { #$ Hash[String, Buffer]
          _2[_1] = yield _1
        }
      end

      def set_buffer(name)
        @current_buffer = buffers.fetch(name)
        yield
      ensure
        @current_buffer = nil
      end

      def buffer
        @current_buffer || raise
      end

      def load()
        json.each do |name, (dirs, decls)|
          set_buffer(name) do
            dirs_ = dirs.map { load_directive(_1) }
            decls_ = decls.map { load_declaration(_1)}

            yield buffer, dirs_, decls_
          end
        end
      end

      def load_directive(dir)
        case dir.fetch(0)
        when "use"
          AST::Directives::Use.new(
            clauses: dir.fetch(1).map { load_use_clause(_1) },
            location: load_location(dir.fetch(2))
          )
        end
      end

      def load_location(loc)
        start_pos, end_pos, required_children, optional_children = loc
        location = RBS::Location.new(buffer, start_pos, end_pos)

        if required_children
          required_children.each do |name, (start_pos, end_pos)|
            location.add_required_child(name.to_sym, start_pos...end_pos)
          end
        end

        if optional_children
          optional_children.each do |name, pair|
            if pair
              location.add_optional_child(name.to_sym, pair[0]...pair[1])
            else
              location.add_optional_child(name.to_sym, nil)
            end
          end
        end

        location
      end

      def load_comment(comment)
        if comment
          AST::Comment.new(
            string: comment[0],
            location: load_location(comment[1])
          )
        end
      end

      def load_annotations(annotations)
        annotations.map do |annotation|
          AST::Annotation.new(
            string: annotation[0],
            location: load_location(annotation[1])
          )
        end
      end

      def load_use_clause(clause)
        if clause.size == 3
          # @type var clause: directives__use__single_clause__json
          AST::Directives::Use::SingleClause.new(
            type_name: TypeName.parse(clause[0]),
            new_name: clause[1]&.to_sym,
            location: load_location(clause[2])
          )
        else
          # @type var clause: directives__use__wildcard_clause__json
          AST::Directives::Use::WildcardClause.new(
            namespace: Namespace.parse(clause[0]),
            location: load_location(clause[1])
          )
        end
      end

      def load_declaration(decl)
        case __skip__ = decl[0]
        when "decls:class"
          # @type var decl: declarations__class__json
          AST::Declarations::Class.new(
            name: TypeName.parse(decl[1]),
            type_params: load_type_params(decl[2]),
            members: load_class_members(decl[3]),
            super_class: decl[4]&.yield_self {|super_class|
              AST::Declarations::Class::Super.new(
                name: TypeName.parse(super_class[0]),
                args: load_types(super_class[1]),
                location: load_location(super_class[2])
              )
            },
            comment: load_comment(decl[5]),
            annotations: load_annotations(decl[6]),
            location: load_location(decl[7])
          )
        when "decls:module"
          # @type var decl: declarations__module__json
          AST::Declarations::Module.new(
            name: TypeName.parse(decl[1]),
            type_params: load_type_params(decl[2]),
            members: load_module_members(decl[3]),
            self_types: decl[4].map {|self_type|
              AST::Declarations::Module::Self.new(
                name: TypeName.parse(self_type[0]),
                args: load_types(self_type[1]),
                location: load_location(self_type[2])
              )
            },
            comment: load_comment(decl[5]),
            annotations: load_annotations(decl[6]),
            location: load_location(decl[7])
          )
        when "decls:interface"
          # @type var decl: declarations__interface__json
          AST::Declarations::Interface.new(
            name: TypeName.parse(decl[1]),
            type_params: load_type_params(decl[2]),
            members: decl[3].map { load_member(_1) },
            comment: load_comment(decl[4]),
            annotations: load_annotations(decl[5]),
            location: load_location(decl[6])
          )
        when "decls:constant"
          # @type var decl: declarations__constant__json
          AST::Declarations::Constant.new(
            name: TypeName.parse(decl[1]),
            type: load_type(decl[2]),
            comment: load_comment(decl[3]),
            location: load_location(decl[4])
          )
        when "decls:type_alias"
          # @type var decl: declarations__type_alias__json
          AST::Declarations::TypeAlias.new(
            name: TypeName.parse(decl[1]),
            type_params: load_type_params(decl[2]),
            type: load_type(decl[3]),
            comment: load_comment(decl[4]),
            annotations: load_annotations(decl[5]),
            location: load_location(decl[6])
          )
        when "decls:global"
          # @type var decl: declarations__global__json
          AST::Declarations::Global.new(
            name: decl[1].to_sym,
            type: load_type(decl[2]),
            comment: load_comment(decl[3]),
            location: load_location(decl[4])
          )
        when "decls:class_alias"
          # @type var decl: declarations__class_alias__json
          AST::Declarations::ClassAlias.new(
            new_name: TypeName.parse(decl[1]),
            old_name: TypeName.parse(decl[2]),
            comment: load_comment(decl[3]),
            location: load_location(decl[4])
          )
        when "decls:module_alias"
          # @type var decl: declarations__module_alias__json
          AST::Declarations::ModuleAlias.new(
            new_name: TypeName.parse(decl[1]),
            old_name: TypeName.parse(decl[2]),
            comment: load_comment(decl[3]),
            location: load_location(decl[4])
          )
        else
          raise "Unexpected declaration tag: #{__skip__ = decl[0]}"
        end
      end

      def load_type_params(type_params)
        type_params.map do |type_param|
          variance = type_param[1].to_sym #: AST::TypeParam::variance

          AST::TypeParam.new(
            name: type_param[0].to_sym,
            variance: variance,
            upper_bound: load_type_opt(type_param[4]),
            default_type: load_type_opt(type_param[5]),
            location: load_location(type_param[3])
          ).unchecked!(type_param[2])
        end
      end

      def load_type_opt(type_opt)
        if type_opt
          load_type(type_opt)
        end
      end

      def load_types(types)
        types.map { load_type(_1) }
      end

      def load_type(type)
        tag = __skip__ = type[0] #: String

        case tag
        when "types:bool"
          # @type var type: types__bases__bool__json
          Types::Bases::Bool.new(location: load_location(type[1]))
        when "types:void"
          # @type var type: types__bases__void__json
          Types::Bases::Void.new(location: load_location(type[1]))
        when "types:untyped"
          # @type var type: types__bases__untyped__json
          Types::Bases::Any.new(location: load_location(type[1]))
        when "types:todo"
          # @type var type: types__bases__todo__json
          Types::Bases::Any.new(location: load_location(type[1])).todo!
        when "types:nil"
          # @type var type: types__bases__nil__json
          Types::Bases::Nil.new(location: load_location(type[1]))
        when "types:self"
          # @type var type: types__bases__self__json
          Types::Bases::Self.new(location: load_location(type[1]))
        when "types:instance"
          # @type var type: types__bases__instance__json
          Types::Bases::Instance.new(location: load_location(type[1]))
        when "types:class"
          # @type var type: types__bases__class__json
          Types::Bases::Class.new(location: load_location(type[1]))
        when "types:top"
          # @type var type: types__bases__top__json
          Types::Bases::Top.new(location: load_location(type[1]))
        when "types:bot"
          # @type var type: types__bases__bot__json
          Types::Bases::Bottom.new(location: load_location(type[1]))
        when "types:variable"
          # @type var type: types__variable__json
          Types::Variable.new(name: type[1].to_sym, location: load_location(type[2]))
        when "types:class_singleton"
          # @type var type: types__class_singleton__json
          Types::ClassSingleton.new(name: TypeName.parse(type[1]), location: load_location(type[2]))
        when "types:interface"
          # @type var type: types__interface__json
          Types::Interface.new(
            name: TypeName.parse(type[1]),
            args: load_types(type[2]),
            location: load_location(type[3])
          )
        when "types:class_instance"
          # @type var type: types__class_instance__json
          Types::ClassInstance.new(
            name: TypeName.parse(type[1]),
            args: load_types(type[2]),
            location: load_location(type[3])
          )
        when "types:alias"
          # @type var type: types__alias__json
          Types::Alias.new(
            name: TypeName.parse(type[1]),
            args: load_types(type[2]),
            location: load_location(type[3])
          )
        when "types:tuple"
          # @type var type: types__tuple__json
          Types::Tuple.new(
            types: load_types(type[1]),
            location: load_location(type[2])
          )
        when "types:record"
          # @type var type: types__record__json
          Types::Record.new(
            fields: Hash[type[1].map {|name, type| [load_record_key(name), load_type(type)] }],
            location: load_location(type[2])
          )
        when "types:optional"
          # @type var type: types__optional__json
          Types::Optional.new(
            type: load_type(type[1]),
            location: load_location(type[2])
          )
        when "types:union"
          # @type var type: types__union__json
          Types::Union.new(
            types: load_types(type[1]),
            location: load_location(type[2])
          )
        when "types:intersection"
          # @type var type: types__intersection__json
          Types::Intersection.new(
            types: load_types(type[1]),
            location: load_location(type[2])
          )
        when "types:proc"
          # @type var type: types__proc__json
          Types::Proc.new(
            type: load_function(type[1]),
            block: load_block(type[2]),
            self_type: load_type_opt(type[3]),
            location: load_location(type[4])
          )
        when "types:literal"
          # @type var type: types__literal__json
          Types::Literal.new(
            literal: load_literal(type[1]),
            location: load_location(type[2])
          )
        else
          raise "Unexpected type tag: #{tag}"
        end
      end

      def load_record_key(key)
        case key
        when String, Integer, true, false
          key
        when Array
          key[0].to_sym
        else
          raise "Unexpected record key: #{key.inspect}"
        end
      end

      def load_literal(lit)
        case lit
        when String, Integer, true, false
          lit
        when Array
          lit[0].to_sym
        else
          raise "Unexpected literal: #{lit.inspect}"
        end
      end

      def load_class_members(members)
        members.map do |member|
          tag = (__skip__ = member[0]) #: String

          case
          when tag.start_with?("decls:")
            load_declaration(
              member #: declarations__json
            )
          when tag.start_with?("members:")
            load_member(
              member #: members__json
            )
          else
            raise "Unknown tag: #{tag}"
          end
        end
      end

      def load_module_members(members)
        members.map do |member|
          tag = (__skip__ = member[0]) #: String

          case
          when tag.start_with?("decls:")
            load_declaration(
              member #: declarations__json
            )
          when tag.start_with?("members:")
            load_member(
              member #: members__json
            )
          else
            raise "Unknown tag: #{tag}"
          end
        end
      end

      def load_member(member)
        tag = (__skip__ = member[0]) #: String

        case tag
        when "members:method_definition"
          # @type var member: members__method_definition__json
          AST::Members::MethodDefinition.new(
            name: member[1].to_sym,
            kind: member[2].to_sym, #: AST::Members::MethodDefinition::kind
            overloads: member[3].map {|overload|
              AST::Members::MethodDefinition::Overload.new(
                method_type: load_method_type(overload[0]),
                annotations: load_annotations(overload[1])
              )
            },
            overloading: member[4],
            visibility: member[5]&.to_sym, #: AST::Members::visibility?
            annotations: load_annotations(member[6]),
            comment: load_comment(member[7]),
            location: load_location(member[8])
          )
        when "members:instance_variable", "members:class_instance_variable", "members:class_variable"
          load_variable(
            member #: members__instance_variable__json | members__class_instance_variable__json | members__class_variable__json
          )
        when "members:include", "members:extend", "members:prepend"
          load_mixin(
            member #: members__include__json | members__extend__json | members__prepend__json
          )
        when "members:attr_reader", "members:attr_accessor", "members:attr_writer"
          load_attribute(
            member #: members__attr_reader__json | members__attr_accessor__json | members__attr_writer__json
          )
        when "members:alias"
          # @type var member: members__alias__json
          AST::Members::Alias.new(
            new_name: member[1].to_sym,
            old_name: member[2].to_sym,
            kind: member[3].to_sym, #: AST::Members::Alias::kind
            annotations: load_annotations(member[4]),
            comment: load_comment(member[5]),
            location: load_location(member[6])
          )
        when "members:public"
          # @type var member: members__public__json
          AST::Members::Public.new(location: load_location(member[1]))
        when "members:private"
          # @type var member: members__private__json
          AST::Members::Private.new(location: load_location(member[1]))
        else
          raise "Unexpected member tag: #{tag}"
        end
      end

      def load_attribute(attr)
        name = attr[1].to_sym
        kind = attr[2].to_sym #: AST::Members::Attribute::kind
        type = load_type(attr[3])
        ivar_name =
          case iv = attr[4]
          when String
            iv.to_sym
          else
            iv
          end
        visibility = attr[5]&.to_sym #: AST::Members::visibility?
        annotations = load_annotations(attr[6])
        comment = load_comment(attr[7])
        location = load_location(attr[8])

        case attr[0]
        when "members:attr_reader"
          AST::Members::AttrReader.new(
            name: name,
            kind: kind,
            type: type,
            ivar_name: ivar_name,
            visibility: visibility,
            annotations: annotations,
            comment: comment,
            location: location
          )
        when "members:attr_accessor"
          AST::Members::AttrAccessor.new(
            name: name,
            kind: kind,
            type: type,
            ivar_name: ivar_name,
            visibility: visibility,
            annotations: annotations,
            comment: comment,
            location: location
          )
        when "members:attr_writer"
          AST::Members::AttrWriter.new(
            name: name,
            kind: kind,
            type: type,
            ivar_name: ivar_name,
            visibility: visibility,
            annotations: annotations,
            comment: comment,
            location: location
          )
        end
      end

      def load_mixin(member)
        name = TypeName.parse(member[1])
        args = load_types(member[2])
        annotations = load_annotations(member[3])
        comment = load_comment(member[4])
        location = load_location(member[5])

        case member[0]
        when "members:include"
          AST::Members::Include.new(
            name: name,
            args: args,
            annotations: annotations,
            location: location,
            comment: comment
          )
        when "members:extend"
          AST::Members::Extend.new(
            name: name,
            args: args,
            annotations: annotations,
            location: location,
            comment: comment
          )
        when "members:prepend"
          AST::Members::Prepend.new(
            name: name,
            args: args,
            annotations: annotations,
            location: location,
            comment: comment
          )
        end
      end

      def load_variable(member)
        name = member[1].to_sym
        type = load_type(member[2])
        comment = load_comment(member[3])
        location = load_location(member[4])

        case member[0]
        when "members:instance_variable"
          AST::Members::InstanceVariable.new(
            name: name,
            type: type,
            location: location,
            comment: comment
          )
        when "members:class_instance_variable"
          AST::Members::ClassInstanceVariable.new(
            name: name,
            type: type,
            location: location,
            comment: comment
          )
        when "members:class_variable"
          AST::Members::ClassVariable.new(
            name: name,
            type: type,
            location: location,
            comment: comment
          )
        end
      end

      def load_method_type(method_type)
        type_params = load_type_params(method_type[0])
        type = load_function(method_type[1])
        block = load_block(method_type[2])
        location = load_location(method_type[3])

        MethodType.new(
          type_params: type_params,
          type: type,
          block: block,
          location: location
        )
      end

      def load_block(block)
        if block
          Types::Block.new(
            type: load_function(block[0]),
            required: block[1],
            self_type: load_type_opt(block[2]),
          )
        end
      end

      def load_function(function)
        case function[0]
        when "function:typed"
          # @type var function: types__typed_function__json
          Types::Function.new(
            required_positionals: function[1].map { load_param(_1) },
            optional_positionals: function[2].map { load_param(_1) },
            rest_positionals: function[3] ? load_param(function[3]) : nil,
            trailing_positionals: function[4].map { load_param(_1) },
            required_keywords: function[5].map {|name, param| [name.to_sym, load_param(param)] }.to_h,
            optional_keywords: function[6].map {|name, param| [name.to_sym, load_param(param)] }.to_h,
            rest_keywords: function[7] ? load_param(function[7]) : nil,
            return_type: load_type(function[8])
          )
        when "function:untyped"
          # @type var function: types__untyped_function__json
          Types::UntypedFunction.new(return_type: load_type(function[1]))
        end
      end

      def load_param(param)
        type, name, location = param

        Types::Function::Param.new(
          type: load_type(type),
          name: name&.to_sym,
          location: load_location(location)
        )
      end
    end
  end
end

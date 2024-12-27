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
            members: [],
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
            members: [],
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
            members: [],
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
        nil
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
        when "members:instance_variable"
        when "members:class_instance_variable"
        when "members:class_variable"
          
        else
          raise "Unexpected member tag: #{tag}"
        end
      end
    end
  end
end

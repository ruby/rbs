module RBS
  class Environment
    attr_reader :buffers
    attr_reader :declarations

    attr_reader :class_decls
    attr_reader :interface_decls
    attr_reader :alias_decls
    attr_reader :constant_decls
    attr_reader :global_decls

    module ContextUtil
      def context
        @context ||= begin
                       (outer + [decl]).each.with_object([Namespace.root]) do |decl, array|
                         array.unshift(array.first + decl.name.to_namespace)
                       end
                     end
      end
    end

    class MultiEntry
      D = Struct.new(:decl, :outer, keyword_init: true) do
        include ContextUtil
      end

      attr_reader :name
      attr_reader :decls

      def initialize(name:)
        @name = name
        @decls = []
      end

      def insert(decl:, outer:)
        decls << D.new(decl: decl, outer: outer)
        @primary = nil
      end

      def validate_type_params
        unless decls.empty?
          hd_decl, *tl_decls = decls
          hd_params = hd_decl.decl.type_params
          hd_names = hd_params.params.map(&:name)

          tl_decls.each do |tl_decl|
            tl_params = tl_decl.decl.type_params

            unless hd_params.size == tl_params.size && hd_params == tl_params.rename_to(hd_names)
              raise GenericParameterMismatchError.new(name: name, decl: tl_decl.decl)
            end
          end
        end
      end

      def type_params
        primary.decl.type_params
      end
    end

    class ModuleEntry < MultiEntry
      def self_types
        decls.flat_map do |d|
          d.decl.self_types
        end.uniq
      end

      def primary
        @primary ||= begin
                       validate_type_params
                       decls.first
                     end
      end
    end

    class ClassEntry < MultiEntry
      def primary
        @primary ||= begin
                       validate_type_params
                       decls.find {|d| d.decl.super_class } || decls.first
                     end
      end
    end

    class SingleEntry
      include ContextUtil

      attr_reader :name
      attr_reader :outer
      attr_reader :decl

      def initialize(name:, decl:, outer:)
        @name = name
        @decl = decl
        @outer = outer
      end
    end

    def initialize
      @buffers = []
      @declarations = []

      @class_decls = {}
      @interface_decls = {}
      @alias_decls = {}
      @constant_decls = {}
      @global_decls = {}
    end

    def initialize_copy(other)
      @buffers = other.buffers.dup
      @declarations = other.declarations.dup

      @class_decls = other.class_decls.dup
      @interface_decls = other.interface_decls.dup
      @alias_decls = other.alias_decls.dup
      @constant_decls = other.constant_decls.dup
      @global_decls = other.global_decls.dup
    end

    def self.from_loader(loader)
      self.new.tap do |env|
        loader.load(env: env)
      end
    end

    def cache_name(cache, name:, decl:, outer:)
      if cache.key?(name)
        raise DuplicatedDeclarationError.new(name, decl, cache[name].decl)
      end

      cache[name] = SingleEntry.new(name: name, decl: decl, outer: outer)
    end

    def insert_decl(decl, outer:, namespace:)
      case decl
      when AST::Declarations::Class, AST::Declarations::Module
        name = decl.name.with_prefix(namespace)

        if constant_decls.key?(name)
          raise DuplicatedDeclarationError.new(name, decl, constant_decls[name].decl)
        end

        unless class_decls.key?(name)
          case decl
          when AST::Declarations::Class
            class_decls[name] ||= ClassEntry.new(name: name)
          when AST::Declarations::Module
            class_decls[name] ||= ModuleEntry.new(name: name)
          end
        end

        existing_entry = class_decls[name]

        case
        when decl.is_a?(AST::Declarations::Module) && existing_entry.is_a?(ModuleEntry)
          # OK
        when decl.is_a?(AST::Declarations::Class) && existing_entry.is_a?(ClassEntry)
          # OK
        else
          raise DuplicatedDeclarationError.new(name, decl, existing_entry.primary.decl)
        end

        existing_entry.insert(decl: decl, outer: outer)

        prefix = outer + [decl]
        ns = name.to_namespace
        decl.each_decl do |d|
          insert_decl(d, outer: prefix, namespace: ns)
        end

      when AST::Declarations::Interface
        cache_name interface_decls, name: decl.name.with_prefix(namespace), decl: decl, outer: outer

      when AST::Declarations::Alias
        cache_name alias_decls, name: decl.name.with_prefix(namespace), decl: decl, outer: outer

      when AST::Declarations::Constant
        name = decl.name.with_prefix(namespace)

        if class_decls.key?(name)
          raise DuplicatedDeclarationError.new(name, decl, class_decls[name].decls[0].decl)
        end

        cache_name constant_decls, name: name, decl: decl, outer: outer

      when AST::Declarations::Global
        cache_name global_decls, name: decl.name, decl: decl, outer: outer

      when AST::Declarations::Extension
        RBS.logger.warn "#{Location.to_string decl.location} Extension construct is deprecated: use class/module syntax instead"
      end
    end

    def <<(decl)
      declarations << decl
      insert_decl(decl, outer: [], namespace: Namespace.root)
      self
    end

    def resolve_type_names(unknown_to_untyped: nil)
      resolver = TypeNameResolver.from_env(self)
      env = Environment.new()

      declarations.each do |decl|
        env << resolve_declaration(resolver,
                                   decl,
                                   outer: [],
                                   prefix: Namespace.root,
                                   unknown_to_untyped: unknown_to_untyped)
      end

      env
    end

    def resolve_declaration(resolver, decl, outer:, prefix:, unknown_to_untyped:)
      if decl.is_a?(AST::Declarations::Global)
        return AST::Declarations::Global.new(
          name: decl.name,
          type: absolute_type(resolver, decl.type, context: [Namespace.root], unknown_to_untyped: unknown_to_untyped),
          location: decl.location,
          comment: decl.comment
        )
      end

      context = (outer + [decl]).each.with_object([Namespace.root]) do |decl, array|
        array.unshift(array.first + decl.name.to_namespace)
      end

      case decl
      when AST::Declarations::Class
        outer_ = outer + [decl]
        prefix_ = prefix + decl.name.to_namespace
        AST::Declarations::Class.new(
          name: decl.name.with_prefix(prefix),
          type_params: decl.type_params,
          super_class: decl.super_class&.yield_self do |super_class|
            AST::Declarations::Class::Super.new(
              name: absolute_type_name(resolver, super_class.name, context: context),
              args: super_class.args.map {|type| absolute_type(resolver, type, context: context, unknown_to_untyped: unknown_to_untyped) }
            )
          end,
          members: decl.members.map do |member|
            case member
            when AST::Members::Base
              resolve_member(resolver, member, context: context, unknown_to_untyped: unknown_to_untyped)
            when AST::Declarations::Base
              resolve_declaration(
                resolver,
                member,
                outer: outer_,
                prefix: prefix_,
                unknown_to_untyped: unknown_to_untyped
              )
            end
          end,
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )
      when AST::Declarations::Module
        outer_ = outer + [decl]
        prefix_ = prefix + decl.name.to_namespace
        AST::Declarations::Module.new(
          name: decl.name.with_prefix(prefix),
          type_params: decl.type_params,
          self_types: decl.self_types.map do |module_self|
            AST::Declarations::Module::Self.new(
              name: absolute_type_name(resolver, module_self.name, context: context),
              args: module_self.args.map {|type| absolute_type(resolver, type, context: context, unknown_to_untyped: unknown_to_untyped) },
              location: module_self.location
            )
          end,
          members: decl.members.map do |member|
            case member
            when AST::Members::Base
              resolve_member(resolver, member, context: context, unknown_to_untyped: unknown_to_untyped)
            when AST::Declarations::Base
              resolve_declaration(
                resolver,
                member,
                outer: outer_,
                prefix: prefix_,
                unknown_to_untyped: unknown_to_untyped
              )
            end
          end,
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )
      when AST::Declarations::Interface
        AST::Declarations::Interface.new(
          name: decl.name.with_prefix(prefix),
          type_params: decl.type_params,
          members: decl.members.map do |member|
            resolve_member(resolver, member, context: context, unknown_to_untyped: unknown_to_untyped)
          end,
          comment: decl.comment,
          location: decl.location,
          annotations: decl.annotations
        )
      when AST::Declarations::Alias
        AST::Declarations::Alias.new(
          name: decl.name.with_prefix(prefix),
          type: absolute_type(resolver, decl.type, context: context, unknown_to_untyped: unknown_to_untyped),
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )

      when AST::Declarations::Constant
        AST::Declarations::Constant.new(
          name: decl.name.with_prefix(prefix),
          type: absolute_type(resolver, decl.type, context: context, unknown_to_untyped: unknown_to_untyped),
          location: decl.location,
          comment: decl.comment
        )
      end
    end

    def resolve_member(resolver, member, context:, unknown_to_untyped:)
      case member
      when AST::Members::MethodDefinition
        AST::Members::MethodDefinition.new(
          name: member.name,
          kind: member.kind,
          types: member.types.map do |type|
            type.map_type {|ty| absolute_type(resolver, ty, context: context, unknown_to_untyped: unknown_to_untyped) }
          end,
          comment: member.comment,
          overload: member.overload?,
          annotations: member.annotations,
          location: member.location
        )
      when AST::Members::AttrAccessor
        AST::Members::AttrAccessor.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name
        )
      when AST::Members::AttrReader
        AST::Members::AttrReader.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name
        )
      when AST::Members::AttrWriter
        AST::Members::AttrWriter.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name
        )
      when AST::Members::InstanceVariable
        AST::Members::InstanceVariable.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::ClassInstanceVariable
        AST::Members::ClassInstanceVariable.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::ClassVariable
        AST::Members::ClassVariable.new(
          name: member.name,
          type: absolute_type(resolver, member.type, context: context, unknown_to_untyped: unknown_to_untyped),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::Include
        AST::Members::Include.new(
          name: absolute_type_name(resolver, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, type, context: context, unknown_to_untyped: unknown_to_untyped) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      when AST::Members::Extend
        AST::Members::Extend.new(
          name: absolute_type_name(resolver, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, type, context: context, unknown_to_untyped: unknown_to_untyped) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      when AST::Members::Prepend
        AST::Members::Prepend.new(
          name: absolute_type_name(resolver, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, type, context: context, unknown_to_untyped: unknown_to_untyped) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      else
        member
      end
    end

    def absolute_type_name(resolver, type_name, context:)
      resolver.resolve(type_name, context: context) || type_name
    end

    def absolute_type(resolver, type, context:, unknown_to_untyped:)
      absolute_type = type.map_type_name do |name|
        absolute_type_name(resolver, name, context: context)
      end

      if unknown_to_untyped
        unknown_to_untyped(absolute_type, type_set: unknown_to_untyped)
      else
        absolute_type
      end
    end

    def valid_name?(type_name)
      if type_name.absolute?
        class_decls.key?(type_name) ||
          interface_decls.key?(type_name) ||
          alias_decls.key?(type_name)
      end
    end

    def fallback_untyped(type, type_set:)
      unless type_set.member?(type)
        RBS.logger.warn { "Converted an unknown type `#{type}` to `untyped`..." }
        type_set << type
      end
      Types::Bases::Any.new(location: type.location)
    end

    def unknown_to_untyped(type, type_set:)
      case type
      when Types::Bases::Base, Types::Variable, Types::Literal
        type
      when Types::Optional
        Types::Optional.new(
          type: unknown_to_untyped(type.type, type_set: type_set),
          location: type.location
        )
      when Types::Alias, Types::ClassSingleton
        if valid_name?(type.name)
          type
        else
          fallback_untyped(type, type_set: type_set)
        end
      when Types::ClassInstance
        if valid_name?(type.name)
          Types::ClassInstance.new(
            name: type.name,
            args: type.args.map {|ty| unknown_to_untyped(ty, type_set: type_set) },
            location: type.location
          )
        else
          fallback_untyped(type, type_set: type_set)
        end
      when Types::Interface
        if valid_name?(type.name)
          Types::Interface.new(
            name: type.name,
            args: type.args.map {|ty| unknown_to_untyped(ty, type_set: type_set) },
            location: type.location
          )
        else
          fallback_untyped(type, type_set: type_set)
        end
      when Types::Union, Types::Intersection
        type.map_type {|ty| unknown_to_untyped(ty, type_set: type_set) }
      when Types::Proc
        Types::Proc.new(
          type: type.type.map_type {|ty| unknown_to_untyped(ty, type_set: type_set) },
          location: type.location
        )
      when Types::Tuple
        Types::Tuple.new(
          types: type.types.map {|ty| unknown_to_untyped(ty, type_set: type_set) },
          location: type.location
        )
      when Types::Record
        Types::Record.new(
          fields: type.fields.transform_values {|ty| unknown_to_untyped(ty, type_set: type_set) },
          location: type.location
        )
      end
    end

    def inspect
      ivars = %i[@buffers @declarations @class_decls @interface_decls @alias_decls @constant_decls @global_decls]
      "\#<RBS::Environment #{ivars.map { |iv| "#{iv}=(#{instance_variable_get(iv).size} items)"}.join(' ')}>"
    end
  end
end

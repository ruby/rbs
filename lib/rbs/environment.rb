# frozen_string_literal: true

module RBS
  class Environment
    attr_reader :class_decls
    attr_reader :interface_decls
    attr_reader :type_alias_decls
    attr_reader :constant_decls
    attr_reader :global_decls
    attr_reader :class_alias_decls

    attr_reader :sources

    class SingleEntry
      attr_reader :name
      attr_reader :context
      attr_reader :decl

      def initialize(name:, decl:, context:)
        @name = name
        @decl = decl
        @context = context
      end
    end

    class ModuleAliasEntry < SingleEntry
    end

    class ClassAliasEntry < SingleEntry
    end

    class InterfaceEntry < SingleEntry
    end

    class TypeAliasEntry < SingleEntry
    end

    class ConstantEntry < SingleEntry
    end

    class GlobalEntry < SingleEntry
    end

    def initialize
      @sources = []
      @class_decls = {}
      @interface_decls = {}
      @type_alias_decls = {}
      @constant_decls = {}
      @global_decls = {}
      @class_alias_decls = {}
      @normalize_module_name_cache = {}
    end

    def initialize_copy(other)
      @sources = other.sources.dup
      @class_decls = other.class_decls.dup
      @interface_decls = other.interface_decls.dup
      @type_alias_decls = other.type_alias_decls.dup
      @constant_decls = other.constant_decls.dup
      @global_decls = other.global_decls.dup
      @class_alias_decls = other.class_alias_decls.dup
    end

    def self.from_loader(loader)
      self.new.tap do |env|
        loader.load(env: env)
      end
    end

    def interface_name?(name)
      interface_decls.key?(name)
    end

    def type_alias_name?(name)
      type_alias_decls.key?(name)
    end

    def module_name?(name)
      class_decls.key?(name) || class_alias_decls.key?(name)
    end

    def type_name?(name)
      interface_name?(name) ||
        type_alias_name?(name) ||
        module_name?(name)
    end

    def constant_name?(name)
      constant_decl?(name) || module_name?(name)
    end

    def constant_decl?(name)
      constant_decls.key?(name)
    end

    def class_decl?(name)
      class_decls[name].is_a?(ClassEntry)
    end

    def module_decl?(name)
      class_decls[name].is_a?(ModuleEntry)
    end

    def module_alias?(name)
      if decl = class_alias_decls[name]
        decl.decl.is_a?(AST::Declarations::ModuleAlias)
      else
        false
      end
    end

    def class_alias?(name)
      if decl = class_alias_decls[name]
        decl.decl.is_a?(AST::Declarations::ClassAlias)
      else
        false
      end
    end

    def class_entry(type_name)
      case
      when (class_entry = class_decls[type_name]).is_a?(ClassEntry)
        class_entry
      when (class_alias = class_alias_decls[type_name]).is_a?(ClassAliasEntry)
        class_alias
      end
    end

    def module_entry(type_name)
      case
      when (module_entry = class_decls[type_name]).is_a?(ModuleEntry)
        module_entry
      when (module_alias = class_alias_decls[type_name]).is_a?(ModuleAliasEntry)
        module_alias
      end
    end

    def normalized_class_entry(type_name)
      if name = normalize_module_name?(type_name)
        case entry = class_entry(name)
        when ClassEntry, nil
          entry
        when ClassAliasEntry
          raise
        end
      end
    end

    def normalized_module_entry(type_name)
      if name = normalize_module_name?(type_name)
        case entry = module_entry(name)
        when ModuleEntry, nil
          entry
        when ModuleAliasEntry
          raise
        end
      end
    end

    def module_class_entry(type_name)
      class_entry(type_name) || module_entry(type_name)
    end

    def normalized_module_class_entry(type_name)
      normalized_class_entry(type_name) || normalized_module_entry(type_name)
    end

    def constant_entry(type_name)
      class_entry(type_name) || module_entry(type_name) || constant_decls[type_name]
    end

    def normalize_type_name?(name)
      return normalize_module_name?(name) if name.class?

      type_name =
        unless name.namespace.empty?
          parent = name.namespace.to_type_name
          parent = normalize_module_name?(parent)
          return parent unless parent

          TypeName.new(namespace: parent.to_namespace, name: name.name)
        else
          name
        end

      if type_name?(type_name)
        type_name
      end
    end

    def normalize_type_name!(name)
      result = normalize_type_name?(name)

      case result
      when TypeName
        result
      when false
        raise "Type name `#{name}` cannot be normalized because it's a cyclic definition"
      when nil
        raise "Type name `#{name}` cannot be normalized because of unknown type name in the path"
      end
    end

    def normalized_type_name?(type_name)
      case
      when type_name.interface?
        interface_decls.key?(type_name)
      when type_name.class?
        class_decls.key?(type_name)
      when type_name.alias?
        type_alias_decls.key?(type_name)
      else
        false
      end
    end

    def normalized_type_name!(name)
      normalized_type_name?(name) or raise "Normalized type name is expected but given `#{name}`, which is normalized to `#{normalize_type_name?(name)}`"
      name
    end

    def normalize_type_name(name)
      normalize_type_name?(name) || name
    end

    def normalize_module_name(name)
      normalize_module_name?(name) or name
    end

    def normalize_module_name?(name)
      raise "Class/module name is expected: #{name}" unless name.class?
      name = name.absolute! unless name.absolute?

      if @normalize_module_name_cache.key?(name)
        return @normalize_module_name_cache[name]
      end

      unless name.namespace.empty?
        parent = name.namespace.to_type_name
        if normalized_parent = normalize_module_name?(parent)
          type_name = TypeName.new(namespace: normalized_parent.to_namespace, name: name.name)
        else
          @normalize_module_name_cache[name] = nil
          return
        end
      else
        type_name = name
      end

      @normalize_module_name_cache[name] = false

      entry = constant_entry(type_name)

      normalized_type_name =
        case entry
        when ClassEntry, ModuleEntry
          type_name
        when ClassAliasEntry, ModuleAliasEntry
          normalize_module_name?(entry.decl.old_name)
        else
          nil
        end

      @normalize_module_name_cache[name] = normalized_type_name
    end

    def insert_rbs_decl(decl, context:, namespace:)
      case decl
      when AST::Declarations::Class, AST::Declarations::Module
        name = decl.name.with_prefix(namespace)

        if cdecl = constant_entry(name)
          if cdecl.is_a?(ConstantEntry) || cdecl.is_a?(ModuleAliasEntry) || cdecl.is_a?(ClassAliasEntry)
            raise DuplicatedDeclarationError.new(name, decl, cdecl.decl)
          end
        end

        unless class_decls.key?(name)
          case decl
          when AST::Declarations::Class
            class_decls[name] ||= ClassEntry.new(name)
          when AST::Declarations::Module
            class_decls[name] ||= ModuleEntry.new(name)
          end
        end

        existing_entry = class_decls[name]

        case
        when decl.is_a?(AST::Declarations::Module) && existing_entry.is_a?(ModuleEntry)
          existing_entry << [context, decl]
        when decl.is_a?(AST::Declarations::Class) && existing_entry.is_a?(ClassEntry)
          existing_entry << [context, decl]
        else
          raise DuplicatedDeclarationError.new(name, decl, existing_entry.primary_decl)
        end

        inner_context = [context, name] #: Resolver::context
        inner_namespace = name.to_namespace
        decl.each_decl do |d|
          insert_rbs_decl(d, context: inner_context, namespace: inner_namespace)
        end

      when AST::Declarations::Interface
        name = decl.name.with_prefix(namespace)

        if interface_entry = interface_decls[name]
          raise DuplicatedDeclarationError.new(name, decl, interface_entry.decl)
        end

        interface_decls[name] = InterfaceEntry.new(name: name, decl: decl, context: context)

      when AST::Declarations::TypeAlias
        name = decl.name.with_prefix(namespace)

        if entry = type_alias_decls[name]
          raise DuplicatedDeclarationError.new(name, decl, entry.decl)
        end

        type_alias_decls[name] = TypeAliasEntry.new(name: name, decl: decl, context: context)

      when AST::Declarations::Constant
        name = decl.name.with_prefix(namespace)

        if entry = constant_entry(name)
          case entry
          when ClassAliasEntry, ModuleAliasEntry, ConstantEntry
            raise DuplicatedDeclarationError.new(name, decl, entry.decl)
          when ClassEntry, ModuleEntry
            raise DuplicatedDeclarationError.new(name, decl, *entry.each_decl.to_a)
          end
        end

        constant_decls[name] = ConstantEntry.new(name: name, decl: decl, context: context)

      when AST::Declarations::Global
        if entry = global_decls[decl.name]
          raise DuplicatedDeclarationError.new(decl.name, decl, entry.decl)
        end

        global_decls[decl.name] = GlobalEntry.new(name: decl.name, decl: decl, context: context)

      when AST::Declarations::ClassAlias, AST::Declarations::ModuleAlias
        name = decl.new_name.with_prefix(namespace)

        if entry = constant_entry(name)
          case entry
          when ClassAliasEntry, ModuleAliasEntry, ConstantEntry
            raise DuplicatedDeclarationError.new(name, decl, entry.decl)
          when ClassEntry, ModuleEntry
            raise DuplicatedDeclarationError.new(name, decl, *entry.each_decl.to_a)
          end
        end

        case decl
        when AST::Declarations::ClassAlias
          class_alias_decls[name] = ClassAliasEntry.new(name: name, decl: decl, context: context)
        when AST::Declarations::ModuleAlias
          class_alias_decls[name] = ModuleAliasEntry.new(name: name, decl: decl, context: context)
        end
      end
    end

    def insert_ruby_decl(decl, context:, namespace:)
      case decl
      when AST::Ruby::Declarations::ClassDecl
        name = decl.class_name.with_prefix(namespace)

        if entry = constant_entry(name)
          if entry.is_a?(ConstantEntry) || entry.is_a?(ModuleAliasEntry) || entry.is_a?(ClassAliasEntry)
            raise DuplicatedDeclarationError.new(name, decl, entry.decl)
          end
          if entry.is_a?(ModuleEntry)
            raise DuplicatedDeclarationError.new(name, decl, *entry.each_decl.to_a)
          end
        end

        entry = ClassEntry.new(name)
        class_decls[name] = entry

        entry << [context, decl]

        inner_context = [context, name] #: Resolver::context
        decl.each_decl do |member|
          insert_ruby_decl(member, context: inner_context, namespace: name.to_namespace)
        end

      when AST::Ruby::Declarations::ModuleDecl
        name = decl.module_name.with_prefix(namespace)

        if entry = constant_entry(name)
          if entry.is_a?(ConstantEntry) || entry.is_a?(ModuleAliasEntry) || entry.is_a?(ClassAliasEntry)
            raise DuplicatedDeclarationError.new(name, decl, entry.decl)
          end
          if entry.is_a?(ClassEntry)
            raise DuplicatedDeclarationError.new(name, decl, *entry.each_decl.to_a)
          end
        end

        entry = ModuleEntry.new(name)
        class_decls[name] = entry

        entry << [context, decl]

        inner_context = [context, name] #: Resolver::context
        decl.each_decl do |member|
          insert_ruby_decl(member, context: inner_context, namespace: name.to_namespace)
        end
      end
    end

    def add_source(source)
      sources << source

      case source
      when Source::RBS
        source.declarations.each do |decl|
          insert_rbs_decl(decl, context: nil, namespace: Namespace.root)
        end
      when Source::Ruby
        source.declarations.each do |dir|
          insert_ruby_decl(dir, context: nil, namespace: Namespace.root)
        end
      end
    end

    def each_rbs_source(&block)
      if block
        sources.each do |source|
          if source.is_a?(Source::RBS)
            yield source
          end
        end
      else
        enum_for(:each_rbs_source)
      end
    end

    def each_ruby_source(&block)
      if block
        sources.each do |source|
          if source.is_a?(Source::Ruby)
            yield source
          end
        end
      else
        enum_for(:each_ruby_source)
      end
    end

    def validate_type_params
      class_decls.each_value do |decl|
        decl.validate_type_params
      end
    end

    def resolve_signature(resolver, table, dirs, decls, only: nil)
      map = UseMap.new(table: table)
      dirs.each do |dir|
        case dir
        when AST::Directives::Use
          dir.clauses.each do |clause|
            map.build_map(clause)
          end
        end
      end

      decls = decls.map do |decl|
        if only && !only.member?(decl)
          decl
        else
          resolve_declaration(resolver, map, decl, context: nil, prefix: Namespace.root)
        end
      end

      [dirs, decls]
    end

    def resolve_type_names(only: nil)
      resolver = Resolver::TypeNameResolver.new(self)
      env = Environment.new

      table = UseMap::Table.new()
      table.known_types.merge(class_decls.keys)
      table.known_types.merge(class_alias_decls.keys)
      table.known_types.merge(type_alias_decls.keys)
      table.known_types.merge(interface_decls.keys)
      table.compute_children

      each_rbs_source do |source|
        resolve = source.directives.find { _1.is_a?(AST::Directives::ResolveTypeNames) } #: AST::Directives::ResolveTypeNames?
        if !resolve || resolve.value
          _, decls = resolve_signature(resolver, table, source.directives, source.declarations)
        else
          decls = source.declarations
        end
        env.add_source(Source::RBS.new(source.buffer, source.directives, decls))
      end

      each_ruby_source do |source|
        decls = source.declarations.map do |decl|
          resolve_ruby_decl(resolver, decl, context: nil, prefix: Namespace.root)
        end

        env.add_source(Source::Ruby.new(source.buffer, source.prism_result, decls, source.diagnostics))
      end

      env
    end

    def resolver_context(*nesting)
      nesting.inject(nil) {|context, decl| #$ Resolver::context
        append_context(context, decl)
      }
    end

    def append_context(context, decl)
      if (_, last = context)
        last or raise
        [context, last + decl.name]
      else
        [nil, decl.name.absolute!]
      end
    end

    def resolve_declaration(resolver, map, decl, context:, prefix:)
      if decl.is_a?(AST::Declarations::Global)
        # @type var decl: AST::Declarations::Global
        return AST::Declarations::Global.new(
          name: decl.name,
          type: absolute_type(resolver, map, decl.type, context: nil),
          location: decl.location,
          comment: decl.comment,
          annotations: decl.annotations
        )
      end

      case decl
      when AST::Declarations::Class
        outer_context = context
        inner_context = append_context(outer_context, decl)

        prefix_ = prefix + decl.name.to_namespace
        AST::Declarations::Class.new(
          name: decl.name.with_prefix(prefix),
          type_params: resolve_type_params(resolver, map, decl.type_params, context: inner_context),
          super_class: decl.super_class&.yield_self do |super_class|
            AST::Declarations::Class::Super.new(
              name: absolute_type_name(resolver, map, super_class.name, context: outer_context),
              args: super_class.args.map {|type| absolute_type(resolver, map, type, context: outer_context) },
              location: super_class.location
            )
          end,
          members: decl.members.map do |member|
            case member
            when AST::Members::Base
              resolve_member(resolver, map, member, context: inner_context)
            when AST::Declarations::Base
              resolve_declaration(
                resolver,
                map,
                member,
                context: inner_context,
                prefix: prefix_
              )
            else
              raise
            end
          end,
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )

      when AST::Declarations::Module
        outer_context = context
        inner_context = append_context(outer_context, decl)

        prefix_ = prefix + decl.name.to_namespace
        AST::Declarations::Module.new(
          name: decl.name.with_prefix(prefix),
          type_params: resolve_type_params(resolver, map, decl.type_params, context: inner_context),
          self_types: decl.self_types.map do |module_self|
            AST::Declarations::Module::Self.new(
              name: absolute_type_name(resolver, map, module_self.name, context: inner_context),
              args: module_self.args.map {|type| absolute_type(resolver, map, type, context: inner_context) },
              location: module_self.location
            )
          end,
          members: decl.members.map do |member|
            case member
            when AST::Members::Base
              resolve_member(resolver, map, member, context: inner_context)
            when AST::Declarations::Base
              resolve_declaration(
                resolver,
                map,
                member,
                context: inner_context,
                prefix: prefix_
              )
            else
              raise
            end
          end,
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )

      when AST::Declarations::Interface
        AST::Declarations::Interface.new(
          name: decl.name.with_prefix(prefix),
          type_params: resolve_type_params(resolver, map, decl.type_params, context: context),
          members: decl.members.map do |member|
            resolve_member(resolver, map, member, context: context)
          end,
          comment: decl.comment,
          location: decl.location,
          annotations: decl.annotations
        )

      when AST::Declarations::TypeAlias
        AST::Declarations::TypeAlias.new(
          name: decl.name.with_prefix(prefix),
          type_params: resolve_type_params(resolver, map, decl.type_params, context: context),
          type: absolute_type(resolver, map, decl.type, context: context),
          location: decl.location,
          annotations: decl.annotations,
          comment: decl.comment
        )

      when AST::Declarations::Constant
        AST::Declarations::Constant.new(
          name: decl.name.with_prefix(prefix),
          type: absolute_type(resolver, map, decl.type, context: context),
          location: decl.location,
          comment: decl.comment,
          annotations: decl.annotations
        )

      when AST::Declarations::ClassAlias
        AST::Declarations::ClassAlias.new(
          new_name: decl.new_name.with_prefix(prefix),
          old_name: absolute_type_name(resolver, map, decl.old_name, context: context),
          location: decl.location,
          comment: decl.comment,
          annotations: decl.annotations
        )

      when AST::Declarations::ModuleAlias
        AST::Declarations::ModuleAlias.new(
          new_name: decl.new_name.with_prefix(prefix),
          old_name: absolute_type_name(resolver, map, decl.old_name, context: context),
          location: decl.location,
          comment: decl.comment,
          annotations: decl.annotations
        )
      end
    end

    def resolve_ruby_decl(resolver, decl, context:, prefix:)
      case decl
      when AST::Ruby::Declarations::ClassDecl
        full_name = decl.class_name.with_prefix(prefix)
        inner_context = [context, full_name] #: Resolver::context
        inner_prefix = full_name.to_namespace

        AST::Ruby::Declarations::ClassDecl.new(decl.buffer, full_name, decl.node).tap do |resolved|
          decl.members.each do |member|
            case member
            when AST::Ruby::Declarations::Base
              resolved.members << resolve_ruby_decl(resolver, member, context: inner_context, prefix: inner_prefix)
            else
              raise "Unknown member type: #{member.class}"
            end
          end
        end

      when AST::Ruby::Declarations::ModuleDecl
        full_name = decl.module_name.with_prefix(prefix)
        inner_context = [context, full_name] #: Resolver::context
        inner_prefix = full_name.to_namespace

        AST::Ruby::Declarations::ModuleDecl.new(decl.buffer, full_name, decl.node).tap do |resolved|
          decl.members.each do |member|
            case member
            when AST::Ruby::Declarations::Base
              resolved.members << resolve_ruby_decl(resolver, member, context: inner_context, prefix: inner_prefix)
            else
              raise "Unknown member type: #{member.class}"
            end
          end
        end

      else
        raise "Unknown declaration type: #{decl.class}"
      end
    end

    def resolve_member(resolver, map, member, context:)
      case member
      when AST::Members::MethodDefinition
        AST::Members::MethodDefinition.new(
          name: member.name,
          kind: member.kind,
          overloads: member.overloads.map do |overload|
            overload.update(
              method_type: resolve_method_type(resolver, map, overload.method_type, context: context)
            )
          end,
          comment: member.comment,
          overloading: member.overloading?,
          annotations: member.annotations,
          location: member.location,
          visibility: member.visibility
        )
      when AST::Members::AttrAccessor
        AST::Members::AttrAccessor.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          kind: member.kind,
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name,
          visibility: member.visibility
        )
      when AST::Members::AttrReader
        AST::Members::AttrReader.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          kind: member.kind,
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name,
          visibility: member.visibility
        )
      when AST::Members::AttrWriter
        AST::Members::AttrWriter.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          kind: member.kind,
          annotations: member.annotations,
          comment: member.comment,
          location: member.location,
          ivar_name: member.ivar_name,
          visibility: member.visibility
        )
      when AST::Members::InstanceVariable
        AST::Members::InstanceVariable.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::ClassInstanceVariable
        AST::Members::ClassInstanceVariable.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::ClassVariable
        AST::Members::ClassVariable.new(
          name: member.name,
          type: absolute_type(resolver, map, member.type, context: context),
          comment: member.comment,
          location: member.location
        )
      when AST::Members::Include
        AST::Members::Include.new(
          name: absolute_type_name(resolver, map, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, map, type, context: context) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      when AST::Members::Extend
        AST::Members::Extend.new(
          name: absolute_type_name(resolver, map, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, map, type, context: context) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      when AST::Members::Prepend
        AST::Members::Prepend.new(
          name: absolute_type_name(resolver, map, member.name, context: context),
          args: member.args.map {|type| absolute_type(resolver, map, type, context: context) },
          comment: member.comment,
          location: member.location,
          annotations: member.annotations
        )
      else
        member
      end
    end

    def resolve_method_type(resolver, map, type, context:)
      type.map_type do |ty|
        absolute_type(resolver, map, ty, context: context)
      end.map_type_bound do |bound|
        _ = absolute_type(resolver, map, bound, context: context)
      end
    end

    def resolve_type_params(resolver, map, params, context:)
      params.map do |param|
        param.map_type {|type| _ = absolute_type(resolver, map, type, context: context) }
      end
    end

    def absolute_type_name(resolver, map, type_name, context:)
      type_name = map.resolve(type_name)
      resolver.resolve(type_name, context: context) || type_name
    end

    def absolute_type(resolver, map, type, context:)
      type.map_type_name do |name, _, _|
        absolute_type_name(resolver, map, name, context: context)
      end
    end

    def inspect
      ivars = %i[@declarations @class_decls @class_alias_decls @interface_decls @type_alias_decls @constant_decls @global_decls]
      "\#<RBS::Environment #{ivars.map { |iv| "#{iv}=(#{instance_variable_get(iv).size} items)"}.join(' ')}>"
    end

    def buffers
      sources.map(&:buffer)
    end

    def unload(buffers)
      env = Environment.new
      bufs = buffers.to_set

      each_rbs_source do |source|
        next if bufs.include?(source.buffer)
        env.add_source(source)
      end

      env
    end
  end
end

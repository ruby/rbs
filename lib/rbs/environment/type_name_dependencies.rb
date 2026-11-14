# frozen_string_literal: true

module RBS
  class Environment
    class TypeNameDependencies
      class Recorder
        def initialize(resolver)
          @resolver = resolver
          @dependencies = []
        end

        def resolve(type_name, context:)
          result, names = @resolver.resolve_with_dependencies(type_name, context: context)
          @dependencies << names
          result
        end

        def type_names
          type_names = Set[] #: Set[TypeName]
          merged = Set[].compare_by_identity #: Set[Array[TypeName]]

          @dependencies.each do |names|
            type_names.merge(names) if merged.add?(names)
          end

          type_names
        end
      end

      attr_reader :type_names

      attr_reader :namespaces

      def initialize
        @type_names = {}
        @namespaces = {}
      end

      def initialize_copy(other)
        @type_names = other.type_names.dup
        @namespaces = other.namespaces.dup
      end

      def resolver(env)
        paths = Set[] #: Set[Pathname]
        env.sources.each do |source|
          paths << source.buffer.name unless source.declarations.empty?
        end
        keep(paths)

        type_names = Set[] #: Set[TypeName]
        type_names.merge(env.class_decls.keys)
        type_names.merge(env.interface_decls.keys)
        type_names.merge(env.type_alias_decls.keys)

        aliases = env.class_alias_decls.transform_values do |entry|
          [entry.decl.unresolved_old_name, entry.context] #: [TypeName, Resolver::context]
        end

        Resolver::TypeNameResolver.new(type_names, aliases)
      end

      def record(source, resolver, merge:)
        recorder = Recorder.new(resolver)
        result = yield recorder
        type_names = recorder.type_names

        namespaces = Set[] #: Set[Namespace]
        if source.is_a?(Source::RBS) && !source.declarations.empty?
          source.directives.each do |directive|
            next unless directive.is_a?(AST::Directives::Use)
            directive.clauses.each do |clause|
              if clause.is_a?(AST::Directives::Use::WildcardClause)
                namespaces << clause.namespace.absolute!
              end
            end
          end
        end

        path = source.buffer.name

        if merge
          # The sets may be shared with the copies
          type_names = (self.type_names[path] || Set[]) | type_names
          namespaces = (self.namespaces[path] || Set[]) | namespaces
        end

        update(self.type_names, path, type_names)
        update(self.namespaces, path, namespaces)

        result
      end

      def delete(path)
        type_names.delete(path)
        namespaces.delete(path)
      end

      def keep(paths)
        type_names.select! { |path, _| paths.include?(path) }
        namespaces.select! { |path, _| paths.include?(path) }
      end

      def affected_paths(old_env, new_env, except:)
        paths = Set[] #: Set[Pathname]

        type_names = changed_type_names(old_env, new_env)
        return paths if type_names.empty?

        self.type_names.each do |path, names|
          next if except.include?(path)
          paths << path if names.intersect?(type_names)
        end

        namespaces = Set[] #: Set[Namespace]
        type_names.each do |type_name|
          namespaces << type_name.namespace unless old_env.type_name?(type_name) == new_env.type_name?(type_name)
        end

        self.namespaces.each do |path, nss|
          next if except.include?(path)
          paths << path if nss.intersect?(namespaces)
        end

        paths
      end

      def changed_type_names(old_env, new_env)
        names = Set[] #: Set[TypeName]

        add_changed_keys(old_env.class_decls, new_env.class_decls, names)
        add_changed_keys(old_env.class_alias_decls, new_env.class_alias_decls, names)
        add_changed_keys(old_env.interface_decls, new_env.interface_decls, names)
        add_changed_keys(old_env.type_alias_decls, new_env.type_alias_decls, names)

        new_env.class_alias_decls.each do |name, entry|
          if old_entry = old_env.class_alias_decls.fetch(name, nil)
            next if old_entry.decl.equal?(entry.decl)

            unless old_entry.decl.unresolved_old_name == entry.decl.unresolved_old_name && old_entry.context == entry.context
              names << name
            end
          end
        end

        names
      end

      private

      def update(hash, path, value)
        if value.empty?
          hash.delete(path)
        else
          hash[path] = value
        end
      end

      def add_changed_keys(old_decls, new_decls, names)
        old_decls.each_key { names << _1 unless new_decls.key?(_1) }
        new_decls.each_key { names << _1 unless old_decls.key?(_1) }
      end
    end
  end
end

# frozen_string_literal: true

module RBS
  class Environment
    class TypeNameDependencies
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

      def record(source, resolver, merge:)
        result, type_names = resolver.record_dependencies { yield }

        namespaces = Set[] #: Set[Namespace]
        if source.is_a?(Source::RBS)
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

      def affected_paths(old_env, new_env)
        paths = Set[] #: Set[Pathname]

        type_names = changed_type_names(old_env, new_env)
        return paths if type_names.empty?

        namespaces = Set[] #: Set[Namespace]
        type_names.each { namespaces << _1.namespace }

        old_sources = Set[].compare_by_identity #: Set[Source::t]
        old_sources.merge(old_env.sources)

        new_env.sources.each do |source|
          next unless old_sources.include?(source)

          path = source.buffer.name

          case
          when self.type_names[path]&.intersect?(type_names)
            paths << path
          when self.namespaces[path]&.intersect?(namespaces)
            paths << path
          end
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

            unless old_entry.decl.old_name == entry.decl.old_name && old_entry.context == entry.context
              names << name
            end
          end
        end

        names
      end

      private

      def update(hash, path, set)
        if set.empty?
          hash.delete(path)
        else
          hash[path] = set
        end
      end

      def add_changed_keys(old_decls, new_decls, names)
        old_decls.each_key { names << _1 unless new_decls.key?(_1) }
        new_decls.each_key { names << _1 unless old_decls.key?(_1) }
      end
    end
  end
end

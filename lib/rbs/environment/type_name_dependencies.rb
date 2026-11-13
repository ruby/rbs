# frozen_string_literal: true

module RBS
  class Environment
    class TypeNameDependencies
      class Recorder
        attr_reader :queries

        def initialize(resolver)
          @resolver = resolver
          @queries = {}
          @queries.compare_by_identity
        end

        def resolve(type_name, context:)
          results = (@queries[context] ||= {})
          results[type_name] ||= @resolver.resolve(type_name, context: context) || type_name
        end
      end

      attr_reader :queries

      attr_reader :wildcards

      attr_reader :aliases

      def initialize
        @queries = {}
        @wildcards = {}
        @aliases = {}
      end

      def initialize_copy(other)
        @queries = other.queries.dup
        @wildcards = other.wildcards.dup
        @aliases = other.aliases.dup
      end

      def resolver(env, only:)
        paths = Set[] #: Set[Pathname]

        env.sources.each do |source|
          path = source.buffer.name
          paths << path

          if source.declarations.empty?
            delete(path)
            next
          end

          decls = source.declarations #: Array[AST::Declarations::t | AST::Ruby::Declarations::t]
          decls = decls.select { only.member?(_1) } if only
          next if decls.empty?

          aliases = {} #: Hash[TypeName, [TypeName, Resolver::context]]
          decls.each do |decl|
            each_alias_name(decl, Namespace.root) do |name|
              entry = env.class_alias_decls.fetch(name)
              aliases[name] = [entry.decl.old_name, entry.context]
            end
          end

          if decls.size < source.declarations.size
            # The hash may be shared with the copies
            aliases = (self.aliases[path] || {}).merge(aliases)
          end

          update(self.aliases, path, aliases)
          update(wildcards, path, wildcard_namespaces(source))
        end

        keep(paths)

        build_resolver(env, alias_table(env))
      end

      def record(source, resolver, merge:)
        recorder = Recorder.new(resolver)
        result = yield recorder
        queries = recorder.queries

        path = source.buffer.name

        if merge && (recorded = self.queries[path])
          # The hash may be shared with the copies
          queries = recorded.merge(queries)
        end

        update(self.queries, path, queries)

        result
      end

      def delete(path)
        queries.delete(path)
        wildcards.delete(path)
        aliases.delete(path)
      end

      def keep(paths)
        queries.select! { |path, _| paths.include?(path) }
        wildcards.select! { |path, _| paths.include?(path) }
        aliases.select! { |path, _| paths.include?(path) }
      end

      def affected_paths(old_env, new_env, except:)
        paths = Set[] #: Set[Pathname]

        type_names = changed_type_names(old_env, new_env, except: except)
        return paths if type_names.empty?

        aliases = alias_table(new_env, except: except)
        resolver = build_resolver(new_env, aliases)

        # The resolution of a type name tests the type names that end with one of the names it consists of, and the
        # ones tested to normalize the aliases among them
        names = Set[] #: Set[Symbol]
        type_names.each { names << _1.name }
        loop do
          size = names.size
          aliases.each { |name, (module_name, _)| names << name.name if mention?(module_name, names) }
          break if names.size == size
        end

        queries.each do |path, contexts|
          next if except.include?(path)

          changed = contexts.any? do |context, results|
            results.any? do |type_name, result|
              mention?(type_name, names) && (resolver.resolve(type_name, context: context) || type_name) != result
            end
          end

          paths << path if changed
        end

        namespaces = Set[] #: Set[Namespace]
        type_names.each do |type_name|
          namespaces << type_name.namespace unless old_env.type_name?(type_name) == new_env.type_name?(type_name)
        end

        wildcards.each do |path, nss|
          next if except.include?(path)
          paths << path if nss.intersect?(namespaces)
        end

        paths
      end

      def changed_type_names(old_env, new_env, except:)
        names = Set[] #: Set[TypeName]

        add_changed_keys(old_env.class_decls, new_env.class_decls, names)
        add_changed_keys(old_env.class_alias_decls, new_env.class_alias_decls, names)
        add_changed_keys(old_env.interface_decls, new_env.interface_decls, names)
        add_changed_keys(old_env.type_alias_decls, new_env.type_alias_decls, names)

        old_aliases = alias_table(old_env)
        alias_table(new_env, except: except).each do |name, definition|
          if old_definition = old_aliases.fetch(name, nil)
            names << name unless old_definition == definition
          end
        end

        names
      end

      private

      def alias_table(env, except: nil)
        table = {} #: Hash[TypeName, [TypeName, Resolver::context]]

        env.class_alias_decls.each do |name, entry|
          table[name] = [entry.decl.old_name, entry.context]
        end

        aliases.each do |path, definitions|
          next if except&.include?(path)

          definitions.each do |name, definition|
            table[name] = definition if table.key?(name)
          end
        end

        table
      end

      def build_resolver(env, aliases)
        type_names = Set[] #: Set[TypeName]
        type_names.merge(env.class_decls.keys)
        type_names.merge(env.interface_decls.keys)
        type_names.merge(env.type_alias_decls.keys)

        Resolver::TypeNameResolver.new(type_names, aliases)
      end

      def mention?(type_name, names)
        names.include?(type_name.name) || type_name.namespace.path.any? { names.include?(_1) }
      end

      def wildcard_namespaces(source)
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

        namespaces
      end

      def add_changed_keys(old_decls, new_decls, names)
        old_decls.each_key { names << _1 unless new_decls.key?(_1) }
        new_decls.each_key { names << _1 unless old_decls.key?(_1) }
      end

      def each_alias_name(decl, namespace, &block)
        case decl
        when AST::Declarations::Class, AST::Declarations::Module
          namespace = decl.name.with_prefix(namespace).to_namespace
          decl.each_decl { each_alias_name(_1, namespace, &block) }
        when AST::Ruby::Declarations::ClassDecl
          namespace = decl.class_name.with_prefix(namespace).to_namespace
          decl.each_decl { each_alias_name(_1, namespace, &block) }
        when AST::Ruby::Declarations::ModuleDecl
          namespace = decl.module_name.with_prefix(namespace).to_namespace
          decl.each_decl { each_alias_name(_1, namespace, &block) }
        when AST::Declarations::ClassAlias, AST::Declarations::ModuleAlias, AST::Ruby::Declarations::ClassModuleAliasDecl
          yield decl.new_name.with_prefix(namespace)
        end
      end

      def update(hash, path, value)
        if value.empty?
          hash.delete(path)
        else
          hash[path] = value
        end
      end
    end
  end
end

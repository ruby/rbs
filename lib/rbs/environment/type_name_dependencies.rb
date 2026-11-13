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
        namespaces = {} #: Hash[Pathname, Array[Namespace]]

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
          namespaces[path] = wildcard_namespaces(source)
        end

        keep(paths)

        children = children(env, namespaces.each_value.flat_map(&:itself))
        namespaces.each do |path, nss|
          update(wildcards, path, nss.to_h { [_1, children.fetch(_1)] })
        end

        build_resolver(env)
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

      def affected_paths(env, except:)
        paths = Set[] #: Set[Pathname]
        resolver = build_resolver(env, except: except)

        queries.each do |path, contexts|
          next if except.include?(path)

          changed = contexts.any? do |context, results|
            results.any? do |type_name, result|
              (resolver.resolve(type_name, context: context) || type_name) != result
            end
          end

          paths << path if changed
        end

        namespaces = [] #: Array[Namespace]
        wildcards.each do |path, recorded|
          namespaces.concat(recorded.keys) unless except.include?(path) || paths.include?(path)
        end

        unless namespaces.empty?
          children = children(env, namespaces)

          wildcards.each do |path, recorded|
            next if except.include?(path) || paths.include?(path)
            paths << path if recorded.any? { |namespace, names| children.fetch(namespace) != names }
          end
        end

        paths
      end

      private

      def build_resolver(env, except: nil)
        type_names = Set[] #: Set[TypeName]
        type_names.merge(env.class_decls.keys)
        type_names.merge(env.interface_decls.keys)
        type_names.merge(env.type_alias_decls.keys)

        aliases = {} #: Hash[TypeName, [TypeName, Resolver::context]]

        env.class_alias_decls.each do |name, entry|
          aliases[name] = [entry.decl.old_name, entry.context]
        end

        self.aliases.each do |path, definitions|
          next if except&.include?(path)

          definitions.each do |name, definition|
            aliases[name] = definition if aliases.key?(name)
          end
        end

        Resolver::TypeNameResolver.new(type_names, aliases)
      end

      def children(env, namespaces)
        children = {} #: Hash[Namespace, Set[TypeName]]
        return children if namespaces.empty?

        namespaces.each { children[_1] = Set[] }

        [env.class_decls, env.class_alias_decls, env.type_alias_decls, env.interface_decls].each do |decls|
          decls.each_key do |name|
            children[name.namespace]&.add(name)
          end
        end

        children
      end

      def wildcard_namespaces(source)
        namespaces = [] #: Array[Namespace]

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

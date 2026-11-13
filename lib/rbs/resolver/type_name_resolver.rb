# frozen_string_literal: true

module RBS
  module Resolver
    class TypeNameResolver
      attr_reader :all_names
      attr_reader :cache
      attr_reader :aliases

      def initialize(all_names, aliases)
        @all_names = all_names
        @aliases = aliases
        @cache = {}
      end

      def self.build(env)
        all_names = Set.new #: Set[TypeName]

        all_names.merge(env.class_decls.keys)
        all_names.merge(env.interface_decls.keys)
        all_names.merge(env.type_alias_decls.keys)

        aliases = {} #: Hash[TypeName, [TypeName, context]]

        env.class_alias_decls.each do |name, entry|
          aliases[name] = [entry.decl.old_name, entry.context]
        end

        new(all_names, aliases)
      end

      def try_cache(type_name, context)
        inner = cache[context] ||= {}

        inner[type_name] ||= begin
          names = [] #: Array[TypeName]
          result = yield names
          entry = [result, names.freeze] #: [TypeName?, Array[TypeName]]
          entry.freeze
        end
      end

      def resolve(type_name, context:)
        if type_name.absolute? && all_names.include?(type_name)
          return type_name
        end

        resolve0(type_name, context)[0]
      end

      def resolve_with_dependencies(type_name, context:)
        if type_name.absolute? && all_names.include?(type_name)
          return [type_name, [type_name]]
        end

        resolve0(type_name, context)
      end

      def resolve0(type_name, context)
        try_cache(type_name, context) do |names|
          if type_name.class?
            resolve_namespace0(type_name, context, Set.new, names) || nil
          else
            namespace = type_name.namespace

            if namespace.empty?
              resolve_type_name(type_name.name, context, names)
            else
              if namespace = resolve_namespace0(namespace.to_type_name, context, Set.new, names)
                type_name = TypeName[namespace.to_namespace, type_name.name]
                has_type_name?(type_name, names)
              end
            end
          end
        end
      end

      def resolve_namespace(type_name, context:)
        if type_name.absolute? && all_names.include?(type_name)
          return type_name
        end

        unless type_name.class?
          raise "Type name must be a class name: #{type_name}"
        end

        entry = try_cache(type_name, context) do |names|
          ns = resolve_namespace0(type_name, context, Set.new, names) or return ns
        end

        entry[0]
      end

      def has_type_name?(full_name, names)
        names << full_name

        if all_names.include?(full_name)
          full_name
        end
      end

      def aliased_name?(type_name, names)
        names << type_name

        if aliases.key?(type_name)
          type_name
        end
      end

      def resolve_type_name(type_name, context, names)
        if context
          outer, inner = context
          case inner
          when false
            resolve_type_name(type_name, outer, names)
          else
            has_type_name?(inner, names) or raise "Context must be normalized: #{inner.inspect}"
            has_type_name?(TypeName[inner.to_namespace, type_name], names) || resolve_type_name(type_name, outer, names)
          end
        else
          type_name = TypeName[Namespace.root, type_name]
          has_type_name?(type_name, names)
        end
      end

      def resolve_head_namespace(head, context, names)
        if context
          outer, inner = context
          case inner
          when false
            resolve_head_namespace(head, outer, names)
          when TypeName
            has_type_name?(inner, names) or raise "Context must be normalized: #{inner.inspect}"
            type_name = TypeName[inner.to_namespace, head]
            has_type_name?(type_name, names) || aliased_name?(type_name, names) || resolve_head_namespace(head, outer, names)
          end
        else
          type_name = TypeName[Namespace.root, head]
          has_type_name?(type_name, names) || aliased_name?(type_name, names)
        end
      end

      def normalize_namespace(type_name, rhs, context, visited, names)
        if visited.include?(type_name)
          # Cycle detected
          return false
        end

        visited << type_name

        begin
          resolve_namespace0(rhs, context, visited, names)
        ensure
          visited.delete(type_name)
        end
      end

      def resolve_namespace0(type_name, context, visited, names)
        head, *tail = [*type_name.namespace.path, type_name.name]

        head = head #: Symbol

        head =
          if type_name.absolute?
            root_name = TypeName[Namespace.root, head]
            has_type_name?(root_name, names) || aliased_name?(root_name, names)
          else
            resolve_head_namespace(head, context, names)
          end

        if head
          if (rhs, context = aliases.fetch(head, nil))
            head = normalize_namespace(head, rhs, context, visited, names) or return head
          end

          tail.inject(head) do |namespace, name|
            type_name = TypeName[namespace.to_namespace, name]
            case
            when has_type_name?(type_name, names)
              type_name
            when (rhs, context = aliases.fetch(type_name, nil))
              m = normalize_namespace(type_name, rhs, context, visited, names) or return m
            else
              return nil
            end
          end
        end
      end
    end
  end
end

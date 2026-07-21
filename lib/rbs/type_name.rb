# frozen_string_literal: true

module RBS
  class TypeName
    attr_reader :namespace
    attr_reader :name
    attr_reader :kind

    def initialize(namespace:, name:)
      @namespace = namespace
      @name = name
      @kind = case
              when name.match?(/\A[A-Z]/)
                :class
              when name.match?(/\A[a-z]/)
                :alias
              when name.start_with?("_")
                :interface
              when name.match?(/\A\p{Uppercase}/)
                :class
              else
                :alias
              end
    end

    # Process-wide flyweight cache. Two-level Hash keyed by canonical
    # Namespace identity (outer uses `compare_by_identity`) and name
    # Symbol.
    @intern_mutex = Mutex.new
    @intern_cache = {}  #: Hash[Namespace, Hash[Symbol, TypeName]]
    @intern_cache.compare_by_identity

    # Returns a canonical `TypeName` instance for the given `namespace` /
    # `name` pair. The namespace is canonicalized through `Namespace.[]`
    # so identity-based lookup works regardless of the caller passing a
    # fresh `Namespace.new` or an already-interned instance.
    def self.[](namespace, name)
      ns = Namespace[namespace.path, namespace.absolute?]

      inner = @intern_cache[ns]
      if inner && (cached = inner[name])
        return cached
      end

      @intern_mutex.synchronize do
        inner = (@intern_cache[ns] ||= {})
        inner[name] ||= new(namespace: ns, name: name)
      end
    end

    def ==(other)
      return true if equal?(other)
      other.is_a?(self.class) && other.namespace == namespace && other.name == name
    end

    alias eql? ==

    def hash
      @hash ||= namespace.hash ^ name.hash
    end

    def to_s
      "#{namespace.to_s}#{name}"
    end

    def to_json(state = nil)
      to_s.to_json(state)
    end

    def to_namespace
      namespace.append(self.name)
    end

    def class?
      kind == :class
    end

    def alias?
      kind == :alias
    end

    def absolute!
      TypeName[namespace.absolute!, name]
    end

    def absolute?
      namespace.absolute?
    end

    def relative!
      TypeName[namespace.relative!, name]
    end

    def interface?
      kind == :interface
    end

    def with_prefix(namespace)
      TypeName[namespace + self.namespace, name]
    end

    def split
      namespace.path + [name]
    end

    def +(other)
      if other.absolute?
        other
      else
        TypeName[self.to_namespace + other.namespace, other.name]
      end
    end

    def self.parse(string)
      absolute = string.start_with?("::")

      *path, name = string.delete_prefix("::").split("::").map(&:to_sym)
      raise unless name

      TypeName[Namespace[path, absolute], name]
    end
  end
end

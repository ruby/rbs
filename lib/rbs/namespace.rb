# frozen_string_literal: true

module RBS
  class Namespace
    attr_reader :path

    def initialize(path:, absolute:)
      @path = path
      @absolute = absolute ? true : false
    end

    # Process-wide flyweight cache. Two tries (one per `absolute` flag)
    # keyed on path Symbols, with the cached Namespace stored under the
    # `INTERN_LEAF` sentinel at each path's terminal node.
    @intern_mutex = Mutex.new
    @intern_trie_absolute = {}
    @intern_trie_relative = {}
    INTERN_LEAF = Module.new

    # Returns a canonical `Namespace` instance for the given `path` /
    # `absolute` pair. Repeated calls with structurally equal arguments
    # return the same object, so callers can rely on `equal?` for fast
    # equality. The path Array is duplicated and frozen on insert.
    def self.[](path, absolute)
      absolute = absolute ? true : false

      # Lock-free fast path.
      node = absolute ? @intern_trie_absolute : @intern_trie_relative
      path.each do |sym|
        node = node[sym]
        break unless node
      end
      if node && (cached = node[INTERN_LEAF])
        return cached
      end

      @intern_mutex.synchronize do
        node = absolute ? @intern_trie_absolute : @intern_trie_relative
        path.each { |sym| node = (node[sym] ||= {}) }
        node[INTERN_LEAF] ||= begin
          frozen_path = path.frozen? ? path : path.dup.freeze
          new(path: frozen_path, absolute: absolute)
        end
      end
    end

    def self.empty
      @empty ||= self[[], false]
    end

    def self.root
      @root ||= self[[], true]
    end

    def +(other)
      if other.absolute?
        other
      else
        Namespace[path + other.path, absolute?]
      end
    end

    def append(component)
      Namespace[path + [component], absolute?]
    end

    def parent
      @parent ||= begin
        raise "Parent with empty namespace" if empty?
        Namespace[path.take(path.size - 1), absolute?]
      end
    end

    def absolute?
      @absolute
    end

    def relative?
      !absolute?
    end

    def absolute!
      Namespace[path, true]
    end

    def relative!
      Namespace[path, false]
    end

    def empty?
      path.empty?
    end

    def ==(other)
      return true if equal?(other)
      other.is_a?(Namespace) && other.path == path && other.absolute? == absolute?
    end

    alias eql? ==

    def hash
      @hash ||= path.hash ^ absolute?.hash
    end

    def split
      last = path.last or return
      parent = self.parent
      [parent, last]
    end

    def to_s
      if empty?
        absolute? ? "::" : ""
      else
        s = path.join("::")
        absolute? ? "::#{s}::" : "#{s}::"
      end
    end

    def to_type_name
      parent, name = split

      raise unless name
      raise unless parent

      TypeName[parent, name]
    end

    def self.parse(string)
      if string.start_with?("::")
        self[string.split("::").drop(1).map(&:to_sym), true]
      else
        self[string.split("::").map(&:to_sym), false]
      end
    end

    def ascend
      if block_given?
        current = self

        until current.empty?
          yield current
          current = _ = current.parent
        end

        yield current

        self
      else
        enum_for(:ascend)
      end
    end
  end
end

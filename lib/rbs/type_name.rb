# frozen_string_literal: true

module RBS
  ALL_NAMES = {}
  ALL_NAMESPACES = {}

  class TypeName
    attr_reader :kind
    attr_reader :string, :name

    def namespace
      Namespace(@namespace_str)
    end

    def initialize(string)
      @string = string
      separator_index = string.rindex("::")
      if separator_index
        @namespace_str = string[0, separator_index + 2]
        @name = (string[(separator_index + 2)..] || raise).to_sym
      else
        @namespace_str = ""
        @name = string.to_sym
      end
      @kind = case
              when name.match?(/\A[A-Z]/)
                :class
              when name.match?(/\A[a-z]/)
                :alias
              when name.start_with?("_")
                :interface
              else
                # Defaults to :class
                :class
              end
    end

    def ==(other)
      other.is_a?(self.class) && other.string == string
    end

    alias eql? ==

    def hash
      string.hash
    end

    def to_s
      string
    end

    def to_json(state = _ = nil)
      string.to_json(state)
    end

    def to_namespace
      Namespace(string + "::")
    end

    def class?
      kind == :class
    end

    def alias?
      kind == :alias
    end

    def absolute!
      if absolute?
        self
      else
        TypeName("::" + string)
      end
    end

    def absolute?
      string.start_with?("::")
    end

    def relative!
      if absolute?
        TypeName(string.delete_prefix("::"))
      else
        self
      end
    end

    def interface?
      kind == :interface
    end

    def with_prefix(namespace)
      if absolute?
        self
      else
        TypeName(namespace.to_s + string)
      end
    end

    def split
      namespace.path + [name]
    end

    def +(other)
      if other.absolute?
        other
      else
        TypeName(string + "::" + other.string)
      end
    end
  end
end

module Kernel
  def TypeName(string)
    string.freeze
    RBS::ALL_NAMES[string] ||= RBS::TypeName.new(string)
  end
end

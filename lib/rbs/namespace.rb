# frozen_string_literal: true

module RBS
  class Namespace
    def initialize(string)
      @string = string
    end

    def self.empty
      Namespace("")
    end

    def self.root
      Namespace("::")
    end

    def +(other)
      if other.absolute?
        other
      else
        Namespace(@string + other.to_s)
      end
    end

    def path
      if empty?
        []
      else
        to_s.delete_prefix("::").delete_suffix("::").split("::").map(&:to_sym)
      end
    end

    def append(component)
      Namespace("#{@string}#{component}::")
    end

    def parent
      raise "Parent with empty namespace" if empty?
      to_type_name.namespace
    end

    def absolute?
      @string.start_with?("::")
    end

    def relative?
      !absolute?
    end

    def absolute!
      if absolute?
        self
      else
        Namespace("::" + @string)
      end
    end

    def relative!
      if relative?
        self
      else
        Namespace(@string[2..] || raise)
      end
    end

    def empty?
      @string == "" || @string == "::"
    end

    def ==(other)
      other.is_a?(Namespace) && @string == other.to_s
    end

    alias eql? ==

    def hash
      @string.hash
    end

    def split
      return if empty?

      name = to_type_name()
      [name.namespace, name.name]
    end

    def head_tail
      return if empty?

      head, *tail = path
      head or raise

      if tail.empty?
        namespace = ""
      else
        namespace = tail.join("::") + "::"
      end

      [
        head,
        Namespace(namespace)
      ]
    end

    def to_s
      @string
    end

    def to_type_name
      raise @string.inspect if empty?
      TypeName @string.delete_suffix("::")
    end

    def self.parse(string)
      Namespace(string)
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

module Kernel
  def Namespace(name)
    RBS::ALL_NAMESPACES[name] ||= RBS::Namespace.new(name)
  end
end

module Ruby
  module Signature
    class TypeName
      attr_reader :namespace
      attr_reader :name
      attr_reader :kind

      def initialize(namespace:, name:)
        @namespace = namespace
        @name = name
        @kind = case name.to_s[0,1]
                when /[A-Z]/
                  :class
                when /[a-z]/
                  :alias
                when "_"
                  :interface
                end
      end

      def ==(other)
        other.is_a?(self.class) && other.namespace == namespace && other.name == name
      end

      alias eql? ==

      def hash
        self.class.hash ^ namespace.hash ^ name.hash
      end

      def to_s
        "#{namespace.to_s}::#{name}"
      end

      def class?
        kind == :class
      end

      def alias?
        kind == :alias
      end

      def interface?
        kind == :interface
      end
    end
  end
end

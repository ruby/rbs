module RBS
  module Collection
    class Manifest
      class Dependency
        attr_reader :name

        def initialize(name:)
          @name = name
        end

        def ==(other)
          other.is_a?(Dependency) && other.name == name
        end

        alias eql? ==

        def hash
          name.hash
        end
      end

      attr_reader :dependencies, :load_implicitly

      def path
        @path or raise "`#path` is `nil` (reading `#path` of *default* manifest?)"
      end

      def load_implicitly?
        case load_implicitly
        when nil
          true
        else
          load_implicitly
        end
      end

      def self.from(path, hash)
        dependencies = hash["dependencies"].map {|dep| Dependency.new(name: dep["name"]) }
        new(path, dependencies: dependencies, load_implicitly: hash["load_implicitly"])
      end

      def initialize(path, dependencies:, load_implicitly:)
        @path = path
        @dependencies = dependencies
        @load_implicitly = load_implicitly
      end

      def ==(other)
        other.is_a?(Manifest) && other.dependencies == dependencies
      end

      alias eql? ==

      def hash
        dependencies.hash
      end

      def self.default
        @default
      end

      @default = new(_ = nil, dependencies: [], load_implicitly: true)
    end
  end
end

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

      attr_reader :dependencies

      def path
        @path or raise "`#path` is `nil` (reading `#path` of *default* manifest?)"
      end

      def self.from(path, hash)
        dependencies = hash["dependencies"].map {|dep| Dependency.new(name: dep["name"]) }
        new(path, dependencies: dependencies)
      end

      def initialize(path, dependencies:)
        @path = path
        @dependencies = dependencies
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

      @default = new(_ = nil, dependencies: [])
    end
  end
end

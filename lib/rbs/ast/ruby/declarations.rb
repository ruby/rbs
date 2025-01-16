module RBS
  module AST
    module Ruby
      module Declarations
        class Base
        end

        class ClassDecl < Base
          attr_reader :node
          attr_reader :members

          def initialize(node)
            @node = node
            @members = []
          end
        end

        class SingletonClassDecl < Base
          attr_reader :node
          attr_reader :members

          def initialize(node)
            @node = node
            @members = []
          end
        end

        class ModuleDecl < Base
          attr_reader :node
          attr_reader :members

          def initialize(node)
            @node = node
            @members = []
          end
        end

        class ConstantDecl < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def type
            Types::Bases::Any.new(location: nil)
          end
        end
      end
    end
  end
end

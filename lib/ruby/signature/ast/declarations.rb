module Ruby
  module Signature
    module AST
      module Declarations
        class Class
          class Super
            attr_reader :name
            attr_reader :args

            def initialize(name:, args:)
              @name = name
              @args = args
            end

            def ==(other)
              other.is_a?(Super) && other.name == name && other.args == args
            end

            alias eql? ==

            def hash
              self.class.hash ^ name.hash ^ args.hash
            end
          end

          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :super_class
          attr_reader :location

          def initialize(name:, type_params:, super_class:, members:, location:)
            @name = name
            @type_params = type_params
            @super_class = super_class
            @members = members
            @location = location
          end

          def ==(other)
            other.is_a?(Class) &&
              other.name == name &&
              other.type_params == type_params &&
              other.super_class == super_class &&
              other.members == members
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type_params.hash ^ super_class.hash ^ member.hash
          end
        end

        class Module
          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :location
          attr_reader :self_type

          def initialize(name:, type_params:, members:, self_type:, location:)
            @name = name
            @type_params = type_params
            @self_type = self_type
            @members = members
            @location = location
          end

          def ==(other)
            other.is_a?(Module) &&
              other.name == name &&
              other.type_params == type_params &&
              other.self_type == self_type &&
              other.members == members
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type_params.hash ^ self_type.hash ^ members.hash
          end
        end

        class Interface
          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :location

          def initialize(name:, type_params:, members:, location:)
            @name = name
            @type_params = type_params
            @members = members
            @location = location
          end

          def ==(other)
            other.is_a?(Interface) &&
              other.name == name &&
              other.type_params == type_params &&
              other.members == members
          end

          alias eql? ==

          def hash
            self.class.hash ^ type_params.hash ^ members.hash
          end
        end

        class Alias
          attr_reader :name
          attr_reader :type
          attr_reader :location

          def initialize(name:, type:, location:)
            @name = name
            @type = type
            @location = location
          end

          def ==(other)
            other.is_a?(Alias) &&
              other.name == name &&
              other.type == type
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type.hash
          end
        end

        class Constant
          attr_reader :name
          attr_reader :type
          attr_reader :location

          def initialize(name:, type:, location:)
            @name = name
            @type = type
            @location = location
          end

          def ==(other)
            other.is_a?(Constant) &&
              other.name == name &&
              other.type == type
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type.hash
          end
        end

        class Global
          attr_reader :name
          attr_reader :type
          attr_reader :location

          def initialize(name:, type:, location:)
            @name = name
            @type = type
            @location = location
          end

          def ==(other)
            other.is_a?(Global) &&
              other.name == name &&
              other.type == type
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type.hash
          end
        end
      end
    end
  end
end

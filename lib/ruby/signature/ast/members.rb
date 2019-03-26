module Ruby
  module Signature
    module AST
      module Members
        class MethodDefinition
          attr_reader :name
          attr_reader :kind
          attr_reader :types
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, kind:, types:, annotations:, location:)
            @name = name
            @kind = kind
            @types = types
            @annotations = annotations
            @location = location
          end

          def ==(other)
            other.is_a?(MethodDefinition) &&
              other.name == name &&
              other.kind == kind &&
              other.types == types
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ kind.hash ^ types.hash
          end
        end

        module Var
          attr_reader :name
          attr_reader :type
          attr_reader :location

          def initialize(name:, type:, location:)
            @name = name
            @type = type
            @location = location
          end

          def ==(other)
            other.is_a?(self.class) && other.name == name && other.type == type
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type.hash
          end
        end

        class InstanceVariable
          include Var
        end

        class ClassInstanceVariable
          include Var
        end

        class ClassVariable
          include Var
        end

        module Mixin
          attr_reader :name
          attr_reader :args
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, args:, annotations:, location:)
            @name = name
            @args = args
            @annotations = annotations
            @location = location
          end

          def ==(other)
            other.is_a?(self.class) && other.name == name && other.args == args
          end

          def eql?(other)
            self == other
          end

          def hash
            self.class.hash ^ name.hash ^ args.hash
          end
        end

        class Include
          include Mixin
        end

        class Extend
          include Mixin
        end

        module Attribute
          attr_reader :name
          attr_reader :type
          attr_reader :ivar_name
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, type:, ivar_name:, annotations:, location:)
            @name = name
            @type = type
            @ivar_name = ivar_name
            @annotations = annotations
            @location = location
          end

          def ==(other)
            other.is_a?(self.class) &&
              other.name == name &&
              other.type == type &&
              other.ivar_name == ivar_name
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type.hash ^ ivar_name.hash
          end
        end

        class AttrReader
          include Attribute
        end

        class AttrAccessor
          include Attribute
        end

        class AttrWriter
          include Attribute
        end

        module LocationOnly
          attr_reader :location

          def initialize(location:)
            @location = location
          end

          def ==(other)
            other.is_a?(self.class)
          end

          alias eql? ==

          def hash
            self.class.hash
          end
        end

        class Public
          include LocationOnly
        end

        class Private
          include LocationOnly
        end

        class Alias
          attr_reader :new_name
          attr_reader :old_name
          attr_reader :kind
          attr_reader :annotations
          attr_reader :location

          def initialize(new_name:, old_name:, kind:, annotations:, location:)
            @new_name = new_name
            @old_name = old_name
            @kind = kind
            @annotations = annotations
            @location = location
          end

          def ==(other)
            other.is_a?(self.class) &&
              other.new_name == new_name &&
              other.old_name == old_name &&
              other.kind == kind
          end

          alias eql? ==

          def hash
            self.class.hash ^ new_name.hash ^ old_name.hash ^ kind
          end
        end
      end
    end
  end
end

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

            def to_json(*a)
              {
                name: name,
                args: args
              }.to_json(*a)
            end
          end

          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :super_class
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, type_params:, super_class:, members:, annotations:, location:)
            @name = name
            @type_params = type_params
            @super_class = super_class
            @members = members
            @annotations = annotations
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

          def to_json(*a)
            {
              declaration: :class,
              name: name,
              type_params: type_params,
              members: members,
              super_class: super_class,
              annotations: annotations,
              location: location
            }.to_json(*a)
          end
        end

        class Module
          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :location
          attr_reader :annotations
          attr_reader :self_type

          def initialize(name:, type_params:, members:, self_type:, annotations:, location:)
            @name = name
            @type_params = type_params
            @self_type = self_type
            @members = members
            @annotations = annotations
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

          def to_json(*a)
            {
              declaration: :module,
              name: name,
              type_params: type_params,
              members: members,
              self_type: self_type,
              annotations: annotations,
              location: location
            }.to_json(*a)
          end
        end

        class Extension
          attr_reader :name
          attr_reader :type_params
          attr_reader :extension_name
          attr_reader :members
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, type_params:, extension_name:, members:, annotations:, location:)
            @name = name
            @type_params = type_params
            @extension_name = extension_name
            @members = members
            @annotations = annotations
            @location = location
          end

          def ==(other)
            other.is_a?(Extension) &&
              other.name == name &&
              other.type_params == type_params &&
              other.extension_name == extension_name &&
              other.members == members
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ type_params.hash ^ extension_name.hash ^ members.hash
          end

          def to_json(*a)
            {
              declaration: :extension,
              name: name,
              type_params: type_params,
              extension_name: extension_name,
              members: members,
              annotations: annotations,
              location: location
            }.to_json(*a)
          end
        end

        class Interface
          attr_reader :name
          attr_reader :type_params
          attr_reader :members
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, type_params:, members:, annotations:, location:)
            @name = name
            @type_params = type_params
            @members = members
            @annotations = annotations
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

          def to_json(*a)
            {
              declaration: :interface,
              name: name,
              type_params: type_params,
              members: members,
              annotations: annotations,
              location: location
            }.to_json(*a)
          end
        end

        class Alias
          attr_reader :name
          attr_reader :type
          attr_reader :annotations
          attr_reader :location

          def initialize(name:, type:, annotations:, location:)
            @name = name
            @type = type
            @annotations = annotations
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

          def to_json(*a)
            {
              declaration: :alias,
              name: name,
              type: type,
              annotations: annotations,
              location: location
            }.to_json(*a)
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

          def to_json(*a)
            {
              declaration: :constant,
              name: name,
              type: type,
              location: location
            }.to_json(*a)
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

          def to_json(*a)
            {
              declaration: :global,
              name: name,
              type: type,
              location: location
            }.to_json(*a)
          end
        end
      end
    end
  end
end

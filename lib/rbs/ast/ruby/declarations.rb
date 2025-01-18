module RBS
  module AST
    module Ruby
      module Declarations
        class Base
          attr_reader :buffer

          def constant_as_type_name(node)
            case node
            when Prism::ConstantPathNode, Prism::ConstantReadNode
              TypeName.parse(node.full_name)
            end
          end

          def rbs_location(location)
            Location.new(buffer, location.start_character_offset, location.end_character_offset)
          end

          def initialize(buffer)
            @buffer = buffer
          end
        end

        class ClassDecl < Base
          class Super
            attr_reader :name
            attr_reader :args
            attr_reader :location

            def initialize(name, args, location)
              @name = name
              @args = args
              @location = location
            end
          end

          attr_reader :node
          attr_reader :members

          def initialize(buffer, node)
            super(buffer)
            @node = node
            @members = []
          end

          def type_params
            []
          end

          def super_class
            if super_node = node.superclass
              if typename = constant_as_type_name(super_node)
                Super.new(typename, [], rbs_location(super_node.location))
              end
            end
          end

          def name
            path = node.constant_path
            raise if path.is_a?(Prism::CallNode)
            TypeName.parse(path.full_name)
          end

          def location
            rbs_location(node.location)
          end

          def each_member(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Members::Base)
              end
            else
              enum_for :each_member
            end
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

          def initialize(buffer, node)
            super(buffer)
            @node = node
            @members = []
          end

          def type_params
            []
          end

          def self_types
            []
          end

          def name
            path = node.constant_path
            raise if path.is_a?(Prism::MissingNode)
            TypeName.parse(path.full_name)
          end

          def location
            rbs_location(node.location)
          end

          def each_member(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Members::Base)
              end
            else
              enum_for :each_member
            end
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

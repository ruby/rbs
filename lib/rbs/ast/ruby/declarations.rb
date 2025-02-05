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
            attr_reader :class_name
            attr_reader :type_args
            attr_reader :location
            attr_reader :class_name_location
            attr_reader :open_paren_location
            attr_reader :close_paren_location
            attr_reader :args_separator_locations

            def initialize(class_name:, type_args:, location:, class_name_location:, open_paren_location:, close_paren_location:, args_separator_locations:)
              @class_name = class_name
              @type_args = type_args
              @location = location
              @class_name_location = class_name_location
              @open_paren_location = open_paren_location
              @close_paren_location = close_paren_location
              @args_separator_locations = args_separator_locations
            end

            def map_type_name(&block)
              self.class.new(
                class_name: yield(class_name),
                type_args: type_args.map {|type| type.map_type_name { yield(_1) } },
                location: location,
                class_name_location: class_name_location,
                open_paren_location: open_paren_location,
                close_paren_location: close_paren_location,
                args_separator_locations: args_separator_locations
              ) #: self
            end

            alias name class_name

            alias args type_args
          end

          attr_reader :node
          attr_reader :location
          attr_reader :class_name
          attr_reader :class_name_location
          attr_reader :members
          attr_reader :super_class

          def initialize(buffer, node, location:, class_name:, class_name_location:, super_class:)
            super(buffer)
            @node = node
            @location = location
            @class_name = class_name
            @class_name_location = class_name_location
            @super_class = super_class
            @members = []
          end

          alias name class_name

          def type_params
            []
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

          def each_decl(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Base)
              end
            else
              enum_for :each_decl
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
          attr_reader :location
          attr_reader :module_name
          attr_reader :module_name_location
          attr_reader :members

          def initialize(buffer, node, location:, module_name:, module_name_location:)
            super(buffer)
            @node = node
            @location = location
            @module_name = module_name
            @module_name_location = module_name_location
            @members = []
          end

          alias name module_name

          def type_params
            []
          end

          def self_types
            []
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

          def each_decl(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Base)
              end
            else
              enum_for :each_decl
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

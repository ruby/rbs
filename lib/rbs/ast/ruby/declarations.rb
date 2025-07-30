# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Declarations
        class Base
          attr_reader :buffer

          include Helpers::ConstantHelper
          include Helpers::LocationHelper

          def initialize(buffer)
            @buffer = buffer
          end
        end

        class ClassDecl < Base
          class SuperClass
            attr_reader :type_name_location

            attr_reader :operator_location

            attr_reader :type_name

            attr_reader :type_annotation

            def initialize(type_name_location, operator_location, type_name, type_annotation)
              @type_name_location = type_name_location
              @operator_location = operator_location
              @type_name = type_name
              @type_annotation = type_annotation
            end

            def type_args
              if type_annotation
                type_annotation.type_args
              else
                []
              end
            end

            def location
              if type_annotation
                Location.new(
                  type_name_location.buffer,
                  type_name_location.start_pos,
                  type_annotation.location.end_pos
                )
              else
                type_name_location
              end
            end

            alias name type_name
            alias args type_args
          end

          attr_reader :class_name

          attr_reader :members

          attr_reader :node

          attr_reader :super_class

          def initialize(buffer, name, node, super_class)
            super(buffer)
            @class_name = name
            @node = node
            @members = []
            @super_class = super_class
          end

          def each_decl(&block)
            return enum_for(:each_decl) unless block

            @members.each do |member|
              if member.is_a?(Base)
                yield member
              end
            end
          end

          def type_params = []

          def location
            rbs_location(node.location)
          end

          def name_location
            rbs_location(node.constant_path.location)
          end
        end

        class ModuleDecl < Base
          attr_reader :module_name

          attr_reader :members

          attr_reader :node

          def initialize(buffer, name, node)
            super(buffer)
            @module_name = name
            @node = node
            @members = []
          end

          def each_decl(&block)
            return enum_for(:each_decl) unless block

            @members.each do |member|
              if member.is_a?(Base)
                yield member
              end
            end
          end

          def type_params = []

          def self_types = []

          def location
            rbs_location(node.location)
          end

          def name_location
            rbs_location(node.constant_path.location)
          end
        end
      end
    end
  end
end

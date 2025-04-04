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
          attr_reader :class_name

          attr_reader :members

          attr_reader :node

          def initialize(buffer, name, node)
            super(buffer)
            @class_name = name
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

          def super_class = nil

          def type_params = []

          def location
            rbs_location(node.location)
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
        end
      end
    end
  end
end

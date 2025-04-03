# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Declarations
        class Base
          attr_reader :buffer

          include Helpers::ConstantHelper

          def initialize(buffer)
            @buffer = buffer
          end

          def rbs_location(location)
            Location.new(buffer, location.start_character_offset, location.end_character_offset)
          end
        end

        class ClassDecl < Base
          attr_reader :class_name

          attr_reader :members

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
        end

        class ModuleDecl < Base
          attr_reader :module_name

          attr_reader :members

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
        end
      end
    end
  end
end

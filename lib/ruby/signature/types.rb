module Ruby
  module Signature
    module Types
      module NoFreeVariables
        def free_variables(set = Set.new)
          set
        end
      end

      module Bases
        class Base
          attr_reader :location

          def initialize(location:)
            @location = location
          end

          def ==(other)
            other.is_a?(self.class)
          end

          def hash
            self.class.hash
          end

          alias eql? ==

          include NoFreeVariables

          def to_json(*a)
            klass = case self
                    when Types::Bases::Bool
                      :bool
                    when Types::Bases::Void
                      :void
                    when Types::Bases::Any
                      :any
                    when Types::Bases::Nil
                      :nil
                    when Types::Bases::Top
                      :top
                    when Types::Bases::Bottom
                      :bot
                    when Types::Bases::Self
                      :self
                    when Types::Bases::Instance
                      :instance
                    when Types::Bases::Class
                      :class
                    else
                      raise "Unexpected base type: #{type.inspect}"
                    end

            { class: klass, location: location }.to_json(*a)
          end
        end

        class Bool < Base; end
        class Void < Base; end
        class Any < Base; end
        class Nil < Base; end
        class Top < Base; end
        class Bottom < Base; end
        class Self < Base; end
        class Instance < Base; end
        class Class < Base; end
      end

      class Variable
        attr_reader :name
        attr_reader :location

        def initialize(name:, location:)
          @name = name
          @location = location
        end

        def ==(other)
          other.is_a?(Variable) && other.name == name
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            set << name
          end
        end

        def to_json(*a)
          { class: :variable, name: name, location: location }.to_json(*a)
        end
      end

      class ClassSingleton
        attr_reader :name
        attr_reader :location

        def initialize(name:, location:)
          @name = name
          @location = location
        end

        def ==(other)
          other.is_a?(ClassSingleton) && other.name == name
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash
        end

        include NoFreeVariables

        def to_json(*a)
          { class: :class_singleton, name: name, location: location }.to_json(*a)
        end
      end

      module Application
        attr_reader :name
        attr_reader :args

        def ==(other)
          other.is_a?(self.class) && other.name == name && other.args == args
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ args.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            args.each do |arg|
              arg.free_variables(set)
            end
          end
        end
      end

      class Interface
        attr_reader :location

        include Application

        def initialize(name:, args:, location:)
          @name = name
          @args = args
          @location = location
        end

        def to_json(*a)
          { class: :interface, name: name, args: args, location: location }.to_json(*a)
        end
      end

      class ClassInstance
        attr_reader :location

        include Application

        def initialize(name:, args:, location:)
          @name = name
          @args = args
          @location = location
        end

        def to_json(*a)
          { class: :class_instance, name: name, args: args, location: location }.to_json(*a)
        end
      end

      class Alias
        attr_reader :location
        attr_reader :name

        def initialize(name:, location:)
          @name = name
          @location = location
        end

        def ==(other)
          other.is_a?(Alias) && other.name == name
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash
        end

        include NoFreeVariables

        def to_json(*a)
          { class: :alias, name: name, location: location }.to_json(*a)
        end
      end

      class Tuple
        attr_reader :types
        attr_reader :location

        def initialize(types:, location:)
          @types = types
          @location = location
        end

        def ==(other)
          other.is_a?(Tuple) && other.types == types
        end

        alias eql? ==

        def hash
          self.class.hash ^ types.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            types.each do |type|
              type.free_variables set
            end
          end
        end

        def to_json(*a)
          { class: :tuple, types: types, location: location }.to_json(*a)
        end
      end

      class Record
        attr_reader :fields
        attr_reader :location

        def initialize(fields:, location:)
          @fields = fields
          @location = location
        end

        def ==(other)
          other.is_a?(Record) && other.fields == fields
        end

        alias eql? ==

        def hash
          self.class.hash ^ fields.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            fields.each_value do |type|
              type.free_variables set
            end
          end
        end

        def to_json(*a)
          { class: :record, fields: fields, location: location }.to_json(*a)
        end
      end

      class Optional
        attr_reader :type
        attr_reader :location

        def initialize(type:, location:)
          @type = type
          @location = location
        end

        def ==(other)
          other.is_a?(Optional) && other.type == type
        end

        alias eql? ==

        def hash
          self.class.hash ^ type.hash
        end

        def free_variables(set = Set.new)
          type.free_variables(set)
        end

        def to_json(*a)
          { class: :optional, type: type, location: location }.to_json(*a)
        end
      end

      class Union
        attr_reader :types
        attr_reader :location

        def initialize(types:, location:)
          @types = types
          @location = location
        end

        def ==(other)
          other.is_a?(Union) && other.types == types
        end

        alias eql? ==

        def hash
          self.class.hash ^ types.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            types.each do |type|
              type.free_variables set
            end
          end
        end

        def to_json(*a)
          { class: :union, types: types, location: location }.to_json(*a)
        end
      end

      class Intersection
        attr_reader :types
        attr_reader :location

        def initialize(types:, location:)
          @types = types
          @location = location
        end

        def ==(other)
          other.is_a?(Interface) && other.types == types
        end

        alias eql? ==

        def hash
          self.class.hash ^ types.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            types.each do |type|
              type.free_variables set
            end
          end
        end

        def to_json(*a)
          { class: :intersection, types: types, location: location }.to_json(*a)
        end
      end

      class Function
        class Param
          attr_reader :type
          attr_reader :name

          def initialize(type:, name:)
            @type = type
            @name = name
          end

          def ==(other)
            other.is_a?(Param) && other.type == type && other.name == name
          end

          alias eql? ==

          def hash
            self.class.hash ^ type.hash ^ name.hash
          end

          def map_type
            if block_given?
              Param.new(name: name, type: yield(type))
            else
              enum_for :map_type
            end
          end

          def to_json(*a)
            { type: type, name: name }.to_json(*a)
          end
        end

        attr_reader :required_positionals
        attr_reader :optional_positionals
        attr_reader :rest_positionals
        attr_reader :trailing_positionals
        attr_reader :required_keywords
        attr_reader :optional_keywords
        attr_reader :rest_keywords
        attr_reader :return_type

        def initialize(required_positionals:, optional_positionals:, rest_positionals:, trailing_positionals:, required_keywords:, optional_keywords:, rest_keywords:, return_type:)
          @return_type = return_type
          @required_positionals = required_positionals
          @optional_positionals = optional_positionals
          @rest_positionals = rest_positionals
          @trailing_positionals = trailing_positionals
          @required_keywords = required_keywords
          @optional_keywords = optional_keywords
          @rest_keywords = rest_keywords
        end

        def ==(other)
          other.is_a?(Function) &&
            other.required_positionals == required_positionals &&
            other.optional_positionals == optional_positionals &&
            other.rest_positionals == rest_positionals &&
            other.trailing_positionals == trailing_positionals &&
            other.required_keywords == required_keywords &&
            other.optional_keywords == optional_keywords &&
            other.rest_keywords == rest_keywords &&
            return_type == return_type
        end

        alias eql? ==

        def hash
          self.class.hash ^
            required_positionals.hash ^
            optional_positionals.hash ^
            rest_positionals.hash ^
            trailing_positionals.hash ^
            required_keywords.hash ^
            optional_keywords.hash ^
            rest_keywords.hash ^
            return_type.hash
        end

        def free_variables(set = Set.new)
          set.tap do
            required_positionals.each do |param|
              param.type.free_variables(set)
            end
            optional_positionals.each do |param|
              param.type.free_variables(set)
            end
            rest_positionals&.yield_self do |param|
              param.type.free_variables(set)
            end
            trailing_positionals.each do |param|
              param.type.free_variables(set)
            end
            required_keywords.each_value do |param|
              param.type.free_variables(set)
            end
            optional_keywords.each_value do |param|
              param.type.free_variables(set)
            end
            rest_keywords&.yield_self do |param|
              param.type.free_variables(set)
            end

            return_type.free_variables(set)
          end
        end

        def map_type(&block)
          if block_given?
            Function.new(
              required_positionals: required_positionals.map {|param| param.map_type &block },
              optional_positionals: optional_positionals.map {|param| param.map_type &block },
              rest_positionals: rest_positionals&.yield_self {|param| param.map_type &block },
              trailing_positionals: trailing_positionals.map {|param| param.map_type &block },
              required_keywords: required_keywords.transform_values {|param| param.map_type &block },
              optional_keywords: optional_keywords.transform_values {|param| param.map_type &block },
              rest_keywords: rest_keywords&.yield_self {|param| param.map_type &block },
              return_type: yield(return_type)
            )
          else
            enum_for :map_type
          end
        end

        def to_json(*a)
          {
            required_positionals: required_positionals,
            optional_positionals: optional_positionals,
            rest_positionals: rest_positionals,
            trailing_positionals: trailing_positionals,
            required_keywords: required_keywords,
            optional_keywords: optional_keywords,
            rest_keywords: rest_keywords
          }.to_json(*a)
        end
      end

      class Proc
        attr_reader :type
        attr_reader :location

        def initialize(location:, type:)
          @type = type
          @location = location
        end

        def ==(other)
          other.is_a?(Proc) && other.type == type
        end

        alias eql? ==

        def hash
          self.class.hash ^ type.hash
        end

        def free_variables(set)
          type.free_variables(set)
        end

        def to_json(*a)
          { class: :proc, type: type, location: location }.to_json(*a)
        end
      end

      class Literal
        attr_reader :literal
        attr_reader :location

        def initialize(literal:, location:)
          @literal = literal
          @location = location
        end

        def ==(other)
          other.is_a?(Literal) && other.literal == literal
        end

        alias eql? ==

        def hash
          self.class.hash ^ literal.hash
        end

        include NoFreeVariables

        def to_json(*a)
          { class: :literal, literal: literal.inspect, location: location }.to_json(*a)
        end
      end
    end
  end
end

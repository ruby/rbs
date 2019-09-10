module Ruby
  module Signature
    module Types
      module NoFreeVariables
        def free_variables(set = Set.new)
          set
        end
      end

      module NoSubst
        def sub(s)
          self
        end
      end

      module EmptyEachType
        def each_type
          if block_given?
            # nop
          else
            enum_for :each_type
          end
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
          include NoSubst
          include EmptyEachType

          def to_json(*a)
            klass = to_s.to_sym
            { class: klass, location: location }.to_json(*a)
          end

          def to_s(level = 0)
            case self
            when Types::Bases::Bool
              'bool'
            when Types::Bases::Void
              'void'
            when Types::Bases::Any
              'any'
            when Types::Bases::Nil
              'nil'
            when Types::Bases::Top
              'top'
            when Types::Bases::Bottom
              'bot'
            when Types::Bases::Self
              'self'
            when Types::Bases::Instance
              'instance'
            when Types::Bases::Class
              'class'
            else
              raise "Unexpected base type: #{type.inspect}"
            end
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

        def sub(s)
          s.apply(self)
        end

        def self.build(v)
          case v
          when Symbol
            new(name: v, location: nil)
          when Array
            v.map {|x| new(name: x, location: nil) }
          end
        end

        @@count = 0
        def self.fresh(v = :T)
          @@count = @@count + 1
          new(name: :"#{v}@#{@@count}", location: nil)
        end

        def to_s(level = 0)
          name.to_s
        end

        include EmptyEachType
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
        include NoSubst

        def to_json(*a)
          { class: :class_singleton, name: name, location: location }.to_json(*a)
        end

        def to_s(level = 0)
          "singleton(#{name})"
        end

        include EmptyEachType
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

        def to_s(level = 0)
          if args.empty?
            name.to_s
          else
            "#{name}[#{args.join(", ")}]"
          end
        end

        def each_type(&block)
          if block_given?
            args.each(&block)
          else
            enum_for :each_type
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

        def sub(s)
          self.class.new(name: name,
                         args: args.map {|ty| ty.sub(s) },
                         location: location)
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

        def sub(s)
          self.class.new(name: name,
                         args: args.map {|ty| ty.sub(s) },
                         location: location)
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
        include NoSubst

        def to_json(*a)
          { class: :alias, name: name, location: location }.to_json(*a)
        end

        def to_s(level = 0)
          name.to_s
        end

        include EmptyEachType
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

        def sub(s)
          self.class.new(types: types.map {|ty| ty.sub(s) },
                         location: location)
        end

        def to_s(level = 0)
          "[ #{types.join(", ")} ]"
        end

        def each_type(&block)
          if block_given?
            types.each(&block)
          else
            enum_for :each_type
          end
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

        def sub(s)
          self.class.new(fields: fields.transform_values {|ty| ty.sub(s) },
                         location: location)
        end

        def to_s(level = 0)
          fields = self.fields.map do |key, type|
            "#{key}: #{type}"
          end
          "{ #{fields.join(", ")} }"
        end

        def each_type(&block)
          if block_given?
            fields.each_value(&block)
          else
            enum_for :each_type
          end
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

        def sub(s)
          self.class.new(type: type.sub(s), location: location)
        end

        def to_s(level = 0)
          "#{type.to_s(1)}?"
        end

        def each_type
          if block_given?
            yield type
          else
            enum_for :each_type
          end
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

        def sub(s)
          self.class.new(types: types.map {|ty| ty.sub(s) },
                         location: location)
        end

        def to_s(level = 0)
          if level > 0
            "(#{types.join(" | ")})"
          else
            types.join(" | ")
          end
        end

        def each_type(&block)
          if block_given?
            types.each(&block)
          else
            enum_for :each_type
          end
        end

        def map_type(&block)
          if block_given?
            Union.new(types: types.map(&block), location: location)
          else
            enum_for :map_type
          end
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
          other.is_a?(Intersection) && other.types == types
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

        def sub(s)
          self.class.new(types: types.map {|ty| ty.sub(s) },
                         location: location)
        end

        def to_s(level = 0)
          strs = types.map {|ty| ty.to_s(2) }
          if level > 0
            "(#{strs.join(" & ")})"
          else
            strs.join(" & ")
          end
        end

        def each_type(&block)
          if block_given?
            types.each(&block)
          else
            enum_for :each_type
          end
        end

        def map_type(&block)
          if block_given?
            Intersection.new(types: types.map(&block), location: location)
          else
            enum_for :map_type
          end
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

          def to_s
            if name
              "#{type} #{name}"
            else
              "#{type}"
            end
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
              required_positionals: required_positionals.map {|param| param.map_type(&block) },
              optional_positionals: optional_positionals.map {|param| param.map_type(&block) },
              rest_positionals: rest_positionals&.yield_self {|param| param.map_type(&block) },
              trailing_positionals: trailing_positionals.map {|param| param.map_type(&block) },
              required_keywords: required_keywords.transform_values {|param| param.map_type(&block) },
              optional_keywords: optional_keywords.transform_values {|param| param.map_type(&block) },
              rest_keywords: rest_keywords&.yield_self {|param| param.map_type(&block) },
              return_type: yield(return_type)
            )
          else
            enum_for :map_type
          end
        end

        def each_type
          if block_given?
            required_positionals.each {|param| yield param.type }
            optional_positionals.each {|param| yield param.type }
            rest_positionals&.yield_self {|param| yield param.type }
            trailing_positionals.each {|param| yield param.type }
            required_keywords.each_value {|param| yield param.type }
            optional_keywords.each_value {|param| yield param.type }
            rest_keywords&.yield_self {|param| yield param.type }
            yield(return_type)
          else
            enum_for :each_type
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
            rest_keywords: rest_keywords,
            return_type: return_type
          }.to_json(*a)
        end

        def sub(s)
          map_type {|ty| ty.sub(s) }
        end

        def self.empty(return_type)
          Function.new(
            required_positionals: [],
            optional_positionals: [],
            rest_positionals: nil,
            trailing_positionals: [],
            required_keywords: {},
            optional_keywords: {},
            rest_keywords: nil,
            return_type: return_type
          )
        end

        def with_return_type(type)
          Function.new(
            required_positionals: required_positionals,
            optional_positionals: optional_positionals,
            rest_positionals: rest_positionals,
            trailing_positionals: trailing_positionals,
            required_keywords: required_keywords,
            optional_keywords: optional_keywords,
            rest_keywords: rest_keywords,
            return_type: type
          )
        end

        def update(required_positionals: self.required_positionals, optional_positionals: self.optional_positionals, rest_positionals: self.rest_positionals, trailing_positionals: self.trailing_positionals,
                   required_keywords: self.required_keywords, optional_keywords: self.optional_keywords, rest_keywords: self.rest_keywords, return_type: self.return_type)
          Function.new(
            required_positionals: required_positionals,
            optional_positionals: optional_positionals,
            rest_positionals: rest_positionals,
            trailing_positionals: trailing_positionals,
            required_keywords: required_keywords,
            optional_keywords: optional_keywords,
            rest_keywords: rest_keywords,
            return_type: return_type
          )
        end

        def empty?
          required_positionals.empty? &&
            optional_positionals.empty? &&
            !rest_positionals &&
            trailing_positionals.empty? &&
            required_keywords.empty? &&
            optional_keywords.empty? &&
            !rest_keywords
        end

        def param_to_s
          params = []
          params.push(*required_positionals.map(&:to_s))
          params.push(*optional_positionals.map {|p| "?#{p}"})
          params.push("*#{rest_positionals}") if rest_positionals
          params.push(*trailing_positionals.map(&:to_s))
          params.push(*required_keywords.map {|name, param| "#{name}: #{param}" })
          params.push(*optional_keywords.map {|name, param| "?#{name}: #{param}" })
          params.push("**#{rest_keywords}") if rest_keywords

          params.join(", ")
        end

        def return_to_s
          return_type.to_s(1)
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

        def sub(s)
          self.class.new(type: type.sub(s), location: location)
        end

        def to_s(level = 0)
          "^(#{type.param_to_s}) -> #{type.return_to_s}".lstrip
        end

        def each_type(&block)
          if block_given?
            type.each_type(&block)
          else
            enum_for :each_type
          end
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
        include NoSubst
        include EmptyEachType

        def to_json(*a)
          { class: :literal, literal: literal.inspect, location: location }.to_json(*a)
        end

        def to_s(level = 0)
          literal.inspect
        end
      end
    end
  end
end

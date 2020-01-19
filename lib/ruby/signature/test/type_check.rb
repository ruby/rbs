module Ruby
  module Signature
    module Test
      class TypeCheck
        attr_reader :self_class
        attr_reader :builder

        def initialize(self_class:, builder:)
          @self_class = self_class
          @builder = builder
        end

        def check(value, type)
          case type
          when Types::Bases::Any
            true
          when Types::Bases::Bool
            true
          when Types::Bases::Top
            true
          when Types::Bases::Bottom
            false
          when Types::Bases::Void
            true
          when Types::Bases::Self
            Test.call(value, IS_AP, self_class)
          when Types::Bases::Nil
            Test.call(value, IS_AP, ::NilClass)
          when Types::Bases::Class
            Test.call(value, IS_AP, Class)
          when Types::Bases::Instance
            Test.call(value, IS_AP, self_class)
          when Types::ClassInstance
            klass = Object.const_get(type.name.to_s)
            if klass == ::Array
              Test.call(value, IS_AP, klass) && value.all? {|v| check(v, type.args[0]) }
            elsif klass == ::Hash
              Test.call(value, IS_AP, klass) && value.all? {|k, v| check(k, type.args[0]) && check(v, type.args[1]) }
            else
              Test.call(value, IS_AP, klass)
            end
          when Types::ClassSingleton
            klass = Object.const_get(type.name.to_s)
            value == klass
          when Types::Interface, Types::Variable
            true
          when Types::Literal
            value == type.literal
          when Types::Union
            type.types.any? {|type| check(value, type) }
          when Types::Intersection
            type.types.all? {|type| check(value, type) }
          when Types::Optional
            Test.call(value, IS_AP, ::NilClass) || check(value, type.type)
          when Types::Alias
            check(value, builder.expand_alias(type.name))
          when Types::Tuple
            Test.call(value, IS_AP, ::Array) &&
              type.types.map.with_index {|ty, index| check(value[index], ty) }.all?
          when Types::Record
            Test::call(value, IS_AP, ::Hash)
          when Types::Proc
            Test::call(value, IS_AP, ::Proc)
          else
            false
          end
        end
      end
    end
  end
end

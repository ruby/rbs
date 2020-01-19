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

        def value(val, type)
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
            Test.call(val, IS_AP, self_class)
          when Types::Bases::Nil
            Test.call(val, IS_AP, ::NilClass)
          when Types::Bases::Class
            Test.call(val, IS_AP, Class)
          when Types::Bases::Instance
            Test.call(val, IS_AP, self_class)
          when Types::ClassInstance
            klass = Object.const_get(type.name.to_s)
            if klass == ::Array
              Test.call(val, IS_AP, klass) && val.all? {|v| value(v, type.args[0]) }
            elsif klass == ::Hash
              Test.call(val, IS_AP, klass) && val.all? {|k, v| value(k, type.args[0]) && value(v, type.args[1]) }
            else
              Test.call(val, IS_AP, klass)
            end
          when Types::ClassSingleton
            klass = Object.const_get(type.name.to_s)
            val == klass
          when Types::Interface, Types::Variable
            true
          when Types::Literal
            val == type.literal
          when Types::Union
            type.types.any? {|type| value(val, type) }
          when Types::Intersection
            type.types.all? {|type| value(val, type) }
          when Types::Optional
            Test.call(val, IS_AP, ::NilClass) || value(val, type.type)
          when Types::Alias
            value(val, builder.expand_alias(type.name))
          when Types::Tuple
            Test.call(val, IS_AP, ::Array) &&
              type.types.map.with_index {|ty, index| value(val[index], ty) }.all?
          when Types::Record
            Test::call(val, IS_AP, ::Hash)
          when Types::Proc
            Test::call(val, IS_AP, ::Proc)
          else
            false
          end
        end
      end
    end
  end
end

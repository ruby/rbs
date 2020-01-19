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

        def args(method_name, method_type, fun, call, errors, type_error:, argument_error:)
          test = zip_args(call.arguments, call.keywords, fun) do |val, param|
            unless self.value(val, param.type)
              errors << type_error.new(klass: self_class,
                                       method_name: method_name,
                                       method_type: method_type,
                                       param: param,
                                       value: val)
            end
          end

          unless test
            errors << argument_error.new(klass: self_class,
                                         method_name: method_name,
                                         method_type: method_type)
          end
        end

        def return(method_name, method_type, fun, call, errors, return_error:)
          unless value(call.return_value, fun.return_type)
            errors << return_error.new(klass: self_class,
                                       method_name: method_name,
                                       method_type: method_type,
                                       type: fun.return_type,
                                       value: call.return_value)
          end
        end

        def zip_keyword_args(hash, fun)
          fun.required_keywords.each do |name, param|
            if hash.key?(name)
              yield(hash[name], param)
            else
              return false
            end
          end

          fun.optional_keywords.each do |name, param|
            if hash.key?(name)
              yield(hash[name], param)
            end
          end

          hash.each do |name, value|
            next if fun.required_keywords.key?(name)
            next if fun.optional_keywords.key?(name)

            if fun.rest_keywords
              yield value, fun.rest_keywords
            else
              return false
            end
          end

          true
        end

        def zip_args(args, kwargs, fun, &block)
          case
          when args.empty? && kwargs.empty?
            if fun.required_positionals.empty? && fun.trailing_positionals.empty? && fun.required_keywords.empty?
              true
            else
              false
            end
          when !fun.required_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_head
              yield(args.first, param)
              zip_args(args.drop(1), kwargs, fun_, &block)
            end
          when fun.has_keyword?
            yield_self do
              if !kwargs.empty?
                zip_keyword_args(kwargs, fun, &block) &&
                  zip_args(args,
                           {},
                           fun.update(required_keywords: {}, optional_keywords: {}, rest_keywords: nil),
                           &block)
              else
                fun.required_keywords.empty? &&
                  zip_args(args,
                           kwargs,
                           fun.update(required_keywords: {}, optional_keywords: {}, rest_keywords: nil),
                           &block)
              end
            end
          when !fun.trailing_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_tail
              yield(args.last, param)
              zip_args(args.take(args.size - 1), kwargs, fun_, &block)
            end
          when !fun.optional_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_head
              yield(args.first, param)
              zip_args(args.drop(1), kwargs, fun_, &block)
            end
          when fun.rest_positionals
            yield_self do
              yield(args.first, fun.rest_positionals)
              zip_args(args.drop(1), kwargs, fun, &block)
            end
          else
            false
          end
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

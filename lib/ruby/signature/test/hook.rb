require "ruby/signature"
require "pp"

module Ruby
  module Signature
    module Test
      class Hook
        IS_AP = Kernel.instance_method(:is_a?)
        DEFINE_METHOD = Module.instance_method(:define_method)
        INSTANCE_EVAL = BasicObject.instance_method(:instance_eval)
        INSTANCE_EXEC = BasicObject.instance_method(:instance_exec)
        METHOD = Kernel.instance_method(:method)
        CLASS = Kernel.instance_method(:class)
        SINGLETON_CLASS = Kernel.instance_method(:singleton_class)
        PP = Kernel.instance_method(:pp)

        module Errors
          ArgumentTypeError =
            Struct.new(:klass, :method_name, :method_type, :param, :value, keyword_init: true)
          BlockArgumentTypeError =
            Struct.new(:klass, :method_name, :method_type, :param, :value, keyword_init: true)
          ArgumentError =
            Struct.new(:klass, :method_name, :method_type, keyword_init: true)
          BlockArgumentError =
            Struct.new(:klass, :method_name, :method_type, keyword_init: true)
          ReturnTypeError =
            Struct.new(:klass, :method_name, :method_type, :type, :value, keyword_init: true)
          BlockReturnTypeError =
            Struct.new(:klass, :method_name, :method_type, :type, :value, keyword_init: true)

          UnexpectedBlockError = Struct.new(:klass, :method_name, :method_type, keyword_init: true)
          MissingBlockError = Struct.new(:klass, :method_name, :method_type, keyword_init: true)

          UnresolvedOverloadingError = Struct.new(:klass, :method_name, :method_types, keyword_init: true)

          def self.format_param(param)
            if param.name
              "`#{param.type}` (#{param.name})"
            else
              "`#{param.type}`"
            end
          end

          def self.to_string(error)
            method = "#{error.klass.name}#{error.method_name}"
            case error
            when ArgumentTypeError
              "[#{method}] ArgumentTypeError: expected #{format_param error.param} but given `#{error.value.inspect}`"
            when BlockArgumentTypeError
              "[#{method}] BlockArgumentTypeError: expected #{format_param error.param} but given `#{error.value.inspect}`"
            when ArgumentError
              "[#{method}] ArgumentError: expected method type #{error.method_type}"
            when BlockArgumentError
              "[#{method}] BlockArgumentError: expected method type #{error.method_type}"
            when ReturnTypeError
              "[#{method}] ReturnTypeError: expected `#{error.type}` but returns `#{error.value.inspect}`"
            when BlockReturnTypeError
              "[#{method}] BlockReturnTypeError: expected `#{error.type}` but returns `#{error.value.inspect}`"
            when UnexpectedBlockError
              "[#{method}] UnexpectedBlockError: unexpected block is given for `#{error.method_type}`"
            when MissingBlockError
              "[#{method}] MissingBlockError: required block is missing for `#{error.method_type}`"
            when UnresolvedOverloadingError
              "[#{method}] UnresolvedOverloadingError: couldn't find a suitable overloading"
            else
              raise "Unexpected error: #{error.inspect}"
            end
          end
        end

        attr_reader :env
        attr_reader :logger

        attr_reader :instance_module
        attr_reader :instance_methods
        attr_reader :singleton_module
        attr_reader :singleton_methods

        attr_reader :klass
        attr_reader :errors

        ArgsReturn = Struct.new(:arguments, :return_value, keyword_init: true)
        Call = Struct.new(:method_call, :block_call, :block_given, keyword_init: true)

        def initialize(env, klass, logger:)
          @env = env
          @logger = logger
          @klass = klass

          @instance_module = Module.new
          @instance_methods = []

          @singleton_module = Module.new
          @singleton_methods = []

          @errors = []
        end

        def prepend!
          klass.prepend @instance_module
          klass.singleton_class.prepend @singleton_module

          if block_given?
            yield
            disable
          end

          self
        end

        def self.install(env, klass, logger:)
          new(env, klass, logger: logger).prepend!
        end

        def refinement
          klass = self.klass
          instance_module = self.instance_module
          singleton_module = self.singleton_module

          Module.new do
            refine klass do
              prepend instance_module
            end

            refine klass.singleton_class do
              prepend singleton_module
            end
          end
        end

        def verify_all
          type_name = Namespace.parse(klass.name).to_type_name.absolute!

          builder = DefinitionBuilder.new(env: env)
          builder.build_instance(type_name).tap do |definition|
            definition.methods.each do |name, method|
              if method.defined_in.name.absolute! == type_name
                unless method.annotations.any? {|a| a.string == "rbs:test:skip" }
                  logger.info "Installing hook on #{type_name}##{name}: #{method.method_types.join(" | ")}"
                  verify instance_method: name, types: method.method_types
                else
                  logger.info "Skipping test of #{type_name}##{name}"
                end
              end
            end
          end

          builder.build_singleton(type_name).tap do |definition|
            definition.methods.each do |name, method|
              if method.defined_in&.name&.absolute! == type_name || name == :new
                unless method.annotations.any? {|a| a.string == "rbs:test:skip" }
                  logger.info "Installing hook on #{type_name}.#{name}: #{method.method_types.join(" | ")}"
                  verify singleton_method: name, types: method.method_types
                else
                  logger.info "Skipping test of #{type_name}##{name}"
                end
              end
            end
          end

          self
        end

        def delegation(name, method_types, method_name)
          hook = self

          proc do |*args, &block|
            hook.logger.debug { "#{method_name} receives arguments: #{args.inspect}" }

            block_call = nil

            if block
              original_block = block

              block = hook.call(Object.new, INSTANCE_EVAL) do |fresh_obj|
                proc do |*as|
                  hook.logger.debug { "#{method_name} receives block arguments: #{as.inspect}" }

                  ret = if self.equal?(fresh_obj)
                          original_block[*as]
                        else
                          hook.call(self, INSTANCE_EXEC, *as, &original_block)
                        end

                  block_call = ArgsReturn.new(arguments: as, return_value: ret)

                  hook.logger.debug { "#{method_name} returns from block: #{ret.inspect}" }

                  ret
                end
              end
            end

            method = hook.call(self, METHOD, name)
            prepended = hook.call(self, CLASS).ancestors.include?(hook.instance_module) || hook.call(self, SINGLETON_CLASS).ancestors.include?(hook.singleton_module)
            result = if prepended
                       method.super_method.call(*args, &block)
                     else
                       # Using refinement
                       method.call(*args, &block)
                     end

            hook.logger.debug { "#{method_name} returns: #{result.inspect}" }

            call = Call.new(method_call: ArgsReturn.new(arguments: args, return_value: result),
                            block_call: block_call,
                            block_given: block != nil)

            errorss = method_types.map do |method_type|
              hook.test(method_name, method_type, call)
            end

            new_errors = []

            if errorss.none?(&:empty?)
              if (best_errors = hook.find_best_errors(errorss))
                new_errors.push(*best_errors)
              else
                new_errors << Errors::UnresolvedOverloadingError.new(
                  klass: hook.klass,
                  method_name: method_name,
                  method_types: method_types
                )
              end
            end

            new_errors.each do |error|
              hook.logger.error Errors.to_string(error)
            end

            hook.errors.push(*new_errors)
            result
          end
        end

        def verify(instance_method: nil, singleton_method: nil, types:)
          method_types = types.map do |type|
            case type
            when String
              Parser.parse_method_type(type)
            else
              type
            end
          end

          case
          when instance_method
            instance_methods << instance_method
            call(self.instance_module, DEFINE_METHOD, instance_method, &delegation(instance_method, method_types, "##{instance_method}"))
          when singleton_method
            call(self.singleton_module, DEFINE_METHOD, singleton_method, &delegation(singleton_method, method_types, ".#{singleton_method}"))
          end
          self
        end

        def find_best_errors(errorss)
          if errorss.size == 1
            errorss[0]
          else
            no_arity_errors = errorss.select do |errors|
              errors.none? do |error|
                error.is_a?(Errors::ArgumentError) ||
                  error.is_a?(Errors::BlockArgumentError) ||
                  error.is_a?(Errors::MissingBlockError) ||
                  error.is_a?(Errors::UnexpectedBlockError)
              end
            end

            unless no_arity_errors.empty?
              # Choose a error set which doesn't include arity error
              return no_arity_errors[0] if no_arity_errors.size == 1
            end
          end
        end

        def self.backtrace(skip: 2)
          raise
        rescue => exn
          exn.backtrace.drop(skip)
        end

        def test(method_name, method_type, call)
          errors = []

          typecheck_args(method_name, method_type, method_type.type, call.method_call, errors, type_error: Errors::ArgumentTypeError, argument_error: Errors::ArgumentError)
          typecheck_return(method_name, method_type, method_type.type, call.method_call, errors, return_error: Errors::ReturnTypeError)

          if method_type.block
            if call.block_call
              typecheck_args(method_name, method_type, block_args(method_type.block.type), call.block_call, errors, type_error: Errors::BlockArgumentTypeError, argument_error: Errors::BlockArgumentError)
              typecheck_return(method_name, method_type, method_type.block.type, call.block_call, errors, return_error: Errors::BlockReturnTypeError)
            else
              if method_type.block.required
                errors << Errors::MissingBlockError.new(klass: klass, method_name: method_name, method_type: method_type)
              end
            end
          else
            if call.block_given
              errors << Errors::UnexpectedBlockError.new(klass: klass, method_name: method_name, method_type: method_type)
            end
          end

          errors
        end

        def run
          yield
          self
        ensure
          disable
        end

        def call(receiver, method, *args, &block)
          method.bind(receiver).call(*args, &block)
        end

        def disable
          self.instance_module.remove_method(*instance_methods)
          self.singleton_module.remove_method(*singleton_methods)
          self
        end

        def typecheck_args(method_name, method_type, fun, value, errors, type_error:, argument_error:)
          test = zip_args(value.arguments, fun) do |value, param|
            unless type_check(value, param.type)
              errors << type_error.new(klass: klass,
                                       method_name: method_name,
                                       method_type: method_type,
                                       param: param,
                                       value: value)
            end
          end

          unless test
            errors << argument_error.new(klass: klass,
                                         method_name: method_name,
                                         method_type: method_type)
          end
        end

        def typecheck_return(method_name, method_type, fun, value, errors, return_error:)
          unless type_check(value.return_value, fun.return_type)
            errors << return_error.new(klass: klass,
                                       method_name: method_name,
                                       method_type: method_type,
                                       type: fun.return_type,
                                       value: value.return_value)
          end
        end

        def keyword?(value)
          value.is_a?(Hash) && value.keys.all? {|key| key.is_a?(Symbol) }
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

        def block_args(fun)
          fun.update(
               required_positionals: [],
               trailing_positionals: [],
               optional_positionals: fun.required_positionals + fun.optional_positionals,
               rest_positionals:
                 if fun.rest_positionals
                   unless fun.trailing_positionals.empty?
                     types = [
                       fun.rest_positionals,
                       *fun.trailing_positionals,
                     ].compact
                     Types::Union.new(types: types, location: nil)
                   else
                     fun.rest_positionals
                   end
                 else
                   Types::Function::Param.new(name: nil, type: Types::Bases::Any.new(location: nil))
                 end)
        end

        def zip_args(args, fun, &block)
          case
          when args.empty?
            if fun.required_positionals.empty? && fun.trailing_positionals.empty? && fun.required_keywords.empty?
              true
            else
              false
            end
          when !fun.required_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_head
              yield(args.first, param)
              zip_args(args.drop(1), fun_, &block)
            end
          when fun.has_keyword?
            yield_self do
              hash = args.last
              if keyword?(hash)
                zip_keyword_args(hash, fun, &block) &&
                  zip_args(args.take(args.size - 1),
                           fun.update(required_keywords: {}, optional_keywords: {}, rest_keywords: nil),
                           &block)
              else
                fun.required_keywords.empty? &&
                  zip_args(args,
                           fun.update(required_keywords: {}, optional_keywords: {}, rest_keywords: nil),
                           &block)
              end
            end
          when !fun.trailing_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_tail
              yield(args.last, param)
              zip_args(args.take(args.size - 1), fun_, &block)
            end
          when !fun.optional_positionals.empty?
            yield_self do
              param, fun_ = fun.drop_head
              yield(args.first, param)
              zip_args(args.drop(1), fun_, &block)
            end
          when fun.rest_positionals
            yield_self do
              yield(args.first, fun.rest_positionals)
              zip_args(args.drop(1), fun, &block)
            end
          else
            false
          end
        end

        def type_check(value, type)
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
            call(value, IS_AP, klass)
          when Types::Bases::Nil
            call(value, IS_AP, NilClass)
          when Types::Bases::Class
            call(value, IS_AP, Class)
          when Types::Bases::Instance
            call(value, IS_AP, klass)
          when Types::ClassInstance
            klass = Object.const_get(type.name.to_s)
            if klass == ::Array
              call(value, IS_AP, klass) && value.all? {|v| type_check(v, type.args[0]) }
            else
              call(value, IS_AP, klass)
            end
          when Types::ClassSingleton
            klass = Object.const_get(type.name.to_s)
            value == klass
          when Types::Interface, Types::Variable
            true
          when Types::Literal
            value == type.literal
          when Types::Union
            type.types.any? {|type| type_check(value, type) }
          when Types::Intersection
            type.types.all? {|type| type_check(value, type) }
          when Types::Optional
            call(value, IS_AP, NilClass) || type_check(value, type.type)
          when Types::Alias
            type_check(value, env.find_alias(type.name).type)
          when Types::Tuple
            call(value, IS_AP, ::Array) &&
              type.types.map.with_index {|ty, index| type_check(value[index], ty) }.all?
          when Types::Record
            call(value, IS_AP, ::Hash)
          when Types::Proc
            call(value, IS_AP, ::Proc)
          else
            false
          end
        end
      end
    end
  end
end

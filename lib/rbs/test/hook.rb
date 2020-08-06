require "rbs"
require "pp"

module RBS
  module Test
    module Hook
      OPERATORS = {
        :== => "eqeq",
        :=== => "eqeqeq",
        :!= => "noteq",
        :+ => "plus",
        :- => "minus",
        :* => "star",
        :/ => "slash",
        :> => "gt",
        :>= => "gteq",
        :< => "lt",
        :<= => "lteq",
        :<=> => "ufo",
        :& => "amp",
        :| => "vbar",
        :^ => "hat",
        :! => "not",
        :<< => "lshift",
        :>> => "rshift",
        :~ => "tilda"
      }
      def self.alias_names(target)
        case target
        when *OPERATORS.keys
          name = OPERATORS[target]
          [
            "#{name}____with__#{Test.suffix}",
            "#{name}____without__#{Test.suffix}"
          ]
        else
          aliased_target, punctuation = target.to_s.sub(/([?!=])$/, ''), $1

          [
            "#{aliased_target}__with__#{Test.suffix}#{punctuation}",
            "#{aliased_target}__without__#{Test.suffix}#{punctuation}"
          ]
        end
      end

      def self.setup_alias_method_chain(klass, target)
        with_method, without_method = alias_names(target)

        RBS.logger.debug "alias name: #{target}, #{with_method}, #{without_method}"

        klass.instance_eval do
          alias_method without_method, target
          alias_method target, with_method

          case
          when public_method_defined?(without_method)
            public target
          when protected_method_defined?(without_method)
            protected target
          when private_method_defined?(without_method)
            private target
          end
        end
      end

      def self.hook_method_source(prefix, method_name, key)
        with_name, without_name = alias_names(method_name)
        full_method_name = "#{prefix}#{method_name}"

        [__LINE__ + 1, <<RUBY]
def #{with_name}(*args)
  ::RBS.logger.debug { "#{full_method_name} with arguments: [" + args.map(&:inspect).join(", ") + "]" }

  begin
    return_from_call = false
    block_calls = []

    if block_given?
      result = __send__(:"#{without_name}", *args) do |*block_args|
        return_from_block = false

        begin
          block_result = yield(*block_args)
          return_from_block = true
        ensure
          exn = $!

          case
          when return_from_block
            # Returned from yield
            block_calls << ::RBS::Test::ArgumentsReturn.return(
              arguments: block_args,
              value: block_result
            )
          when exn
            # Exception
            block_calls << ::RBS::Test::ArgumentsReturn.exception(
              arguments: block_args,
              exception: exn
            )
          else
            # break?
            block_calls << ::RBS::Test::ArgumentsReturn.break(
              arguments: block_args
            )
          end
        end

        block_result
      end
    else
      result = __send__(:"#{without_name}", *args)
    end
    return_from_call = true
    result
  ensure
    exn = $!

    case
    when return_from_call
      ::RBS.logger.debug { "#{full_method_name} return with value: " + result.inspect }
      method_call = ::RBS::Test::ArgumentsReturn.return(
        arguments: args,
        value: result
      )
    when exn
      ::RBS.logger.debug { "#{full_method_name} exit with exception: " + exn.inspect }
      method_call = ::RBS::Test::ArgumentsReturn.exception(
        arguments: args,
        exception: exn
      )
    else
      ::RBS.logger.debug { "#{full_method_name} exit with jump" }
      method_call = ::RBS::Test::ArgumentsReturn.break(arguments: args)
    end

    trace = ::RBS::Test::CallTrace.new(
      method_name: #{method_name.inspect},
      method_call: method_call,
      block_calls: block_calls,
      block_given: block_given?,
    )

    ::RBS::Test::Observer.notify(#{key.inspect}, self, trace)
  end

  result
end

ruby2_keywords :#{with_name}
RUBY
      end

      def self.hook_instance_method(klass, method, key:)
        line, source = hook_method_source("#{klass}#", method, key)

        klass.module_eval(source, __FILE__, line)
        setup_alias_method_chain klass, method
      end

      def self.hook_singleton_method(klass, method, key:)
        line, source = hook_method_source("#{klass}.",method, key)

        klass.singleton_class.module_eval(source, __FILE__, line)
        setup_alias_method_chain klass.singleton_class, method
      end
    end
  end
end

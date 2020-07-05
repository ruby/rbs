module RBS
  module Test
    class Tester
      attr_reader :env
      attr_reader :checkers

      def initialize(env:)
        @env = env
        @checkers = []
      end

      def factory
        @factory ||= Factory.new
      end

      def builder
        @builder ||= DefinitionBuilder.new(env: env)
      end

      def install!(klass)
        RBS.logger.info { "Installing runtime type checker in #{klass}..." }

        type_name = factory.type_name(klass.name).absolute!

        builder.build_instance(type_name).tap do |definition|
          instance_key = new_key(type_name, "InstanceChecker")
          Observer.register(instance_key, MethodCallTester.new(klass, builder, definition, kind: :instance))

          definition.methods.each do |name, method|
            if method.implemented_in == type_name
              RBS.logger.info { "Setting up method hook in ##{name}..." }
              Hook.hook_instance_method klass, name, key: instance_key
            end
          end
        end

        builder.build_singleton(type_name).tap do |definition|
          singleton_key = new_key(type_name, "SingletonChecker")
          Observer.register(singleton_key, MethodCallTester.new(klass.singleton_class, builder, definition, kind: :singleton))

          definition.methods.each do |name, method|
            if method.implemented_in == type_name || name == :new
              RBS.logger.info { "Setting up method hook in .#{name}..." }
              Hook.hook_singleton_method klass, name, key: singleton_key
            end
          end
        end
      end

      def new_key(type_name, prefix)
        "#{prefix}__#{type_name}__#{SecureRandom.hex(10)}"
      end

      class TypeError < Exception
        attr_reader :errors

        def initialize(errors)
          @errors = errors

          super "TypeError: #{errors.map {|e| Errors.to_string(e) }.join(", ")}"
        end
      end

      class MethodCallTester
        attr_reader :self_class
        attr_reader :definition
        attr_reader :builder
        attr_reader :kind

        def initialize(self_class, builder, definition, kind:)
          @self_class = self_class
          @definition = definition
          @builder = builder
          @kind = kind
        end

        def env
          builder.env
        end

        def check
          @check ||= TypeCheck.new(self_class: self_class, builder: builder)
        end

        def format_method_name(name)
          case kind
          when :instance
            "##{name}"
          when :singleton
            ".#{name}"
          end
        end

        def call(receiver, trace)
          method_name = trace.method_name
          method = definition.methods[method_name]
          if method
            RBS.logger.debug { "Type checking `#{self_class}#{format_method_name(method_name)}`..."}
            errors = check.overloaded_call(method, format_method_name(method_name), trace, errors: [])

            if errors.empty?
              RBS.logger.debug { "No type error detected 👏" }
            else
              RBS.logger.debug { "Detected type error 🚨" }
              raise TypeError.new(errors)
            end
          else
            RBS.logger.error { "Type checking `#{self_class}#{method_name}` call but no method found in definition" }
          end
        end
      end
    end
  end
end

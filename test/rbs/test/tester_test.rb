require "test_helper"
require "delegate"
require "rbs/test"

class RBS::Test::TesterTest < Test::Unit::TestCase
  include TestHelper

  ArgumentsReturn = RBS::Test::ArgumentsReturn
  CallTrace = RBS::Test::CallTrace

  def test_method_call_tester
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  attr_reader x: Integer
  attr_reader y: Integer

  def initialize: (x: Integer, y: Integer) -> void

  def move: (?x: Integer, ?y: Integer) -> void
end
EOF
      manager.build do |env, path|
        builder = RBS::DefinitionBuilder.new(env: env)
        definition = builder.build_instance(type_name("::Hello"))

        checker = RBS::Test::Tester::MethodCallTester.new(Object, builder, definition, kind: :instance, sample_size: 100, unchecked_classes: [])

        # No type error detected
        checker.call(
          Object.new,
          CallTrace.new(
            method_name: :move,
            method_call: ArgumentsReturn.return(arguments: [{ x: 1 }], value: nil),
            block_calls: [],
            block_given: false
          )
        )

        # Type error detected
        assert_raises RBS::Test::Tester::TypeError do
          checker.call(
            Object.new,
            CallTrace.new(
              method_name: :move,
              method_call: ArgumentsReturn.return(arguments: [1, 2], value: nil),
              block_calls: [],
              block_given: false
            )
          )
        end
      end
    end
  end

  class Foo
  end

  # See also https://github.com/ruby/rbs/issues/1636
  def test_redefine_class
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module RBS
  module Test
    module TesterTest
      class Foo
        def foo: (Foo) -> void
      end
    end
  end
end
EOF
      manager.build do |env, path|
        builder = RBS::DefinitionBuilder.new(env: env)
        definition = builder.build_instance(type_name("::RBS::Test::TesterTest::Foo"))

        checker = RBS::Test::Tester::MethodCallTester.new(Object, builder, definition, kind: :instance, sample_size: 100, unchecked_classes: [])

        checker.call(
          Object.new,
          CallTrace.new(
            method_name: :foo,
            method_call: ArgumentsReturn.return(arguments: [Foo.new], value: nil),
            block_calls: [],
            block_given: false
          )
        )

        self.class.send(:remove_const, :Foo)
        self.class.const_set(:Foo, Class.new)

        checker.call(
          Object.new,
          CallTrace.new(
            method_name: :foo,
            method_call: ArgumentsReturn.return(arguments: [Foo.new], value: nil),
            block_calls: [],
            block_given: false
          )
        )
      end
    end
  end

  class Base
  end

  class Sub < Base
  end

  def test_self_and_instance_types_on_subclass_receiver
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module RBS
  module Test
    module TesterTest
      class Base
        def self.make: () -> instance
        def self.itself: () -> self
        def copy: () -> self
        def klass: () -> class
      end
      class Sub < Base
      end
    end
  end
end
EOF
      manager.build do |env, path|
        builder = RBS::DefinitionBuilder.new(env: env)

        singleton_checker = RBS::Test::Tester::MethodCallTester.new(
          Base.singleton_class, builder, builder.build_singleton(type_name("::RBS::Test::TesterTest::Base")),
          kind: :singleton, sample_size: 100, unchecked_classes: []
        )
        instance_checker = RBS::Test::Tester::MethodCallTester.new(
          Base, builder, builder.build_instance(type_name("::RBS::Test::TesterTest::Base")),
          kind: :instance, sample_size: 100, unchecked_classes: []
        )

        returning = ->(name, value) {
          CallTrace.new(method_name: name, method_call: ArgumentsReturn.return(arguments: [], value: value), block_calls: [], block_given: false)
        }

        # `instance` is the receiver class of a singleton method call
        singleton_checker.call(Sub, returning[:make, Sub.new])
        assert_raises RBS::Test::Tester::TypeError do
          singleton_checker.call(Sub, returning[:make, Base.new])
        end
        assert_raises RBS::Test::Tester::TypeError do
          singleton_checker.call(Base, returning[:make, 1])
        end

        # `self` in a singleton method is the receiver class itself
        singleton_checker.call(Sub, returning[:itself, Sub])
        assert_raises RBS::Test::Tester::TypeError do
          singleton_checker.call(Sub, returning[:itself, Base])
        end

        # `self` in an instance method is the receiver's class
        instance_checker.call(Sub.new, returning[:copy, Sub.new])
        assert_raises RBS::Test::Tester::TypeError do
          instance_checker.call(Sub.new, returning[:copy, Base.new])
        end

        # `class` in an instance method is the singleton class of the receiver's class
        instance_checker.call(Sub.new, returning[:klass, Sub])
        assert_raises RBS::Test::Tester::TypeError do
          instance_checker.call(Sub.new, returning[:klass, Base])
        end
      end
    end
  end

  class Response < Delegator
    attr_accessor :data

    def initialize(data)
      @data = data
    end

    def __getobj__
      @data
    end
  end

  class Data < Struct.new(:foo)
  end

  def test_delegator
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module RBS
  module Test
    module TesterTest
      interface _Response
        def data: () -> Data
        def foo: () -> Integer
      end
      class Foo
        def get_response: () -> _Response
      end
      class Data
        def foo: () -> Integer
      end
    end
  end
end
EOF
      manager.build do |env, path|
        builder = RBS::DefinitionBuilder.new(env: env)
        definition = builder.build_instance(type_name("::RBS::Test::TesterTest::Foo"))
        value = Response.new(Data.new(42))
        checker = RBS::Test::Tester::MethodCallTester.new(Object, builder, definition, kind: :instance, sample_size: 100, unchecked_classes: [])
        checker.call(
          Object.new,
          CallTrace.new(
            method_name: :get_response,
            method_call: ArgumentsReturn.return(arguments: [], value: value),
            block_calls: [],
            block_given: false
          )
        )
      end
    end
  end
end

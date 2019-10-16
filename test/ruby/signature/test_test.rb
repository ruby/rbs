require "test_helper"

require "ruby/signature/test"
require "logger"

class Ruby::Signature::TestTest < Minitest::Test
  include TestHelper

  Test = Ruby::Signature::Test

  def io
    @io ||= StringIO.new
  end

  def logger
    @logger ||= Logger.new(io).tap do |l|
      l.level = "debug"
    end
  end

  def test_verify_instance_method
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module X
end

class Foo
  extend X
end

module Y[A]
end

class Bar[X]
  include Y[X]
end
EOF
      manager.build do |env|
        klass = Class.new do
          def foo(*args)
            if block_given?
              (yield 123).to_s
            else
              :foo
            end
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :foo,
                         types: ["(::String x, ::Integer i, foo: 123 foo) { (Integer) -> Array[Integer] } -> ::String"])

        hook.run do
          instance = klass.new
          instance.foo { 1+2 }
          instance.foo("", 3, foo: 234) {}
          instance.foo
        end

        puts io.string
      end
    end
  end

  def test_verify_singleton_method
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def self.open: () { (Foo) -> void } -> Foo
end
EOF
      manager.build do |env|
        klass = Class.new do
          def self.open(&block)
            x = new
            instance_exec x, &block
            x
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(singleton_method: :open,
                         types: ["() { (::String) -> void } -> ::String"])

        hook.run do
          _foo = klass.open {|foo|
            1 + 2 + 3
          }
        end

        refute_empty hook.errors
        puts io.string
      end
    end
  end

  def test_verify_all
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def self.open: () { (String) -> void } -> Integer
  def foo: (*any) -> String
end
EOF
      manager.build do |env|
        klass = Class.new do
          def self.open(&block)
            x = new
            x.instance_exec "", &block
            1
          end

          def foo(*args)
            "hello foo"
          end

          def self.name
            "Foo"
          end
        end

        ::Object.const_set :Foo, klass

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger).verify_all

        hook.run do
          _foo = klass.open {
            1 + 2 + 3

            self.foo(1, 2, 3)
          }
        end

        puts io.string
        assert_empty hook.errors
      ensure
        ::Object.instance_eval do
          remove_const :Foo
        end
      end
    end
  end

  def test_type_check
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type foo = String | Integer
EOF
      manager.build do |env|
        hook = Ruby::Signature::Test::Hook.new(env, Object, logger: logger)

        assert hook.type_check(3, parse_type("::foo"))
        assert hook.type_check("3", parse_type("::foo"))
        refute hook.type_check(:foo, parse_type("::foo"))

        assert hook.type_check(Object, parse_type("singleton(::Object)"))
        assert hook.type_check(Object, parse_type("::Class"))
        refute hook.type_check(Object, parse_type("singleton(::String)"))
      end
    end
  end

  def test_typecheck_args
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type foo = String | Integer
EOF
      manager.build do |env|
        hook = Ruby::Signature::Test::Hook.new(env, Object, logger: logger)

        parse_method_type("(Integer) -> String").tap do |method_type|
          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [1], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors

          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: ["1"], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Hook::Errors::ArgumentTypeError) }

          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [1, 2], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Hook::Errors::ArgumentError) }

          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ hello: :world }], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Hook::Errors::ArgumentTypeError) }
        end

        parse_method_type("(foo: Integer, ?bar: String, **Symbol) -> String").tap do |method_type|
          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ foo: 31, baz: :baz }], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors

          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ foo: "foo" }], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Hook::Errors::ArgumentTypeError) }

          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ bar: "bar" }], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Hook::Errors::ArgumentError) }
        end

        parse_method_type("(?String, ?encoding: String) -> String").tap do |method_type|
          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ encoding: "ASCII-8BIT" }], return_value: "foo"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors
        end

        parse_method_type("(parent: any, type: any) -> any").tap do |method_type|
          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [{ parent: nil, type: nil }], return_value: nil),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors.map {|e| Test::Hook::Errors.to_string(e) }
        end

        parse_method_type("() { (Integer) -> void } -> void").tap do |method_type|
          errors = []

          hook.typecheck_args "#foo",
                              method_type,
                              hook.block_args(method_type.block.type),
                              Test::Hook::ArgsReturn.new(arguments: [], return_value: nil),
                              errors,
                              type_error: Test::Hook::Errors::BlockArgumentTypeError,
                              argument_error: Test::Hook::Errors::BlockArgumentError
          assert_empty errors.map {|e| Test::Hook::Errors.to_string(e) }

          errors.clear
          hook.typecheck_args "#foo",
                              method_type,
                              hook.block_args(method_type.block.type),
                              Test::Hook::ArgsReturn.new(arguments: [1,2], return_value: nil),
                              errors,
                              type_error: Test::Hook::Errors::BlockArgumentTypeError,
                              argument_error: Test::Hook::Errors::BlockArgumentError
          assert_empty errors.map {|e| Test::Hook::Errors.to_string(e) }
        end
      end
    end
  end
end

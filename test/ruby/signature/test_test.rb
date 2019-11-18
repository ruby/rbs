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
  def foo: (*untyped) -> String
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
            _bar = 1 + 2 + 3

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
type foo = String | Integer | [String, String] | ::Array[Integer]
type M::t = Integer
type M::s = t
EOF
      manager.build do |env|
        hook = Ruby::Signature::Test::Hook.new(env, Object, logger: logger)

        assert hook.type_check(3, parse_type("::foo"))
        assert hook.type_check("3", parse_type("::foo"))
        assert hook.type_check(["foo", "bar"], parse_type("::foo"))
        assert hook.type_check([1, 2, 3], parse_type("::foo"))
        refute hook.type_check(:foo, parse_type("::foo"))
        refute hook.type_check(["foo", 3], parse_type("::foo"))
        refute hook.type_check([1, 2, "3"], parse_type("::foo"))

        assert hook.type_check(Object, parse_type("singleton(::Object)"))
        assert hook.type_check(Object, parse_type("::Class"))
        refute hook.type_check(Object, parse_type("singleton(::String)"))

        assert hook.type_check(3, parse_type("::M::t"))
        assert hook.type_check(3, parse_type("::M::s"))
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

        parse_method_type("(parent: untyped, type: untyped) -> untyped").tap do |method_type|
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

        parse_method_type("(Integer?, *String) -> String").tap do |method_type|
          errors = []
          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [1], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors

          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [1, ''], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors

          hook.typecheck_args "#foo",
                              method_type,
                              method_type.type,
                              Test::Hook::ArgsReturn.new(arguments: [1, '', ''], return_value: "1"),
                              errors,
                              type_error: Test::Hook::Errors::ArgumentTypeError,
                              argument_error: Test::Hook::Errors::ArgumentError
          assert_empty errors
        end
      end
    end
  end

  def test_verify_block
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello
            yield ["3", 3]
          end

          def world
            yield "3", 3
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :hello,
                         types: ["() { (::String, ::Integer) -> void } -> void"])
                 .verify(instance_method: :world,
                         types: ["() { ([::String, ::Integer]) -> void } -> void"])

        hook.run do
          klass.new.hello { }
          klass.new.world { }
        end

        refute_empty hook.errors.select {|e| e.method_name == "#hello" }.map {|e| Test::Hook::Errors.to_string(e) }
        refute_empty hook.errors.select {|e| e.method_name == "#world" }.map {|e| Test::Hook::Errors.to_string(e) }
      end
    end
  end

  def test_verify_block_no_yelld
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :hello,
                         types: ["() { (::String, ::Integer) -> void } -> void"])
        hook.run do
          klass.new.hello { }
        end

        assert_empty hook.errors.map {|e| Test::Hook::Errors.to_string(e) }
      end
    end
  end

  def test_verify_block_no_yied
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :hello,
                         types: ["() { (::String, ::Integer) -> void } -> void"])
        hook.run do
          klass.new.hello { }
        end

        assert_empty hook.errors.map {|e| Test::Hook::Errors.to_string(e) }
      end
    end
  end

  def test_verify_block_not_given
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :hello,
                         types: ["() { (::String, ::Integer) -> void } -> void"])
        hook.run do
          klass.new.hello
        end

        refute_empty hook.errors.map {|e| Test::Hook::Errors.to_string(e) }
      end
    end
  end

  def test_verify_block_yielded_twice
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello
            yield
            yield "foo", 2
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .verify(instance_method: :hello,
                         types: ["() { (::String, ::Integer) -> void } -> void"])
        hook.run do
          klass.new.hello {}
        end

        refute_empty hook.errors.map {|e| Test::Hook::Errors.to_string(e) }
      end
    end
  end

  def test_verify_error
    SignatureManager.new do |manager|
      manager.build do |env|
        klass = Class.new do
          def hello()
            yield 30
          end

          def self.name
            "Foo"
          end
        end

        hook = Ruby::Signature::Test::Hook.install(env, klass, logger: logger)
                 .raise_on_error!
                 .verify(instance_method: :hello,
                         types: ["() { (String) -> void } -> void"])


        assert_raises(Ruby::Signature::Test::Hook::Error) do
          hook.run do
            klass.new.hello {|x| 30 }
          end
        end
      end
    end
  end
end

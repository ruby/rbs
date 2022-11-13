require "test_helper"

require "rbs/test"
require "logger"

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')

RSPEC_MOCK = -> { double('foo') }

class RBS::Test::TypeCheckTest < Test::Unit::TestCase
  include TestHelper
  include RBS

  def test_type_check
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Array[Elem]
end

type foo = String | Integer | [String, String] | ::Array[Integer]

module M
  type t = Integer
  type s = t
end

interface _ToInt
  def to_int: () -> Integer
end
EOF
      manager.build do |env|
        typecheck = Test::TypeCheck.new(
          self_class: Integer,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        assert typecheck.value(3, parse_type("::foo"))
        assert typecheck.value("3", parse_type("::foo"))
        assert typecheck.value(["foo", "bar"], parse_type("::foo"))
        assert typecheck.value([1, 2, 3], parse_type("::foo"))
        refute typecheck.value(:foo, parse_type("::foo"))
        refute typecheck.value(["foo", 3], parse_type("::foo"))
        refute typecheck.value([1, 2, "3"], parse_type("::foo"))

        assert typecheck.value(Object, parse_type("singleton(::Object)"))
        assert typecheck.value(Object, parse_type("::Class"))
        refute typecheck.value(Object, parse_type("singleton(::String)"))

        assert typecheck.value(String, parse_type("singleton(::String)"))
        assert typecheck.value(String, parse_type("singleton(::Object)"))
        refute typecheck.value(String, parse_type("singleton(::Integer)"))

        assert typecheck.value(3, parse_type("::M::t"))
        assert typecheck.value(3, parse_type("::M::s"))

        assert typecheck.value(3, parse_type("::_ToInt"))
        refute typecheck.value("3", parse_type("::_ToInt"))

        assert typecheck.value([1,2,3].each, parse_type("Enumerator[Integer, Array[Integer]]"))
        assert typecheck.value(loop, parse_type("Enumerator[nil, bot]"))

        assert typecheck.value(true, parse_type("bool"))
        assert typecheck.value(false, parse_type("bool"))
        refute typecheck.value(nil, parse_type("bool"))
        refute typecheck.value("", parse_type("bool"))
      end
    end
  end

  def test_type_check_instance_class
    SignatureManager.new do |manager|
      manager.build do |env|
        typecheck = Test::TypeCheck.new(
          self_class: Integer,
          instance_class: Integer,
          class_class: Integer.singleton_class,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        assert typecheck.value(30, parse_type("instance"))
        refute typecheck.value("30", parse_type("instance"))

        assert typecheck.value(Integer, parse_type("class"))
        refute typecheck.value(String, parse_type("class"))
      end
    end
  end

  def test_type_check_absent
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Bar
end
EOF
      manager.build do |env|
        typecheck = Test::TypeCheck.new(
          self_class: Integer,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        refute typecheck.value(3, parse_type("::Bar"))
        assert typecheck.value(nil, parse_type("::Bar | nil"))
      end
    end
  end

  def test_type_check_array_sampling
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        typecheck = Test::TypeCheck.new(self_class: Integer, builder: builder, sample_size: 100, unchecked_classes: [])

        assert typecheck.value([], parse_type("::Array[::Integer]"))
        assert typecheck.value([1], parse_type("::Array[::Integer]"))
        refute typecheck.value([1,2,3] + ["a"], parse_type("::Array[::Integer]"))

        assert typecheck.value(Array.new(500, 1), parse_type("::Array[::Integer]"))
        refute typecheck.value(Array.new(99, 1) + Array.new(401, "a"), parse_type("::Array[::Integer]"))
      end
    end
  end

  def test_type_check_hash_sampling
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        typecheck = Test::TypeCheck.new(self_class: Integer, builder: builder, sample_size: 100, unchecked_classes: [])

        assert typecheck.value({}, parse_type("::Hash[::Integer, ::String]"))
        assert typecheck.value(Array.new(100) {|i| [i, i.to_s] }.to_h, parse_type("::Hash[::Integer, ::String]"))

        assert typecheck.value(Array.new(1000) {|i| [i, i.to_s] }.to_h, parse_type("::Hash[::Integer, ::String]"))
      end
    end
  end

  def test_type_check_enumerator_sampling
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        typecheck = Test::TypeCheck.new(self_class: Integer, builder: builder, sample_size: 100, unchecked_classes: [])

        assert typecheck.value([1,2,3].each, parse_type("Enumerator[Integer, Array[Integer]]"))
        assert typecheck.value(Array.new(400, 3).each, parse_type("Enumerator[Integer, Array[Integer]]"))

        refute typecheck.value((Array.new(99, 1) + Array.new(401, "a")).each, parse_type("Enumerator[Integer, Array[Integer]]"))

        assert typecheck.value(loop, parse_type("Enumerator[nil, bot]"))
      end
    end
  end

  def test_sampling_handling
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

          assert_sampling_check(builder, 1, [0,1,2,3,4])
          assert_sampling_check(builder, 3, [1,2,3,4,5])
          assert_sampling_check(builder, 3, [1,2,3,4,'a'])
          assert_sampling_check(builder, 3, [1,'a'])
          assert_sampling_check(builder, 100,[0,1,2,3,4])
          assert_sampling_check(builder, 100, Array.new(400) {|i| i})
          assert_sampling_check(builder, nil, [0,1,2,3,4])
      end
    end
  end

  def test_typecheck_return
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type foo = String | Integer
EOF
      manager.build do |env|
        typecheck = Test::TypeCheck.new(
          self_class: Object,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        parse_method_type("(Integer) -> String").tap do |method_type|
          errors = []
          typecheck.return "#foo",
                           method_type,
                           method_type.type,
                           Test::ArgumentsReturn.exception(arguments: [1], exception: RuntimeError.new("test")),
                           errors,
                           return_error: Test::Errors::ReturnTypeError
          assert_empty errors

          errors.clear
          typecheck.return "#foo",
                           method_type,
                           method_type.type,
                           Test::ArgumentsReturn.return(arguments: [1], value: "5"),
                           errors,
                           return_error: Test::Errors::ReturnTypeError
          assert_empty errors
        end

        parse_method_type("(Integer) -> bot").tap do |method_type|
          errors = []
          typecheck.return "#foo",
                           method_type,
                           method_type.type,
                           Test::ArgumentsReturn.exception(arguments: [1], exception: RuntimeError.new("test")),
                           errors,
                           return_error: Test::Errors::ReturnTypeError
          assert_empty errors

          errors.clear
          typecheck.return "#foo",
                           method_type,
                           method_type.type,
                           Test::ArgumentsReturn.return(arguments: [1], value: "5"),
                           errors,
                           return_error: Test::Errors::ReturnTypeError
          assert errors.any? {|error| error.is_a?(Test::Errors::ReturnTypeError) }
        end
      end
    end
  end

  def test_type_check_record
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type outer_record_type = {
  inner_record: {
    innermost_record: {
      string: String
    }
  }
}
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        typecheck = Test::TypeCheck.new(self_class: Integer, builder: builder, sample_size: 100, unchecked_classes: [])

        assert typecheck.value({foo: 'foo', bar: 0, baz: :baz }, parse_type("{:foo => String, :bar => Integer, :baz => Symbol}"))
        assert typecheck.value({foo: 'foo', bar: 0, baz: :baz }, parse_type("{foo: String, bar: Integer, baz: Symbol}"))
        refute typecheck.value({}, parse_type("{:foo => String, :bar => Integer, :baz => Symbol}"))


        assert typecheck.value({}, parse_type("{foo: String?, bar: Integer?, baz: Symbol?}"))
        assert typecheck.value({}, parse_type("{:foo => String?, :bar => Integer?, :baz => Symbol?}"))
        assert typecheck.value({foo: 'foo', bar: 0}, parse_type("{foo: String?, bar: Integer?, baz: Symbol?}"))
        assert typecheck.value({foo: 'foo', bar: 0 }, parse_type("{:foo => String?, :bar => Integer?, :baz => Symbol?}"))

        outer_record = {
          inner_record: {
            innermost_record: {string: "string"}
          }
        }

        assert typecheck.value(outer_record, parse_type('::outer_record_type'))
      end
    end
  end

  def test_typecheck_args
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type foo = String | Integer
EOF
      manager.build do |env|
        typecheck = Test::TypeCheck.new(
          self_class: Object,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        parse_method_type("(Integer) -> String").tap do |method_type|
          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [1], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors

          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: ["1"], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Errors::ArgumentTypeError) }

          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [1, 2], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Errors::ArgumentError) }

          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ hello: :world }], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Errors::ArgumentTypeError) }
        end

        parse_method_type("(foo: Integer, ?bar: String, **Symbol) -> String").tap do |method_type|
          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ foo: 31, baz: :baz }], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors

          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ foo: "foo" }], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Errors::ArgumentTypeError) }

          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ bar: "bar" }], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert errors.any? {|error| error.is_a?(Test::Errors::ArgumentError) }
        end

        parse_method_type("(?String, ?encoding: String) -> String").tap do |method_type|
          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ encoding: "ASCII-8BIT" }], value: "foo"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors
        end

        parse_method_type("(parent: untyped, type: untyped) -> untyped").tap do |method_type|
          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [{ parent: nil, type: nil }], value: nil),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors.map {|e| Test::Errors.to_string(e) }
        end

        parse_method_type("(Integer?, *String) -> String").tap do |method_type|
          errors = []
          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [1], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors

          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [1, ''], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors

          typecheck.args "#foo",
                         method_type,
                         method_type.type,
                         Test::ArgumentsReturn.return(arguments: [1, '', ''], value: "1"),
                         errors,
                         type_error: Test::Errors::ArgumentTypeError,
                         argument_error: Test::Errors::ArgumentError
          assert_empty errors
        end
      end
    end
  end

  def test_is_double
    omit unless has_gem?("rspec")
    omit if skip_minitest?

    require "rspec/mocks/standalone"
    require "minitest/mock"

    SignatureManager.new do |manager|
      manager.build do |env|
        minitest_typecheck = Test::TypeCheck.new(
          self_class: Integer,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: ['Minitest::Mock']
        )

        rspec_typecheck = Test::TypeCheck.new(
          self_class: Integer,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: ['RSpec::Mocks::Double']
        )

        no_mock_typecheck = Test::TypeCheck.new(
          self_class: Integer,
          builder: DefinitionBuilder.new(env: env),
          sample_size: 100,
          unchecked_classes: []
        )

        minitest_mock = ::Minitest::Mock.new
        rspec_mock = RSPEC_MOCK[]

        assert minitest_typecheck.is_double? minitest_mock
        assert rspec_typecheck.is_double? rspec_mock

        refute minitest_typecheck.is_double? rspec_mock
        refute rspec_typecheck.is_double? minitest_mock

        refute minitest_typecheck.is_double? 1
        refute minitest_typecheck.is_double? 'hi'
        refute minitest_typecheck.is_double? nil

        refute rspec_typecheck.is_double? 1
        refute rspec_typecheck.is_double? 'hi'
        refute rspec_typecheck.is_double? nil

        refute no_mock_typecheck.is_double? minitest_mock
        refute no_mock_typecheck.is_double? minitest_mock

      end
    end
  end

  def test_type_overload
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def foo: () -> String
         | (Integer) -> String

  def bar: () -> String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        typecheck = Test::TypeCheck.new(self_class: Object, builder: builder, sample_size: 100, unchecked_classes: [])

        builder.build_instance(type_name("::Foo")).tap do |foo|
          typecheck.overloaded_call(
            foo.methods[:foo],
            "#foo",
            Test::CallTrace.new(
              method_name: :foo,
              method_call: Test::ArgumentsReturn.return(
                arguments: [],
                value: "foo"
              ),
              block_calls: [],
              block_given: false
            ),
            errors: []
          ).tap do |errors|
            assert_empty errors
          end

          typecheck.overloaded_call(
            foo.methods[:bar],
            "#bar",
            Test::CallTrace.new(
              method_name: :bar,
              method_call: Test::ArgumentsReturn.return(
                arguments: [],
                value: 30
              ),
              block_calls: [],
              block_given: false
            ),
            errors: []
          ).tap do |errors|
            assert_equal 1, errors.size
            assert_instance_of RBS::Test::Errors::ReturnTypeError, errors[0]
          end

          typecheck.overloaded_call(
            foo.methods[:foo],
            "#foo",
            Test::CallTrace.new(
              method_name: :foo,
              method_call: Test::ArgumentsReturn.return(
                arguments: [3],
                value: 30
              ),
              block_calls: [],
              block_given: false
            ),
            errors: []
          ).tap do |errors|
            assert_equal 1, errors.size
            assert_instance_of RBS::Test::Errors::UnresolvedOverloadingError, errors[0]
          end
        end
      end
    end
  end
end

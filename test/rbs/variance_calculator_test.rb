require "test_helper"

class RBS::VarianceCalculatorTest < Test::Unit::TestCase
  include TestHelper

  DefinitionBuilder = RBS::DefinitionBuilder
  VarianceCalculator = RBS::VarianceCalculator

  def test_method_type_variance
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[out X, in Y, Z]
end

module Bar[out X, in Y, Z]
end

module Baz = Bar
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)
        calculator = VarianceCalculator.new(builder: builder)

        calculator.in_method_type(method_type: parse_method_type("() -> void"), variables: []).tap do |result|
          assert_equal({}, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("(A) -> B", variables: [:A, :B]), variables: [:A, :B]).tap do |result|
          assert_equal({ A: :contravariant, B: :covariant }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("(A) -> A", variables: [:A]), variables: [:A, :B]).tap do |result|
          assert_equal({ A: :invariant, B: :unused }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("() -> ::Foo[A, B, C]", variables: [:A, :B, :C]), variables: [:A, :B, :C]).tap do |result|
          assert_equal({ A: :covariant, B: :contravariant, C: :invariant }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("() -> [A, B]", variables: [:A, :B]), variables: [:A, :B]).tap do |result|
          assert_equal({ A: :covariant, B: :covariant }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("() -> { foo: A }", variables: [:A]), variables: [:A]).tap do |result|
          assert_equal({ A: :covariant }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("(A&B) -> void", variables: [:A, :B]), variables: [:A, :B]).tap do |result|
          assert_equal({ A: :contravariant, B: :contravariant }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("() -> ::Foo[A, B, C, D]", variables: [:A, :B, :C, :D]), variables: [:A, :B, :C, :D]).tap do |result|
          assert_equal({ A: :covariant, B: :contravariant, C: :invariant, D: :unused }, result.result)
        end

        calculator.in_method_type(method_type: parse_method_type("() -> ::Baz[A, B, C]", variables: [:A, :B, :C]), variables: [:A, :B, :C]).tap do |result|
          assert_equal({ A: :covariant, B: :contravariant, C: :invariant }, result.result)
        end
      end
    end
  end

  def test_alias_generics
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
type a[T] = T

type b[T, S] = ^(T) -> S

type c[T, S] = Foo[T, S]

type d[T] = Foo[T, T]

class Foo[in T, out S]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)
        calculator = VarianceCalculator.new(builder: builder)

        calculator.in_type_alias(name: TypeName("::a")).tap do |result|
          assert_equal({ T: :covariant }, result.result)
        end

        calculator.in_type_alias(name: TypeName("::b")).tap do |result|
          assert_equal({ T: :contravariant, S: :covariant }, result.result)
        end

        calculator.in_type_alias(name: TypeName("::c")).tap do |result|
          assert_equal({ T: :contravariant, S: :covariant }, result.result)
        end

        calculator.in_type_alias(name: TypeName("::d")).tap do |result|
          assert_equal({ T: :invariant }, result.result)
        end
      end
    end
  end

  def test_result
    result = VarianceCalculator::Result.new(variables: [:A, :B, :C])
    result.covariant(:A)
    result.contravariant(:B)
    result.invariant(:C)

    # class Foo[out A, out B, out C]; def foo: (B, C) -> [A, C]; end
    assert result.compatible?(:A, with_annotation: :covariant)
    refute result.compatible?(:B, with_annotation: :covariant)
    refute result.compatible?(:C, with_annotation: :covariant)

    # class Foo[in A, in B, in C]; def foo: (B, C) -> [A, C]; end
    refute result.compatible?(:A, with_annotation: :contravariant)
    assert result.compatible?(:B, with_annotation: :contravariant)
    refute result.compatible?(:C, with_annotation: :contravariant)

    # class Foo[A, B, C]; def foo: (B, C) -> [A, C]; end
    assert result.compatible?(:A, with_annotation: :invariant)
    assert result.compatible?(:B, with_annotation: :invariant)
    assert result.compatible?(:C, with_annotation: :invariant)
  end
end

require_relative 'test_helper'

class RationalInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Rational'

  def test_op_mul
    assert_send_type  '(Integer) -> Rational',
                      3/8r, :*, 38
    assert_send_type  '(Rational) -> Rational',
                      3/8r, :*, -9/13r
    assert_send_type  '(Float) -> Float',
                      3/8r, :*, 12.34
    assert_send_type  '(Complex) -> Complex',
                      3/8r, :*, 12-34i
    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      3/8r, :*, Coercable.for_op(:*)
  end

  class MyZeroNumeric < Numeric
    def ==(other) = 0 == other ? true : super
  end

  def test_op_pow
    # Technically, the rational code for `**` has a branch for integer exponents when `Integer#**`
    # returns `Float`. That's no longer a thing (now that `exponent is too large` is raised), so the
    # branch is dead code
    assert_send_type  '(Integer) -> Rational',
                      3/8r, :**, 24

    assert_send_type  '(Rational) -> Rational',
                      3/8r, :**, 0r
    assert_send_type  '(Rational) -> Float',
                      3/8r, :**, 1/2r
    assert_send_type  '(Rational) -> Complex',
                      -3/8r, :**, 1/2r

    assert_send_type  '(Float) -> Float',
                      3/8r, :**, 0.0
    assert_send_type  '(Float) -> Float',
                      3/8r, :**, 0.5
    assert_send_type  '(Float) -> Complex',
                      -3/8r, :**, 0.5

    assert_send_type  '(Complex) -> Rational',
                      3/8r, :**, 0i
    assert_send_type  '(Complex) -> Complex',
                      3/8r, :**, 0.5+0i
    assert_send_type  '(Complex) -> Complex',
                      -3/8r, :**, 0.5i

    assert_send_type  '(RationalInstanceTest::MyZeroNumeric) -> Rational',
                      3/8r, :**, MyZeroNumeric.new
    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      3/8r, :**, Coercable.for_op(:**)
  end

  def test_op_add
    assert_send_type  '(Integer) -> Rational',
                      3/8r, :+, 38
    assert_send_type  '(Rational) -> Rational',
                      3/8r, :+, -9/13r
    assert_send_type  '(Float) -> Float',
                      3/8r, :+, 12.34
    assert_send_type  '(Complex) -> Complex',
                      3/8r, :+, 12-34i
    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      3/8r, :+, Coercable.for_op(:+)
  end

  def test_op_sub
    assert_send_type  '(Integer) -> Rational',
                      3/8r, :-, 38
    assert_send_type  '(Rational) -> Rational',
                      3/8r, :-, -9/13r
    assert_send_type  '(Float) -> Float',
                      3/8r, :-, 12.34
    assert_send_type  '(Complex) -> Complex',
                      3/8r, :-, 12-34i
    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      3/8r, :-, Coercable.for_op(:-)
  end

  def test_op_uneg
    assert_send_type  '() -> Rational',
                      3/8r, :-@
  end

  def test_op_div(method: :/)
    assert_send_type  '(Integer) -> Rational',
                      3/8r, method, 38
    assert_send_type  '(Rational) -> Rational',
                      3/8r, method, -9/13r
    assert_send_type  '(Float) -> Float',
                      3/8r, method, 12.34
    assert_send_type  '(Complex) -> Complex',
                      3/8r, method, 12-34i
    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      3/8r, method, Coercable.for_op(:/) # note not `.for_op(method)`
  end

  def test_op_cmp
    with -3, 0, 4, 5 do |num|
      assert_send_type  '(Integer) -> (-1 | 0 | 1)',
                        4/1r, :<=>, num
      assert_send_type  '(Rational) -> (-1 | 0 | 1)',
                        4/1r, :<=>, num.to_r
    end

    with_untyped.and 2, 3.4, 5/6r, 7+8i do |untyped|
      assert_send_type  '(untyped) -> Integer?',
                        3/8r, :<=>, untyped
    end
  end

  def test_op_eq
    with_untyped.and 2, 2.0, 2r, 2+0i do |untyped|
      next unless defined? untyped.==
      assert_send_type  '(untyped) -> bool',
                        2/1r, :==, untyped
    end
  end

  def test_abs(method: :abs)
    assert_send_type  '() -> Rational',
                      3/8r, method
    assert_send_type  '() -> Rational',
                      -3/8r, method
  end

  def test_ceil
    assert_send_type  '() -> Integer',
                      38/3r, :ceil
    assert_send_type  '(Integer) -> Rational',
                      38/3r, :ceil, 2
    assert_send_type  '(Integer) -> Integer',
                      38/3r, :ceil, -2
  end

  def test_coerce
    assert_send_type  '(Integer) -> [Rational, Rational]',
                      3/8r, :coerce, 12
    assert_send_type  '(Rational) -> [Rational, Rational]',
                      3/8r, :coerce, -9/13r
    assert_send_type  '(Float) -> [Float, Float]',
                      3/8r, :coerce, 3.4
    assert_send_type  '(Complex) -> [Complex, Complex]',
                      3/8r, :coerce, 1+2i
    assert_send_type  '(Complex) -> [Rational, Rational]',
                      3/8r, :coerce, 1.2+0i
  end

  def test_denominator
    assert_send_type  '() -> Integer',
                      3/8r, :denominator
  end

  def test_fdiv
    assert_send_type  '(Integer) -> Float',
                      3/8r, :fdiv, 12
    assert_send_type  '(Rational) -> Float',
                      3/8r, :fdiv, 12r
    assert_send_type  '(Float) -> Float',
                      3/8r, :fdiv, 1.2
    assert_send_type  '(Complex) -> Float',
                      3/8r, :fdiv, 2+0i

    with_float 3.4 do |float|
      coerce = Coercable.for_op(:/, result: float)
      def coerce.==(r) = false
      assert_send_type  '(Coercable) -> Float',
                        3/8r, :fdiv, coerce
    end
  end

  def test_floor
    assert_send_type  '() -> Integer',
                      38/3r, :floor
    assert_send_type  '(Integer) -> Rational',
                      38/3r, :floor, 2
    assert_send_type  '(Integer) -> Integer',
                      38/3r, :floor, -2
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      3/8r, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      3/8r, :inspect
  end

  def test_magnitude
    test_abs(method: :magnitude)
  end

  def test_negative?
    assert_send_type  '() -> bool',
                      3/8r, :negative?
    assert_send_type  '() -> bool',
                      -3/8r, :negative?
  end

  def test_numerator
    assert_send_type  '() -> Integer',
                      3/8r, :numerator
  end

  def test_positive?
    assert_send_type  '() -> bool',
                      3/8r, :positive?
    assert_send_type  '() -> bool',
                      -3/8r, :positive?
  end

  def test_quo
    test_op_div(method: :quo)
  end

  def test_rationalize
    assert_send_type  '() -> Rational',
                      3/8r, :rationalize

    with 1, 1/5r, 0.001, 0.000004+0i do |eps|
      assert_send_type  '(Numeric) -> Rational',
                        3/8r, :rationalize, eps
    end
  end

  def test_round
    assert_send_type  '() -> Integer',
                      7/2r, :round

    with_round_mode do |mode|
      assert_send_type  '(half: Numeric::round_mode) -> Integer',
                        7/2r, :round, half: mode
    end

    assert_send_type  '(Integer) -> Integer',
                      7/2r, :round, -1

    with_round_mode do |mode|
      assert_send_type  '(Integer, half: Numeric::round_mode) -> Integer',
                        7/2r, :round, -1, half: mode
    end
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      3/8r, :to_f
  end

  def test_to_i
    assert_send_type  '() -> Integer',
                      3/8r, :to_i
    assert_send_type  '() -> Integer',
                      -38/8r, :to_i
  end

  def test_to_r
    assert_send_type  '() -> Rational',
                      3/8r, :to_r
  end

  def test_to_s
    assert_send_type  '() -> String',
                      3/8r, :to_s
  end

  def test_truncate
    assert_send_type  '() -> Integer',
                      38/3r, :truncate
    assert_send_type  '(Integer) -> Rational',
                      38/3r, :truncate, 2
    assert_send_type  '(Integer) -> Integer',
                      38/3r, :truncate, -2
  end

  def test_marshal_dump
    assert_visibility :private, :marshal_dump

    assert_send_type  '() -> [Integer, Integer]',
                      3/8r, :marshal_dump
  end
end

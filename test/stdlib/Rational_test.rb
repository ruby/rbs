require_relative 'test_helper'

class RationalInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Rational'

  class Subclass < Rational; end
  class Subclass2 < Rational; end
  INSTANCE = Class.instance_method(:new).bind_call(Subclass) + (1/2r)
  INSTANCE2 = Class.instance_method(:new).bind_call(Subclass2) + (1/2r)

  def test_mul
    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :*, 3
    assert_send_type  '(Rational) -> RationalInstanceTest::Subclass',
                      INSTANCE, :*, 1/2r
    assert_send_type  '(Float) -> Float',
                      INSTANCE, :*, 1.0

    with_coercible :* do |coercible|
      assert_send_type '[O < Numeric::_Multiply[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, :*, coercible
    end
  end

  def test_pow
    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :**, 3

    assert_send_type  '(Rational) -> RationalInstanceTest::Subclass',
                      INSTANCE, :**, 1r
    assert_send_type  '(Rational) -> Float',
                      INSTANCE, :**, 1/2r
    assert_send_type  '(Rational) -> Complex',
                      -INSTANCE, :**, 1/2r

    assert_send_type  '(Float) -> Float',
                      INSTANCE, :**, 1.0
    assert_send_type  '(Float) -> Complex',
                      -INSTANCE, :**, 0.5

    with_coercible :** do |coercible|
      assert_send_type '[O < Numeric::_Power[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, :**, coercible
    end
  end

  def test_add
    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :+, 3
    assert_send_type  '(Rational) -> RationalInstanceTest::Subclass',
                      INSTANCE, :+, 1/2r
    assert_send_type  '(Float) -> Float',
                      INSTANCE, :+, 0.0

    with_coercible :+ do |coercible|
      assert_send_type '[O < Numeric::_Add[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, :+, coercible
    end
  end

  def test_sub
    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :-, 3
    assert_send_type  '(Rational) -> RationalInstanceTest::Subclass',
                      INSTANCE, :-, 1/2r
    assert_send_type  '(Float) -> Float',
                      INSTANCE, :-, 0.0

    with_coercible :- do |coercible|
      assert_send_type '[O < Numeric::_Subtract[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, :-, coercible
    end
  end

  def test_uneg
    assert_send_type  '() -> RationalInstanceTest::Subclass',
                      INSTANCE, :-@
  end

  def test_div(method: :/)
    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, method, 3
    assert_send_type  '(Rational) -> RationalInstanceTest::Subclass',
                      INSTANCE, method, 1/2r
    assert_send_type  '(Float) -> Float',
                      INSTANCE, method, 1.0

    with_coercible :/ do |coercible|
      assert_send_type '[O < Numeric::_Divide[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, method, coercible
    end
  end

  def test_cmp
    with 1, 0, 1/2r, 1/3r, INSTANCE do |other|
      assert_send_type  '(Integer | Rational) -> (-1 | 0 | 1)',
                        INSTANCE, :<=>, other
    end

    with_untyped.and INSTANCE do |untyped|
      assert_send_type  '(untyped) -> (-1 | 0 | 1)?',
                        INSTANCE, :<=>, untyped
    end
  end

  def test_eq
    with_untyped.and INSTANCE do |untyped|
      def untyped.==(other) = true unless defined?(untyped.==)

      assert_send_type  '(untyped) -> bool',
                        INSTANCE, :==, untyped
    end
  end

  def test_abs(method: :abs)
    assert_send_type  '() -> RationalInstanceTest::Subclass',
                      INSTANCE, :abs

    assert_send_type  '() -> RationalInstanceTest::Subclass',
                      -INSTANCE, :abs
  end

  def test_ceil
    assert_send_type  '() -> Integer',
                      INSTANCE, :ceil

    assert_send_type  '(Integer) -> Integer',
                      INSTANCE, :ceil, -1

    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :ceil, 2
  end

  def test_coerce
    assert_send_type  '(Integer) -> [RationalInstanceTest::Subclass, RationalInstanceTest::Subclass]',
                      INSTANCE, :coerce, 1
    assert_send_type  '(Float) -> [Float, Float]',
                      INSTANCE, :coerce, 1.0
    assert_send_type  '(RationalInstanceTest::Subclass2) -> [RationalInstanceTest::Subclass2, RationalInstanceTest::Subclass]',
                      INSTANCE, :coerce, INSTANCE2
    assert_send_type  '(Complex) -> [RationalInstanceTest::Subclass, RationalInstanceTest::Subclass]',
                      INSTANCE, :coerce, 0i
    assert_send_type  '(Complex) -> [Complex, Complex]',
                      INSTANCE, :coerce, 1i
  end

  def test_denominator
    assert_send_type  '() -> Integer',
                      INSTANCE, :denominator
  end

  def test_fdiv
    assert_send_type  '(Integer) -> Float',
                      INSTANCE, :fdiv, 1
    assert_send_type  '(Rational) -> Float',
                      INSTANCE, :fdiv, 1r
    assert_send_type  '(Float) -> Float',
                      INSTANCE, :fdiv, 1.0

    return_value = BlankSlate.new
    def return_value.to_f = 3.14
    with_coercible :/, return_value: return_value do |coercible|
      assert_send_type '[O < Numeric::_Divide[S, R], R < _ToF] (Numeric::_Coerce[Float, O, S] other) -> R',
                       INSTANCE, :fdiv, coercible
    end
  end

  def test_floor
    assert_send_type  '() -> Integer',
                      INSTANCE, :floor

    assert_send_type  '(Integer) -> Integer',
                      INSTANCE, :floor, -1

    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :floor, 2
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      INSTANCE, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      INSTANCE, :inspect
  end

  def test_magnitude
    test_abs(method: :magnitude)
  end

  def test_negative?
    assert_send_type  '() -> bool',
                      INSTANCE, :negative?

    assert_send_type  '() -> bool',
                      -INSTANCE, :negative?
  end

  def test_numerator
    assert_send_type  '() -> Integer',
                      INSTANCE, :denominator
  end

  def test_positive?
    assert_send_type  '() -> bool',
                      INSTANCE, :positive?

    assert_send_type  '() -> bool',
                      -INSTANCE, :positive?
  end

  def test_quo
    test_div(method: :quo)
  end

  def test_rationalize
    assert_send_type  '() -> RationalInstanceTest::Subclass',
                      INSTANCE, :rationalize

    eps = BlankSlate.new
    def eps.abs = 1.2

    assert_send_type  '(Numeric::_Eps) -> RationalInstanceTest::Subclass',
                      INSTANCE, :rationalize, eps 
  end

  def test_round
    assert_send_type  '() -> Integer',
                      INSTANCE, :round

    assert_send_type  '(Integer) -> Integer',
                      INSTANCE, :round, -1

    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :round, 2

    with(:up, :down, :even, nil).and with_string('up'), with_string('down'), with_string('even') do |dir|
      unless defined?(dir.==)
        def dir.==(rhs) = rhs == to_str
      end

      assert_send_type  '(half: Numeric::round_direction) -> Integer',
                        INSTANCE, :round, half: dir
      assert_send_type  '(half: Numeric::round_direction) -> Integer',
                        INSTANCE, :round, half: dir

      assert_send_type  '(Integer, half: Numeric::round_direction) -> Integer',
                        INSTANCE, :round, -1, half: dir
      assert_send_type  '(Integer, half: Numeric::round_direction) -> RationalInstanceTest::Subclass',
                        INSTANCE, :round, 2, half: dir
     end
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      INSTANCE, :to_f
  end

  def test_to_i
    assert_send_type  '() -> Integer',
                      INSTANCE, :to_i
  end

  def test_to_r
    assert_send_type  '() -> RationalInstanceTest::Subclass',
                      INSTANCE, :to_r
  end

  def test_to_s
    assert_send_type  '() -> String',
                      INSTANCE, :to_s
  end

  def test_truncate
    assert_send_type  '() -> Integer',
                      INSTANCE, :truncate

    assert_send_type  '(Integer) -> Integer',
                      INSTANCE, :truncate, -1

    assert_send_type  '(Integer) -> RationalInstanceTest::Subclass',
                      INSTANCE, :truncate, 2
  end
end

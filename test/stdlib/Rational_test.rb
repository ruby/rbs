require_relative 'test_helper'

class RationalInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Rational'

  def test_op_mul
    omit
  end

  def test_op_pow
    omit
  end

  def test_op_add
    omit
  end

  def test_op_sub
    omit
  end

  def test_op_uneg
    assert_send_type  '() -> Rational',
                      3/8r, :-@
  end

  def test_op_div
    omit
  end

  def test_op_cmp
    omit
  end

  def test_op_eq
    omit
  end

  def test_abs(method: :abs)
    assert_send_type  '() -> Rational',
                      3/8r, method
    assert_send_type  '() -> Rational',
                      -3/8r, method
  end

  def test_ceil
    omit
  end

  def test_coerce
    omit
  end

  def test_denominator
    assert_send_type  '() -> Integer',
                      3/8r, :denominator
  end

  def test_fdiv
    omit
  end

  def test_floor
    omit
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
    omit
  end

  def test_rationalize
    omit
  end

  def test_round
    omit
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
    omit
  end

  def test_marshal_dump
    omit
  end
end

require_relative 'test_helper'

class FloatSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Float)'

  def test_constant_DIG
    assert_const_type 'Integer',
                      'Float::DIG'
  end

  def test_constant_EPSILON
    assert_const_type 'Float',
                      'Float::EPSILON'
  end

  def test_constant_INFINITY
    assert_const_type 'Float',
                      'Float::INFINITY'
  end

  def test_constant_MANT_DIG
    assert_const_type 'Integer',
                      'Float::MANT_DIG'
  end

  def test_constant_MAX
    assert_const_type 'Float',
                      'Float::MAX'
  end

  def test_constant_MAX_10_EXP
    assert_const_type 'Integer',
                      'Float::MAX_10_EXP'
  end

  def test_constant_MAX_EXP
    assert_const_type 'Integer',
                      'Float::MAX_EXP'
  end

  def test_constant_MIN
    assert_const_type 'Float',
                      'Float::MIN'
  end

  def test_constant_MIN_10_EXP
    assert_const_type 'Integer',
                      'Float::MIN_10_EXP'
  end

  def test_constant_MIN_EXP
    assert_const_type 'Integer',
                      'Float::MIN_EXP'
  end

  def test_constant_NAN
    assert_const_type 'Float',
                      'Float::NAN'
  end

  def test_constant_RADIX
    assert_const_type 'Integer',
                      'Float::RADIX'
  end

  def test_constant_ROUNDS
    return unless defined? Float::ROUNDS
    assert_const_type 'Integer',
                      'Float::ROUNDS'
  end
end

class FloatInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Float'

  def test_op_mod
    omit 'todo'
  end

  def test_op_mul
    omit 'todo'
  end

  def test_op_pow
    omit 'todo'
  end

  def test_op_add
    omit 'todo'
  end

  def test_op_sub
    omit 'todo'
  end

  def test_op_uneg
    omit 'todo'
  end

  def test_op_div
    omit 'todo'
  end

  def test_op_lth
    omit 'todo'
  end

  def test_op_leq
    omit 'todo'
  end

  def test_op_cmp
    omit 'todo'
  end

  def test_op_eq
    omit 'todo'
  end

  def test_op_eqq
    omit 'todo'
  end

  def test_op_gth
    omit 'todo'
  end

  def test_op_geq
    omit 'todo'
  end

  def test_abs
    omit 'todo'
  end

  def test_angle
    omit 'todo'
  end

  def test_arg
    omit 'todo'
  end

  def test_ceil
    omit 'todo'
  end

  def test_coerce
    omit 'todo'
  end

  def test_denominator
    omit 'todo'
  end

  def test_divmod
    omit 'todo'
  end

  def test_eql?
    omit 'todo'
  end

  def test_fdiv
    omit 'todo'
  end

  def test_finite?
    omit 'todo'
  end

  def test_floor
    omit 'todo'
  end

  def test_hash
    omit 'todo'
  end

  def test_infinite?
    omit 'todo'
  end

  def test_inspect
    omit 'todo'
  end

  def test_magnitude
    omit 'todo'
  end

  def test_modulo
    omit 'todo'
  end

  def test_nan?
    omit 'todo'
  end

  def test_negative?
    omit 'todo'
  end

  def test_next_float
    omit 'todo'
  end

  def test_numerator
    omit 'todo'
  end

  def test_phase
    omit 'todo'
  end

  def test_positive?
    omit 'todo'
  end

  def test_prev_float
    omit 'todo'
  end

  def test_quo
    omit 'todo'
  end

  def test_rationalize
    omit 'todo'
  end

  def test_round
    omit 'todo'
  end

  def test_to_f
    omit 'todo'
  end

  def test_to_i
    omit 'todo'
  end

  def test_to_int
    omit 'todo'
  end

  def test_to_r
    omit 'todo'
  end

  def test_to_s
    omit 'todo'
  end

  def test_truncate
    omit 'todo'
  end

  def test_zero?
    omit 'todo'
  end
end

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

  def with_floats(infinity: true, nan: true)
    yield 0.0
    yield -0.0
    yield 12.34
    yield -38e99
    yield Float::MIN
    yield Float::MAX
    yield Float::INFINITY if infinity
    yield -Float::INFINITY if infinity
    yield Float::NAN if nan
  end

  def test_op_mod(method: :%)
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
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, :-@
    end
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

  def test_op_eq(method: :==)
    with_floats do |float|
      with_untyped.and float do |other|
        next unless defined? other.==
        assert_send_type  '(untyped) -> bool',
                          float, method, other
      end
    end
  end

  def test_op_eqq
    test_op_eq(method: :===)
  end

  def test_op_gth
    omit 'todo'
  end

  def test_op_geq
    omit 'todo'
  end

  def test_abs(method: :abs)
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, method
    end
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
    with_floats do |float|
      with_float do |other|
        assert_send_type  '(_ToF) -> [Float, Float]',
                          float, :coerce, other
      end
    end
  end

  def test_denominator
    omit 'todo'
  end

  def test_divmod
    omit 'todo'
  end

  def test_eql?
    with_floats do |float|
      with_untyped.and float do |other|
        assert_send_type  '(untyped) -> bool',
                          float, :eql?, other
      end
    end
  end

  def test_fdiv
    test_quo(method: :fdiv)
  end

  def test_finite?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :finite?
    end
  end

  def test_floor
    omit 'todo'
  end

  def test_hash
    with_floats do |float|
      assert_send_type  '() -> Integer',
                        float, :hash
    end
  end

  def test_infinite?
    with_floats do |float|
      assert_send_type  '() -> (-1 | 1)?',
                        float, :infinite?
    end
  end

  def test_inspect
    test_to_s(method: :inspect)
  end

  def test_magnitude
    test_abs(method: :magnitude)
  end

  def test_modulo
    test_op_mod(method: :modulo)
  end

  def test_nan?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :nan?
    end
  end

  def test_negative?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :negative?
    end
  end

  def test_next_float
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, :next_float
    end
  end

  def test_numerator
    omit 'todo'
  end

  def test_phase
    omit 'todo'
  end

  def test_positive?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :positive?
    end
  end

  def test_prev_float
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, :next_float
    end
  end

  def test_quo(method: :quo)
    omit 'todo'
  end

  def test_rationalize
    omit 'todo'
  end

  def test_round
    omit 'todo'
  end

  def test_to_f
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, :to_f
    end
  end

  def test_to_i(method: :to_i)
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Integer',
                        float, method
    end
  end

  def test_to_int
    test_to_i(method: :to_int)
  end

  def test_to_r
    omit 'todo'
  end

  def test_to_s(method: :to_s)
    with_floats do |float|
      assert_send_type  '() -> String',
                        float, method
    end
  end

  def test_truncate
    omit 'todo'
  end

  def test_zero?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :zero?
    end
  end
end

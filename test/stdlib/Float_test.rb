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
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, method, 12
      assert_send_type  '(Rational) -> Float',
                        float, method, 12r
      assert_send_type  '(Float) -> Float',
                        float, method, 12.0
      # no `Complex` as it doesnt have `%`

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, method, Coercable.for_op(:%) # Note: `.for_op(:%)` is correct
    end
  end

  def test_op_mul
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, :*, 12
      assert_send_type  '(Rational) -> Float',
                        float, :*, 12r
      assert_send_type  '(Float) -> Float',
                        float, :*, 12.0
      assert_send_type  '(Complex) -> Complex',
                        float, :*, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :*, Coercable.for_op(:*)
    end
  end

  def test_op_pow
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, :**, 12
      assert_send_type  '(Rational) -> Float',
                        float, :**, 12r
      assert_send_type  '(Rational) -> (Float | Complex)',
                        float, :**, 1/2r
      assert_send_type  '(Float) -> Float',
                        float, :**, 12.0
      assert_send_type  '(Float) -> (Float | Complex)',
                        float, :**, 0.5
      assert_send_type  '(Complex) -> Complex',
                        float, :**, 0i
      assert_send_type  '(Complex) -> Complex',
                        float, :**, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :**, Coercable.for_op(:**)
    end
  end

  def test_op_add
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, :+, 12
      assert_send_type  '(Rational) -> Float',
                        float, :+, 12r
      assert_send_type  '(Float) -> Float',
                        float, :+, 12.0
      assert_send_type  '(Complex) -> Complex',
                        float, :+, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :+, Coercable.for_op(:+)
    end
  end

  def test_op_sub
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, :-, 12
      assert_send_type  '(Rational) -> Float',
                        float, :-, 12r
      assert_send_type  '(Float) -> Float',
                        float, :-, 12.0
      assert_send_type  '(Complex) -> Complex',
                        float, :-, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :-, Coercable.for_op(:-)
    end
  end

  def test_op_uneg
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, :-@
    end
  end

  def test_op_div
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, :/, 12
      assert_send_type  '(Rational) -> Float',
                        float, :/, 12r
      assert_send_type  '(Float) -> Float',
                        float, :/, 12.0
      assert_send_type  '(Complex) -> Complex',
                        float, :/, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :/, Coercable.for_op(:/)
    end
  end

  def test_op_lth
    with_floats do |float|
      assert_send_type  '(Integer) -> bool',
                        float, :<, 12
      assert_send_type  '(Rational) -> bool',
                        float, :<, 12r
      assert_send_type  '(Float) -> bool',
                        float, :<, 12.0
      # Notably not `Complex` as complex doesn't define `<`

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :<, Coercable.for_op(:<)
    end
  end

  def test_op_leq
    with_floats do |float|
      assert_send_type  '(Integer) -> bool',
                        float, :<=, 12
      assert_send_type  '(Rational) -> bool',
                        float, :<=, 12r
      assert_send_type  '(Float) -> bool',
                        float, :<=, 12.0
      # Notably not `Complex` as complex doesn't define `<=`

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :<=, Coercable.for_op(:<=)
    end
  end

  def test_op_cmp
    with_floats do |float|
      with_floats do |float2|
        assert_send_type  '(Float) -> (-1 | 0 | 1)?',
                          float, :<=>, float2
      end

      with_untyped.and float do |other|
        assert_send_type  '(untyped) -> Integer?',
                          float, :<=>, other
      end
    end
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
    with_floats do |float|
      assert_send_type  '(Integer) -> bool',
                        float, :>, 12
      assert_send_type  '(Rational) -> bool',
                        float, :>, 12r
      assert_send_type  '(Float) -> bool',
                        float, :>, 12.0
      # Notably not `Complex` as complex doesn't define `>`

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :>, Coercable.for_op(:>)
    end
  end

  def test_op_geq
    with_floats do |float|
      assert_send_type  '(Integer) -> bool',
                        float, :>=, 12
      assert_send_type  '(Rational) -> bool',
                        float, :>=, 12r
      assert_send_type  '(Float) -> bool',
                        float, :>=, 12.0
      # Notably not `Complex` as complex doesn't define `>=`

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, :>=, Coercable.for_op(:>=)
    end
  end

  def test_abs(method: :abs)
    with_floats do |float|
      assert_send_type  '() -> Float',
                        float, method
    end
  end

  def test_angle
    test_arg(method: :angle)
  end

  def test_arg(method: :arg)
    with_floats do |float|
      assert_send_type  '() -> (0 | Float)',
                        float, method
    end
  end

  def test_ceil
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Integer',
                        float, :ceil

      with_int(-1).and with_int(1) do |ndigits|
        assert_send_type  '(int) -> (Float | Integer)',
                          float, :ceil, ndigits
      end
    end
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
    with_floats do |float|
      assert_send_type  '() -> Integer',
                        float, :denominator
    end
  end

  def test_divmod
    assert_send_type  '(Integer) -> [Integer, Float]',
                      38.0, :divmod, 12
    assert_send_type  '(Rational) -> [Integer, Float]',
                      38.0, :divmod, 12r
    assert_send_type  '(Float) -> [Integer, Float]',
                      38.0, :divmod, 12.0
    # Notably not `Complex` as complex doesn't define `divmod`

    assert_send_type  '(Coercable) -> Coercable::OpReturn',
                      38.0, :divmod, Coercable.for_op(:divmod)
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
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Integer',
                        float, :floor

      with_int(-1).and with_int(1) do |ndigits|
        assert_send_type  '(int) -> (Float | Integer)',
                          float, :floor, ndigits
      end
    end
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
    with_floats do |float|
      if float.nan? || float.infinite?
        assert_send_type  '() -> Float',
                          float, :numerator
      else
        assert_send_type  '() -> Integer',
                          float, :numerator
      end
    end
  end

  def test_phase
    test_arg(method: :phase)
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
    # note: `quo` (and `fdiv`) actually is just a thin wrapper around `/`.
    with_floats do |float|
      assert_send_type  '(Integer) -> Float',
                        float, method, 12
      assert_send_type  '(Rational) -> Float',
                        float, method, 12r
      assert_send_type  '(Float) -> Float',
                        float, method, 12.0
      assert_send_type  '(Complex) -> Complex',
                        float, method, 12i

      assert_send_type  '(Coercable) -> Coercable::OpReturn',
                        float, method, Coercable.for_op(:/)
    end
  end

  def test_rationalize
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '(Integer) -> Rational',
                        float, :rationalize, 1
      assert_send_type  '(Rational) -> Rational',
                        float, :rationalize, 1r
      assert_send_type  '(Float) -> Rational',
                        float, :rationalize, 1.2
      assert_send_type  '(Complex) -> Rational',
                        float, :rationalize, 1i
    end
  end

  def test_round
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Integer',
                        float, :round

      with_round_mode do |mode|
        assert_send_type  '(half: Numeric::round_mode) -> Integer',
                          float, :round, half: mode
      end

      with_int(-1).and with_int(1) do |digits|
        assert_send_type  '(int) -> (Integer | Float)',
                          float, :round, digits

        with_round_mode do |mode|
          assert_send_type  '(int, half: Numeric::round_mode) -> (Integer | Float)',
                            float, :round, digits, half: mode
        end
      end
    end
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
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Rational',
                        float, :to_r
    end
  end

  def test_to_s(method: :to_s)
    with_floats do |float|
      assert_send_type  '() -> String',
                        float, method
    end
  end

  def test_truncate
    with_floats infinity: false, nan: false do |float|
      assert_send_type  '() -> Integer',
                        float, :truncate

      with_int(-1).and with_int(1) do |ndigits|
        assert_send_type  '(int) -> (Float | Integer)',
                          float, :truncate, ndigits
      end
    end
  end

  def test_zero?
    with_floats do |float|
      assert_send_type  '() -> bool',
                        float, :zero?
    end
  end
end

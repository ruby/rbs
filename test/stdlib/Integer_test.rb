require_relative 'test_helper'

class IntegerSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Integer)'

  def test_sqrt
    with_int 38 do |int|
      assert_send_type  '(int) -> Integer',
                        Integer, :sqrt, int
    end
  end

  def test_try_convert
    with_int 1 do |int|
      assert_send_type  '(int) -> Integer',
                        Integer, :try_convert, int
    end

    with_untyped do |untyped|
      assert_send_type '(untyped) -> Integer?',
                       Integer, :try_convert, untyped
    end
  end
end

class IntegerInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Integer'

  def test_op_mod(method: :%)
    assert_send_type  '(Integer) -> Integer',
                      38, method, 12
    assert_send_type  '(Rational) -> Rational',
                      38, method, 12r
    assert_send_type  '(Float) -> Float',
                      38, method, 12.0
    # Notably not `Complex` as complex doesn't define `%`

    assert_send_type  '[O < RBS::Ops::_Subtract[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, method, Coercable.new('fmt: %s', &:to_s)
  end

  def test_op_and
    # omit 'todo'
  end

  def test_op_mul
    assert_send_type  '(Integer) -> Integer',
                      38, :*, 12
    assert_send_type  '(Rational) -> Rational',
                      38, :*, 12r
    assert_send_type  '(Float) -> Float',
                      38, :*, 12.0
    assert_send_type  '(Complex) -> Complex',
                      38, :*, 12i

    assert_send_type  '[O < RBS::Ops::_Times[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :*, Coercable.new(%w[a b], &:to_s)
  end

  def test_op_pow
    assert_send_type  '(Integer) -> Integer',
                      38, :**, 12
    assert_send_type  '(Rational) -> Rational',
                      38, :**, 12r
    assert_send_type  '(Float) -> Float',
                      38, :**, 12.0
    assert_send_type  '(Complex) -> Complex',
                      38, :**, 12i

    assert_send_type  '[O < RBS::Ops::_Power[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :**, Coercable.new(10i, &:i)
  end

  def test_op_add
    assert_send_type  '(Integer) -> Integer',
                      38, :+, 12
    assert_send_type  '(Rational) -> Rational',
                      38, :+, 12r
    assert_send_type  '(Float) -> Float',
                      38, :+, 12.0
    assert_send_type  '(Complex) -> Complex',
                      38, :+, 12i

    assert_send_type  '[O < RBS::Ops::_Add[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :+, Coercable.new('foo', &:to_s)
  end

  def test_op_sub
    assert_send_type  '(Integer) -> Integer',
                      38, :-, 12
    assert_send_type  '(Rational) -> Rational',
                      38, :-, 12r
    assert_send_type  '(Float) -> Float',
                      38, :-, 12.0
    assert_send_type  '(Complex) -> Complex',
                      38, :-, 12i

    assert_send_type  '[O < RBS::Ops::_Subtract[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :-, Coercable.new([3], &:digits)
  end

  def test_op_uneg
    assert_send_type  '() -> Integer',
                      38, :-@
  end

  def test_op_div
    assert_send_type  '(Integer) -> Integer',
                      38, :/, 12
    assert_send_type  '(Rational) -> Rational',
                      38, :/, 12r
    assert_send_type  '(Float) -> Float',
                      38, :/, 12.0
    assert_send_type  '(Complex) -> Complex',
                      38, :/, 12i

    assert_send_type  '[O < RBS::Ops::_Times[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :/, Coercable.new(10i, &:i)
  end

  def test_op_lt
    assert_send_type  '(Integer) -> bool',
                      38, :<, 12
    assert_send_type  '(Rational) -> bool',
                      38, :<, 12r
    assert_send_type  '(Float) -> bool',
                      38, :<, 12.0
    # Notably not `Complex` as complex doesn't define `<`

    assert_send_type  '[O < RBS::Ops::_LessThan[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :<, Coercable.new(Set[8, 4]){ |n| n.digits.to_set }
  end

  def test_op_lsh
    # omit 'todo'
  end

  def test_op_leq
    assert_send_type  '(Integer) -> bool',
                      38, :<=, 12
    assert_send_type  '(Rational) -> bool',
                      38, :<=, 12r
    assert_send_type  '(Float) -> bool',
                      38, :<=, 12.0
    # Notably not `Complex` as complex doesn't define `<=`

    assert_send_type  '[O < RBS::Ops::_LessThanOrEqual[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :<=, Coercable.new(Set[8, 4]){ |n| n.digits.to_set }
  end

  def test_op_cmp
    # omit 'todo'
  end

  def test_op_eq(method: :==)
    with_untyped.and 38 do |other|
      next unless defined? other.== # even for the `===` case heh
      assert_send_type  '(untyped) -> bool',
                        38, method, other
    end
  end

  def test_op_eqq
    test_op_eq(method: :===)
  end

  def test_op_gt
    assert_send_type  '(Integer) -> bool',
                      38, :>, 12
    assert_send_type  '(Rational) -> bool',
                      38, :>, 12r
    assert_send_type  '(Float) -> bool',
                      38, :>, 12.0
    # Notably not `Complex` as complex doesn't define `>`

    assert_send_type  '[O < RBS::Ops::_GreaterThan[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :>, Coercable.new(Set[8, 4]){ |n| n.digits.to_set }
  end

  def test_op_geq
    assert_send_type  '(Integer) -> bool',
                      38, :>=, 12
    assert_send_type  '(Rational) -> bool',
                      38, :>=, 12r
    assert_send_type  '(Float) -> bool',
                      38, :>=, 12.0
    # Notably not `Complex` as complex doesn't define `>`

    assert_send_type  '[O < RBS::Ops::_GreaterThanOrEqual[S, R], S, R] (Numeric::_Coerce[38, O, S]) -> R',
                      38, :>=, Coercable.new(Set[8, 4]){ |n| n.digits.to_set }
  end

  def test_op_rsh
    # omit 'todo'
  end

  def test_op_aref
    # omit 'todo'
  end

  def test_op_xor
    # omit 'todo'
  end

  def test_abs(method: :magnitude)
    assert_send_type  '() -> Integer',
                      38, method
    assert_send_type  '() -> Integer',
                      -38, method
  end

  def test_allbits?
    with_int 1 do |mask|
      assert_send_type  '(int) -> bool',
                        0, :allbits?, mask
      assert_send_type  '(int) -> bool',
                        1, :allbits?, mask
    end
  end

  def test_anybits?
    with_int 1 do |mask|
      assert_send_type  '(int) -> bool',
                        0, :anybits?, mask
      assert_send_type  '(int) -> bool',
                        1, :anybits?, mask
    end
  end

  def test_bit_length
    assert_send_type  '() -> Integer',
                      38, :bit_length
    assert_send_type  '() -> Integer',
                      3838, :bit_length
  end

  def test_ceil
    assert_send_type  '() -> Integer',
                      38, :ceil
    with_int(-1) do |digits|
      assert_send_type  '(int) -> Integer',
                        38, :ceil, digits
    end
  end

  def test_ceildiv
    # omit 'todo'
  end

  def test_chr
    assert_send_type  '() -> String',
                      38, :chr

    with_encoding do |encoding|
      assert_send_type  '(encoding) -> String',
                        38, :chr, encoding
    end
  end

  def test_coerce
    assert_send_type  '(Integer) -> [Integer, 38]',
                      38, :coerce, 4

    with_float do |float|
      assert_send_type  '(_ToF) -> [Float, Float]',
                        38, :coerce, float
    end
  end

  def test_denominator
    assert_send_type  '() -> 1',
                      38, :denominator
  end

  def test_digits
    assert_send_type  '() -> Array[Integer]',
                      38, :digits

    with_int 5 do |base|
      assert_send_type  '(int) -> Array[Integer]',
                        38, :digits, base
    end
  end

  def test_div
    # omit 'todo'
  end

  def test_divmod
    # omit 'todo'
  end

  def test_downto
    # omit 'todo'
  end

  def test_even?
    assert_send_type  '() -> bool',
                      38, :even?
    assert_send_type  '() -> bool',
                      39, :even?
  end

  def test_fdiv
    # omit 'todo'
  end

  def test_floor
    assert_send_type  '() -> Integer',
                      38, :floor
    with_int(-1) do |digits|
      assert_send_type  '(int) -> Integer',
                        38, :floor, digits
    end
  end

  def test_gcd
    assert_send_type  '(Integer) -> Integer',
                      38, :gcd, 2
    refute_send_type  '(_ToInt) -> Integer',
                      39, :gcd, ToInt.new(2) # explicitly only supports ints
  end

  def test_gcdlcm
    assert_send_type  '(Integer) -> [Integer, Integer]',
                      38, :gcdlcm, 2
    refute_send_type  '(_ToInt) -> [Integer, Integer]',
                      39, :gcdlcm, ToInt.new(2) # explicitly only supports ints
  end

  def test_inspect
    test_to_s(method: :inspect)
  end

  def test_integer?
    assert_send_type  '() -> true',
                      38, :integer?
  end

  def test_lcm
    assert_send_type  '(Integer) -> Integer',
                      38, :lcm, 2
    refute_send_type  '(_ToInt) -> Integer',
                      39, :lcm, ToInt.new(2) # explicitly only supports ints
  end

  def test_magnitude
    test_abs(method: :magnitude)
  end

  def test_modulo
    test_op_mod(method: :modulo)
  end

  def test_next
    test_succ(method: :next)
  end

  def test_nobits?
    with_int 1 do |mask|
      assert_send_type  '(int) -> bool',
                        0, :nobits?, mask
      assert_send_type  '(int) -> bool',
                        1, :nobits?, mask
    end
  end

  def test_numerator
    assert_send_type  '() -> 38',
                      38, :numerator
  end

  def test_odd?
    assert_send_type  '() -> bool',
                      38, :odd?
    assert_send_type  '() -> bool',
                      39, :odd?
  end

  def test_ord
    assert_send_type  '() -> 38',
                      38, :ord
  end

  def test_pow
    # omit 'todo'
  end

  def test_pred
    assert_send_type  '() -> Integer',
                      1, :pred
  end

  def test_rationalize
    assert_send_type  '() -> Rational',
                      38, :rationalize

    with Numeric.new do |eps|
      assert_send_type  '(Numeric) -> Rational',
                        38, :rationalize, eps
    end
  end

  def test_remainder
    # omit 'todo'
  end

  def test_round
    assert_send_type  '() -> Integer',
                      38, :round

    with_round_mode do |mode|
      assert_send_type  '(half: Numeric::round_mode) -> Integer',
                        38, :round, half: mode
    end

    with_int(-1) do |digits|
      assert_send_type  '(int) -> Integer',
                        38, :round, digits

      with_round_mode do |mode|
        assert_send_type  '(int, half: Numeric::round_mode) -> Integer',
                          38, :round, digits, half: mode
      end
    end
  end

  def test_size
    assert_send_type  '() -> Integer',
                      38, :size
    assert_send_type  '() -> Integer',
                      3838, :size
  end

  def test_succ(method: :succ)
    assert_send_type  '() -> Integer',
                      1, method
  end

  def test_times
    assert_send_type  '() { (Integer) -> void } -> 38',
                      38, :times do end
    assert_send_type  '() -> Enumerator[Integer, 38]',
                      38, :times
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      38, :to_f
  end

  def test_to_i(method: :to_i)
    assert_send_type  '() -> 38',
                      38, method
  end

  def test_to_int
    test_to_i(method: :to_int)
  end

  def test_to_r
    assert_send_type  '() -> Rational',
                      38, :to_r
  end

  def test_to_s(method: :to_s)
    assert_send_type  '() -> String',
                      38, method

    with_int 8 do |base|
      assert_send_type  '(int) -> String',
                        38, method, base
    end
  end

  def test_truncate
    assert_send_type  '() -> Integer',
                      38, :truncate
    with_int(-1) do |digits|
      assert_send_type  '(int) -> Integer',
                        38, :truncate, digits
    end
  end

  def test_upto
    # omit 'todo'
  end

  def test_zero?
    assert_send_type  '() -> bool',
                      0, :zero?
    assert_send_type  '() -> bool',
                      38, :zero?
  end

  def test_op_or
    # omit 'todo'
  end

  def test_op_not
    assert_send_type  '() -> Integer',
                      38, :~
  end
end

require_relative "test_helper"

class FloatConstantsTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Float)'

  def test_DIG
    assert_const_type 'Integer',
                      'Float::DIG'
  end

  def test_EPSILON
    assert_const_type 'Float',
                      'Float::EPSILON'
  end

  def test_INFINITY
    assert_const_type 'Float',
                      'Float::INFINITY'
  end

  def test_MANT_DIG
    assert_const_type 'Integer',
                      'Float::MANT_DIG'
  end

  def test_MAX
    assert_const_type 'Float',
                      'Float::MAX'
  end

  def test_MAX_10_EXP
    assert_const_type 'Integer',
                      'Float::MAX_10_EXP'
  end

  def test_MAX_EXP
    assert_const_type 'Integer',
                      'Float::MAX_EXP'
  end

  def test_MIN
    assert_const_type 'Float',
                      'Float::MIN'
  end

  def test_MIN_10_EXP
    assert_const_type 'Integer',
                      'Float::MIN_10_EXP'
  end

  def test_MIN_EXP
    assert_const_type 'Integer',
                      'Float::MIN_EXP'
  end

  def test_NAN
    assert_const_type 'Float',
                      'Float::NAN'
  end

  def test_RADIX
    assert_const_type 'Integer',
                      'Float::RADIX'
  end
end

class FloatInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Float'

  def test_mod(method: :%)
    assert_send_type  '(Integer) -> Float',
                      1.2, method, 3
    assert_send_type  '(Float) -> Float',
                      1.2, method, 4.5
    # use `:%` and not `methofd` as `Float#modulo` relies on `%` being defined not `modulo` when coercing
    with_coercible :% do |coercible|
      assert_send_type '[O < Numeric::_Modulo[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, method, coercible
    end
  end

  def test_mul
    assert_send_type  '(Integer) -> Float',
                      1.2, :*, 3
    assert_send_type  '(Float) -> Float',
                      1.2, :*, 4.5

    with_coercible :* do |coercible|
      assert_send_type '[O < Numeric::_Multiply[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :*, coercible
    end
  end

  def test_pow
    assert_send_type  '(Integer) -> Float',
                      7.8, :**, 12
    assert_send_type  '(Float) -> Float',
                      7.8, :**, 12.3
    assert_send_type  '(Float) -> Complex',
                      -7.8, :**, 0.5

    with_coercible :** do |coercible|
      assert_send_type '[O < Numeric::_Power[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :**, coercible
    end
  end

  def test_add
    assert_send_type  '(Integer) -> Float',
                      7.8, :+, 12
    assert_send_type  '(Float) -> Float',
                      7.8, :+, 12.3

    with_coercible :+ do |coercible|
      assert_send_type '[O < Numeric::_Add[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :+, coercible
    end
  end

  def test_sub
    assert_send_type  '(Integer) -> Float',
                      7.8, :-, 12
    assert_send_type  '(Float) -> Float',
                      7.8, :-, 12.3

    with_coercible :- do |coercible|
      assert_send_type '[O < Numeric::_Sub[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :-, coercible
    end
  end

  def test_uneg
    with -1.2, 0.0, 3.4 do |float|
      assert_send_type  '() -> Float',
                        float, :-@
    end
  end

  def test_div(method: :/)
    assert_send_type  '(Integer) -> Float',
                      7.8, method, 12
    assert_send_type  '(Float) -> Float',
                      7.8, method, 12.3

    with_coercible :/ do |coercible|
      assert_send_type '[O < Numeric::_Div[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, method, coercible
    end
  end

  def test_lth
    assert_send_type  '(Integer) -> bool',
                      7.8, :<, 12
    assert_send_type  '(Float) -> bool',
                      7.8, :<, 12.3

    with_coercible :< do |coercible|
      assert_send_type '[O < Numeric::_LessThan[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :<, coercible
    end
  end

  def test_leq
    assert_send_type  '(Integer) -> bool',
                      7.8, :<=, 12
    assert_send_type  '(Float) -> bool',
                      7.8, :<=, 12.3

    with_coercible :<= do |coercible|
      assert_send_type '[O < Numeric::_LessOrEqualTo[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :<=, coercible
    end
  end

  def test_cmp
    assert_send_type  '(Integer) -> -1',
                      7.8, :<=>, 12
    assert_send_type  '(Integer) -> nil',
                      Float::NAN, :<=>, 12

    assert_send_type  '(Float) -> 1',
                      7.8, :<=>, 1.3
    assert_send_type  '(Float) -> nil',
                      Float::NAN, :<=>, 1.3

    with_coercible :<=>, return_value: -1 do |coercible|
      assert_send_type '[O < Numeric::_Compare[S]] (Numeric::_Coerce[Float, O, S] other) -> (-1 | 0 | 1)',
                       1.2, :<=>, coercible
    end

    assert_send_type  '(untyped) -> nil',
                      1.2, :<=>, :hello
  end

  def test_eq(method: :==)
    with_untyped.and 1.2 do |other|
      def other.==(x) = true unless defined? other.==

      assert_send_type  '(untyped) -> bool',
                        1.2, method, other
    end
  end

  def test_eqq
    test_eq(method: :===)
  end

  def test_gth
    assert_send_type  '(Integer) -> bool',
                      7.8, :>, 12
    assert_send_type  '(Float) -> bool',
                      7.8, :>, 12.3

    with_coercible :> do |coercible|
      assert_send_type '[O < Numeric::_GreaterThan[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :>, coercible
    end
  end

  def test_geq
    assert_send_type  '(Integer) -> bool',
                      7.8, :>=, 12
    assert_send_type  '(Float) -> bool',
                      7.8, :>=, 12.3

    with_coercible :>= do |coercible|
      assert_send_type '[O < Numeric::_GreaterOrEqualTo[S, R], R] (Numeric::_Coerce[Float, O, S] other) -> R',
                       1.2, :>=, coercible
    end
  end

  def test_abs(method: :abs)
    with -1.2, 0.0, 3.4 do |float|
      assert_send_type  '() -> Float',
                        float, method
    end
  end

  def test_angle(method: :angle)
    assert_send_type  '() -> 0',
                      1.0, method
    assert_send_type  '() -> Float',
                      -1.0, method
  end

  def test_arg
    test_angle(method: :arg)
  end

  def test_ceil
    assert_send_type  '() -> Integer',
                      1.2, :ceil
    
    with_int -1 do |digits|
      assert_send_type  '(int) -> Integer',
                        1.2, :ceil, digits
    end

    with_int 2 do |digits|
      assert_send_type  '(int) -> Float',
                        1.2, :ceil, digits
    end
  end

  def test_coerce
    custom_to_f = BlankSlate.new
    def custom_to_f.to_f = 3.4

    with 1, 0i, 1r, custom_to_f do |other|
      assert_send_type  '(_ToF) -> [Float, Float]',
                        1.2, :coerce, other
    end
  end

  def test_denominator
    assert_send_type  '() -> Integer',
                      1.2, :denominator
  end

  def test_divmod
    assert_send_type  '(Integer) -> [Integer, Float]',
                      7.8, :divmod, 12
    assert_send_type  '(Float) -> [Integer, Float]',
                      7.8, :divmod, 12.3

    with_coercible :divmod, return_value: [1r, 2r] do |coercible|
      assert_send_type '[O < Numeric::_DivMod[S, W, P], S, W, P] (Numeric::_Coerce[Float, O, S] other) -> [W, P]',
                       1.2, :divmod, coercible
    end
  end

  def test_eql?
    with_untyped.and 1.2 do |other|
      assert_send_type  '(untyped) -> bool',
                        1.2, :eql?, other
    end
  end

  def test_fdiv
    test_quo(method: :fdiv)
  end

  def test_finite?
    with Float::INFINITY, Float::NAN, 1.2, 3.4 do |float|
      assert_send_type  '() -> bool',
                        float, :finite?
    end
  end

  def test_floor
    assert_send_type  '() -> Integer',
                      1.2, :floor
    
    with_int -1 do |digits|
      assert_send_type  '(int) -> Integer',
                        1.2, :floor, digits
    end

    with_int 2 do |digits|
      assert_send_type  '(int) -> Float',
                        1.2, :floor, digits
    end
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      1.2, :hash
  end

  def test_infinite?
    assert_send_type  '() -> 1',
                      Float::INFINITY, :infinite?
    assert_send_type  '() -> -1',
                      -Float::INFINITY, :infinite?
    with Float::NAN, 1.2, 3.4 do |float|
      assert_send_type  '() -> nil',
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
    test_mod(method: :modulo)
  end

  def test_nan?
    with Float::INFINITY, Float::NAN, 1.2, 3.4 do |float|
      assert_send_type  '() -> bool',
                        float, :nan?
    end
  end

  def test_negative?
    with Float::INFINITY, Float::NAN, 1.2, 3.4 do |float|
      assert_send_type  '() -> bool',
                        float, :negative?
    end
  end

  def test_next_float
    assert_send_type  '() -> Float',
                      1.2, :next_float
  end

  def test_numerator
    assert_send_type  '() -> Integer',
                      1.23, :numerator

    assert_send_type  '() -> Float',
                      Float::INFINITY, :numerator
  end

  def test_phase
    test_angle(method: :phase)
  end

  def test_positive?
    with Float::INFINITY, Float::NAN, 1.2, 3.4 do |float|
      assert_send_type  '() -> bool',
                        float, :positive?
    end
  end

  def test_prev_float
    assert_send_type  '() -> Float',
                      1.2, :prev_float
  end

  def test_quo(method: :quo)
    # Technically `quo` is not an alias of `/`, however all it does is call `/` internally. This is
    # only relevant if you subclass `Float` and override `/`, then `quo` (and `fdiv`) will follow
    # suit. Since we're not testing subclasses, and their signature are identical, we just pretend
    # like they're aliases for the test.
    test_div(method: method)
  end

  def test_rationalize
    assert_send_type  '() -> Rational',
                      1.2, :rationalize

    eps = BlankSlate.new
    def eps.abs = 1.2

    assert_send_type  '(Numeric::_Eps) -> Rational',
                      1.2, :rationalize, eps
  end

  def test_round
    assert_send_type  '() -> Integer',
                      1.2, :round

    with_int -1 do |digits|
      assert_send_type  '(int) -> Integer',
                        1.2, :round, digits
    end

    with_int 2 do |digits|
      assert_send_type  '(int) -> Float',
                        1.2, :round, digits
    end

    with(:up, :down, :even, nil).and with_string('up'), with_string('down'), with_string('even') do |dir|
      unless defined?(dir.==)
        def dir.==(rhs) = rhs == to_str
      end

      assert_send_type  '(half: Numeric::round_direction) -> Integer',
                        1.2, :round, half: dir
      assert_send_type  '(half: Numeric::round_direction) -> Integer',
                        1.2, :round, half: dir

      with_int -1 do |digits|
        assert_send_type  '(int, half: Numeric::round_direction) -> Integer',
                          1.2, :round, digits, half: dir
      end

      with_int 2 do |digits|
        assert_send_type  '(int, half: Numeric::round_direction) -> Float',
                          1.2, :round, digits, half: dir
      end
    end
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      1.2, :to_f
  end

  def test_to_i(method: :to_i)
    assert_send_type  '() -> Integer',
                      1.2, method
  end

  def test_to_int
    test_to_i(method: :to_int)
  end

  def test_to_r
    assert_send_type  '() -> Rational',
                      1.2, :to_r
  end

  def test_to_s(method: :to_s)
    assert_send_type  '() -> String',
                      1.2, method
  end

  def test_truncate
    assert_send_type  '() -> Integer',
                      1.2, :truncate
    assert_send_type  '() -> Integer',
                      -1.2, :truncate
    
    with_int -1 do |digits|
      assert_send_type  '(int) -> Integer',
                        1.2, :truncate, digits
      assert_send_type  '(int) -> Integer',
                        -1.2, :truncate, digits
    end

    with_int 2 do |digits|
      assert_send_type  '(int) -> Float',
                        1.2, :truncate, digits
      assert_send_type  '(int) -> Float',
                        -1.2, :truncate, digits
    end
  end

  def test_zero?
    assert_send_type  '() -> bool',
                      0.0, :zero?
    assert_send_type  '() -> bool',
                      0.1, :zero?
  end
end


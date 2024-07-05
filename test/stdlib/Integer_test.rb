require_relative "test_helper"


#     assert_send_type "(Integer) -> Integer",
#                      1, :pow, 2
#     assert_send_type "(Integer) -> Rational",
#                      -2, :pow, -1
#     assert_send_type "(Integer, Integer) -> Integer",
#                      1, :pow, 2, 10
#     assert_send_type "(Float) -> Float",
#                      1, :pow, 1.0
#     assert_send_type "(Float) -> Complex",
#                      -9, :pow, 0.1
#     assert_send_type "(Rational) -> Float",
#                      2, :pow, 1/2r
#     assert_send_type "(Rational) -> Rational",
#                      1, :pow, 1r
#     assert_send_type "(Rational) -> Complex",
#                      -3, :pow, -4/3r
#     assert_send_type "(Complex) -> Complex",
#                      1, :pow, 1i
#   end
# end
class IntegerSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Integer)"

  def test_sqrt
    with_int do |int|
      assert_send_type  '(int) -> Integer',
                        Integer, :sqrt, int
    end
  end

  def test_try_convert
    with_int do |int|
      assert_send_type  '(int) -> Integer',
                        Integer, :try_convert, int
    end

    with_untyped do |untyped|
      assert_send_type  '(untyped) -> Integer?',
                        Integer, :try_convert, untyped
    end
  end
end

class IntegerInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Integer"

  def with_random_Integers
    [0, -1, 100, -123, rand(-10000..10000)].each do |integer|
      yield integer
    end
  end

  def with_random_ints(&block)
    with_random_Integers do |integer|
      with_int(integer, &block)
    end
  end

  def test_op_mod(method: :%)
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, method, 123
      assert_send_type  '(Float) -> Float',
                        integer, method, 12.3

      with_coerce self: 'Integer', method: :% do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpMod[Y, Z], Y]) -> Z',
                          integer, method, coerced
      end
    end
  end

  def test_op_and
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :&, 123

      with_coerce self: 'Integer', method: :& do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpAnd[Y, Z], Y]) -> Z',
                          integer, :&, coerced
      end
    end
  end

  def test_op_mul
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :*, 123
      assert_send_type  '(Float) -> Float',
                        integer, :*, 12.3
      assert_send_type  '(Complex) -> Complex',
                        integer, :*, 12+3i

      with_coerce self: 'Integer', method: :* do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpMul[Y, Z], Y]) -> Z',
                          integer, :*, coerced
      end
    end
  end

  def test_op_pow
    omit "todo: #{__method__}"
    with_random_Integers do |integer|

    end
  end

  def test_op_add
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :+, 123
      assert_send_type  '(Float) -> Float',
                        integer, :+, 12.3
      assert_send_type  '(Complex) -> Complex',
                        integer, :+, 12+3i

      with_coerce self: 'Integer', method: :+ do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpAdd[Y, Z], Y]) -> Z',
                          integer, :+, coerced
      end
    end
  end

  def test_op_sub
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :-, 123
      assert_send_type  '(Float) -> Float',
                        integer, :-, 12.3

      with_coerce self: 'Integer', method: :- do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpSub[Y, Z], Y]) -> Z',
                          integer, :-, coerced
      end
    end
  end

  def test_op_uneg
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :-@
    end
  end

  def test_op_div
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :/, 123
      assert_send_type  '(Float) -> Float',
                        integer, :/, 12.3

      with_coerce self: 'Integer', method: :/ do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpDiv[Y, Z], Y]) -> Z',
                          integer, :/, coerced
      end
    end
  end

  def test_op_lt
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> bool',
                        integer, :<, 123
      assert_send_type  '(Float) -> bool',
                        integer, :<, 12.3

      with_coerce self: 'Integer', method: :<, return_value: integer < 12 do |coerced|
        assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpLt[Y], Y]) -> bool',
                          integer, :<, coerced
      end
    end
  end

  def test_op_rsh
    with_random_Integers do |integer|
      with_random_ints do |amount|
        assert_send_type  '(int) -> Integer',
                          integer, :<<, amount
      end
    end
  end

  def test_op_le
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> bool',
                        integer, :<=, 123
      assert_send_type  '(Float) -> bool',
                        integer, :<=, 12.3

      with_coerce self: 'Integer', method: :<=, return_value: integer <= 12 do |coerced|
        assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpLe[Y], Y]) -> bool',
                          integer, :<=, coerced
      end
    end
  end

  def test_op_cmp
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> (-1 | 0 | 1)',
                        integer, :<=>, 123
      assert_send_type  '(Float) -> (-1 | 0 | 1)',
                        integer, :<=>, 12.3
      
      with_untyped do |untyped|
        assert_send_type  '(untyped) -> (-1 | 0 | 1)?',
                          integer, :<=>, untyped
      end
    end
  end

  def test_op_eq(method: :==)
    with_random_Integers do |integer|
      with_untyped do |untyped|
        defined? untyped.== or def untyped.==(r) = true

        assert_send_type  '(untyped) -> bool',
                          integer, method, untyped
      end
    end
  end

  def test_op_eqq
    test_op_eq(method: :===)
  end

  def test_op_gt
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> bool',
                        integer, :>, 123
      assert_send_type  '(Float) -> bool',
                        integer, :>, 12.3

      with_coerce self: 'Integer', method: :>, return_value: integer > 12 do |coerced|
        assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGt[Y], Y]) -> bool',
                          integer, :>, coerced
      end
    end
  end

  def test_op_ge
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> bool',
                        integer, :>=, 123
      assert_send_type  '(Float) -> bool',
                        integer, :>=, 12.3

      with_coerce self: 'Integer', method: :>=, return_value: integer >= 12 do |coerced|
        assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGe[Y], Y]) -> bool',
                          integer, :>=, coerced
      end
    end
  end

  def test_op_lsh
    with_random_Integers do |integer|
      with_random_ints do |amount|
        assert_send_type  '(int) -> Integer',
                          integer, :<<, amount
      end
    end
  end

  def test_op_aref
    omit 'arg'
    with_random_Integers do |integer|
      with_random_ints do |offset|
        assert_send_type  '(int) -> Integer',
                          integer, :[], offset

        with_random_ints do |size|
          assert_send_type  '(int, int) -> Integer',
                            integer, :[], offset, size
        end
      end

      with_random_Integers do |start|
        with_random_Integers do |stop|
          with_range with_int(start), with_int(stop) do |range|
            # unless defined?
            assert_send_type  '(range[int]) -> Integer',
                              integer, :[], range
          end
        end
      end
    end
  end

  def test_op_xor
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :^, 123

      with_coerce self: 'Integer', method: :^ do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpXor[Y, Z], Y]) -> Z',
                          integer, :^, coerced
      end

    end
  end

  def test_abs(method: :abs)
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, method
    end
  end

  def test_allbits?
    with_random_Integers do |integer|
      with_random_ints do |mask|
        assert_send_type  '(int) -> bool',
                          integer, :allbits?, mask
      end
    end
  end

  def test_anybits?
    with_random_Integers do |integer|
      with_random_ints do |mask|
        assert_send_type  '(int) -> bool',
                          integer, :anybits?, mask
      end
    end
  end

  def test_bit_length
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :bit_length
    end
  end

  def test_ceil
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :ceil

      with_random_ints do |digits|
        assert_send_type  '(int) -> Integer',
                          integer, :ceil, digits
      end
    end
  end

  def test_ceildiv
    omit "todo: #{__method__}"
    with_random_Integers do |integer|

    end
  end

  def test_chr
    assert_send_type  '() -> String',
                      'a'.ord, :chr

    with_encoding do |enc|
      assert_send_type  '(encoding) -> String',
                        'a'.ord, :chr, enc
    end
  end

  def test_coerce
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> [Integer, Integer]',
                        integer, :coerce, 123
      
      with_float do |float|
        assert_send_type  '(float) -> [Float, Float]',
                          integer, :coerce, float
      end
    end
  end

  def test_denominator
    assert_send_type  '() -> 1',
                      123, :denominator
  end

  def test_digits
    with_random_Integers do |integer|
      integer = integer.abs # to prevent exceptions

      assert_send_type  '() -> Array[Integer]',
                        integer, :digits

      with_int 16 do |base|
        assert_send_type  '(int) -> Array[Integer]',
                          integer, :digits, base
      end
    end
  end

  def test_div
    omit 'TODO'
    # with_random_Integers do |integer|
    #   assert_send_type  '(Integer) -> Integer',
    #                     integer, :div, 123

    #   with_float 12.3 do |float|
    #     assert_send_type  '(float) -> Integer',
    #                       integer, :div, float
    #   end

    #   with_coerce self: 'Integer', method: :div, return_value: 12 do |coerced|
    #     assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_Div[Y], Y]) -> Integer',
    #                       integer, :div, coerced
    #   end
    # end
  end

  def test_divmod
    omit "todo: #{__method__}"
    with_random_Integers do |integer|

    end
  end

  def test_downto
    omit 'whyy'
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Enumerator[Integer, Integer]',
                        integer, :downto, 123
      assert_send_type  '(Float) -> Enumerator[Integer, Integer]',
                        integer, :downto, 12.3
      assert_send_type  '(Integer) { (Integer) -> void } -> Integer',
                        integer, :downto, 123 do |_| end
      assert_send_type  '(Float) { (Integer) -> void } -> Integer',
                        integer, :downto, 12.3 do |_| end

      coerced = BlankSlate.new.__with_object_methods(:define_singleton_method)
      geq = BlankSlate.new.__with_object_methods(:define_singleton_method)

      coerced.define_singleton_method(:coerce) do |rhs|
        [geq, rhs]
      end

      geq.define_singleton_method(:>=) do |x|
        # ::Kernel.p x
        x >= integer - 10
      end

      geq.define_singleton_method(:<) do |x|
        x < integer - 10
      end

      assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGe[Y], Y] limit) -> Enumerator[Integer, Integer]',
                        integer, :downto, coerced
      assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGe[Y], Y] limit) { (Integer) -> void } -> Integer',
                        integer, :downto, coerced do |i| end
    end
  end

  def test_even?
    with_random_Integers do |integer|
      assert_send_type  '() -> bool',
                        integer, :even?
    end
  end

  def test_fdiv
    omit "todo: #{__method__}"
    with_random_Integers do |integer|

    end
  end

  def test_floor
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :floor

      with_random_ints do |digits|
        assert_send_type  '(int) -> Integer',
                          integer, :floor, digits
      end
    end
  end

  def test_gcd
    with_random_Integers do |integer|
      with_random_Integers do |other_int|
        assert_send_type  '(Integer) -> Integer',
                          integer, :gcd, other_int
      end
    end
  end

  def test_gcdlcm
    with_random_Integers do |integer|
      with_random_Integers do |other_int|
        assert_send_type  '(Integer) -> [Integer, Integer]',
                          integer, :gcdlcm, other_int
      end
    end
  end

  def test_inspect
    test_to_s(method: :to_s)
  end

  def test_integer?
    assert_send_type  '() -> true',
                      123, :integer?
  end

  def test_lcm
    with_random_Integers do |integer|
      with_random_Integers do |other_int|
        assert_send_type  '(Integer) -> Integer',
                          integer, :lcm, other_int
      end
    end
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
    with_random_Integers do |integer|
      with_random_ints do |mask|
        assert_send_type  '(int) -> bool',
                          integer, :nobits?, mask
      end
    end
  end

  def test_numerator
    assert_send_type  '() -> Integer',
                      123, :numerator
  end

  def test_odd?
    with_random_Integers do |integer|
      assert_send_type  '() -> bool',
                        integer, :odd?
    end
  end

  def test_ord
    assert_send_type  '() -> Integer',
                      123, :ord
  end

  def test_pow
    omit "todo: #{__method__}" # actual todo
    with_random_Integers do |integer|

    end
  end

  def test_pred
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :pred
    end
  end

  def test_rationalize
    with_random_Integers do |integer|
      assert_send_type  '() -> Rational',
                        integer, :rationalize

      with_untyped do |untyped|
        assert_send_type  '(untyped) -> Rational',
                          integer, :rationalize, untyped
      end
    end
  end

  def test_remainder
    omit "todo: #{__method__}" # actual todo
    with_random_Integers do |integer|

    end
  end

  def test_round
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :round

      with_round_half do |half|
        assert_send_type  '(half: Numeric::round_half) -> Integer',
                          integer, :round, half: half

        with_random_ints do |digits|
          assert_send_type  '(int, half: Numeric::round_half) -> Integer',
                            integer, :round, digits, half: half
        end
      end
    end
  end

  def test_size
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :size
    end
  end

  def test_succ(method: :succ)
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, method
    end
  end

  def test_times
    with_random_Integers do |integer|
      assert_send_type  '() -> Enumerator[Integer, Integer]',
                        integer, :times
      assert_send_type  '() { (Integer) -> void } -> Integer',
                        integer, :times do |_| end
    end
  end

  def test_to_f
    assert_send_type  '() -> Float',
                      123, :to_f
  end

  def test_to_i
    assert_send_type  '() -> Integer',
                      123, :to_i
  end

  def test_to_int
    assert_send_type  '() -> Integer',
                      123, :to_int
  end

  def test_to_r
    assert_send_type  '() -> Rational',
                      123, :to_r
  end

  def test_to_s(method: :to_s)
    with_random_Integers do |integer|
      assert_send_type  '() -> String',
                        integer, method

      with_int 31 do |base|
        assert_send_type  '(int) -> String',
                          integer, method, base
      end
    end
  end

  def test_truncate
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        integer, :truncate

      with_random_ints do |digits|
        assert_send_type  '(int) -> Integer',
                          integer, :truncate, digits
      end
    end
  end

  def test_upto
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Enumerator[Integer, Integer]',
                        integer, :upto, 123
      assert_send_type  '(Float) -> Enumerator[Integer, Integer]',
                        integer, :upto, 12.3
      assert_send_type  '(Integer) { (Integer) -> void } -> Integer',
                        integer, :upto, 123 do |_| end
      assert_send_type  '(Float) { (Integer) -> void } -> Integer',
                        integer, :upto, 12.3 do |_| end

      coerced = BlankSlate.new.__with_object_methods(:define_singleton_method)
      geq = BlankSlate.new.__with_object_methods(:define_singleton_method)

      coerced.define_singleton_method(:coerce) do |rhs|
        [geq, rhs]
      end

      geq.define_singleton_method(:>) do |x|
        integer + 10 > x
      end

      assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGt[Y], Y] limit) -> Enumerator[Integer, Integer]',
                        integer, :upto, coerced
      assert_send_type  '[Y] (Numeric::_Coerce[Integer, Numeric::_OpGt[Y], Y] limit) { (Integer) -> void } -> Integer',
                        integer, :upto, coerced do |i| end
    end
  end

  def test_zero?
    with_random_Integers do |integer|
      assert_send_type  '() -> bool',
                        integer, :zero?
    end
  end

  def test_op_or
    with_random_Integers do |integer|
      assert_send_type  '(Integer) -> Integer',
                        integer, :|, 123

      with_coerce self: 'Integer', method: :| do |coerced|
        assert_send_type  '[Y, Z] (Numeric::_Coerce[Integer, Numeric::_OpOr[Y, Z], Y]) -> Z',
                          integer, :|, coerced
      end
    end
  end

  def test_op_comp
    with_random_Integers do |integer|
      assert_send_type  '() -> Integer',
                        123, :~@
    end
  end
end

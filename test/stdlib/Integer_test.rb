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

  def test_op_mod
    omit 'todo'
  end

  def test_op_and
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
    assert_send_type  '() -> Integer',
                      38, :-@
  end

  def test_op_div
    omit 'todo'
  end

  def test_op_lt
    omit 'todo'
  end

  def test_op_lsh
    omit 'todo'
  end

  def test_op_leq
    omit 'todo'
  end

  def test_op_cmp
    omit 'todo'
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
    omit 'todo'
  end

  def test_op_geq
    omit 'todo'
  end

  def test_op_rsh
    omit 'todo'
  end

  def test_op_aref
    omit 'todo'
  end

  def test_op_xor
    omit 'todo'
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
    omit 'todo'
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
    omit 'todo'
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
    omit 'todo'
  end

  def test_divmod
    omit 'todo'
  end

  def test_downto
    omit 'todo'
  end

  def test_even?
    assert_send_type  '() -> bool',
                      38, :even?
    assert_send_type  '() -> bool',
                      39, :even?
  end

  def test_fdiv
    omit 'todo'
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
    omit 'todo'
  end

  def test_gcdlcm
    omit 'todo'
  end

  def test_inspect
    test_to_s(method: :inspect)
  end

  def test_integer?
    assert_send_type  '() -> true',
                      38, :integer?
  end

  def test_lcm
    omit 'todo'
  end

  def test_magnitude
    test_abs(method: :magnitude)
  end

  def test_modulo
    omit 'todo'
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
    omit 'todo'
  end

  def test_pred
    assert_send_type  '() -> Integer',
                      1, :pred
  end

  def test_rationalize
    omit 'todo'
  end

  def test_remainder
    omit 'todo'
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
    assert_send_type  '() { (Integer) -> 38',
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
    omit 'todo'
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
    omit 'todo'
  end

  def test_zero?
    assert_send_type  '() -> Integer',
                      0, :zero?
    assert_send_type  '() -> Integer',
                      38, :zero?
  end

  def test_op_or
    omit 'todo'
  end

  def test_op_not
    assert_send_type  '() -> Integer',
                      38, :~
  end
end

__END__
class IntegerTest < StdlibTest
  target Integer

  def test_sqrt
    Integer.sqrt(4)
    Integer.sqrt(4.0)
    Integer.sqrt(4/1r)
    Integer.sqrt(ToInt.new)
  end

  def test_modulo
    3 % 1
    3 % 1.1
    3 % 1.5r
  end

  def test_bitwise_ops
    3 & 1
    1 ^ 3
  end

  def test_calc
    3 * 1
    3 * 1.0
    3 * (1r/3)

    3 - 1
    3 - 0.1
    3 - 1r
    3 - 1.to_c

    1 ** 1
    2 ** 2.1
    3 ** 3r
    3 ** 10.to_c

    3 + 1
    3 + 1.0
    3 + (1r/3)
    3 + 10.to_c

    3 / 1
    3 / 1.0
    3 / (1r/3)
    30 / 10.to_c
  end

  def test_compare
    3 < 1
    3 < 1.0
    3 < 1r

    1 > 1
    1 > 1.0
    1 > 1r

    1 <= 3
    1 <= 1.3
    1 <= 3r

    1 >= 3
    1 >= 1.3
    1 >= 3r

    1 <=> 1
    1 <=> 1.0
    1 <=> 3r

    3 === 3.0
    3 === ""
  end

  def test_shift
    1 << 30
    1 << 30.to_f
    1 << ToInt.new

    1 >> 30
    1 >> 30.to_f
    1 >> ToInt.new
  end

  def test_aref
    3[0]
    3[0.3]
    3[ToInt.new]

    3[1,2]
    3[1...3]
  end

  def test_to_s
    1.to_s
    1.to_s(2)
    1.to_s(3)
    1.to_s(4)
    1.to_s(5)
    1.to_s(6)
    1.to_s(7)
    1.to_s(8)
    1.to_s(9)
    1.to_s(10)
    1.to_s(11)
    1.to_s(12)
    1.to_s(13)
    1.to_s(14)
    1.to_s(15)
    1.to_s(16)
    1.to_s(17)
    1.to_s(18)
    1.to_s(19)
    1.to_s(20)
    1.to_s(21)
    1.to_s(22)
    1.to_s(23)
    1.to_s(24)
    1.to_s(25)
    1.to_s(26)
    1.to_s(27)
    1.to_s(28)
    1.to_s(29)
    1.to_s(30)
    1.to_s(31)
    1.to_s(32)
    1.to_s(33)
    1.to_s(34)
    1.to_s(35)
    1.to_s(36)
    30.to_s(ToInt.new)
  end

  def test_abs_abs2
    3.abs
    3.abs2
  end

  def test_allbits?
    1.allbits?(1)
    2.allbits?(1)
    3.allbits?(ToInt.new)
  end

  def test_angle
    3.angle()
  end

  def test_anybits?
    0xf0.anybits?(0xf)
    0xf1.anybits?(0xf)
    0xf1.anybits?(ToInt.new)
  end

  def test_arg
    3.arg
  end

  def test_bit_length
    3.bit_length
  end

  def test_ceil
    3.ceil
    3.ceil(10)
    3.ceil(ToInt.new)
  end

  def test_ceildiv
    3.ceildiv(10)
    3.ceildiv(1.3)
  end

  def test_chr
    3.chr
    3.chr(Encoding::UTF_8)
    3.chr("UTF-7")
    3.chr(ToStr.new("ASCII-8BIT"))
  end

  def test_conj
    3.conj
  end

  def test_denominator
    3.denominator
  end

  def test_digits
    3.digits
    3.digits(3)
    3.digits(3.0)
    30.digits(ToInt.new)
  end

  def test_div
    30.div(10)
  end

  def test_div_mod
    3.divmod(3)
    40.divmod(1.0)
    30.divmod(30r)
  end

  def test_down_to
    30.downto(1) {}
    30.downto(31)
    30.downto(4.2)
  end

  def test_even?
    30.even?
  end

  def test_fdiv
    30.fdiv(30)
    30.fdiv(3r)
    30.fdiv(3.1)
  end

  def test_finite?
    30.finite?
  end

  def test_floor
    30.floor
    30.floor(3)
    30.floor(ToInt.new)
  end

  def test_gcd
    30.gcd(1)
  end

  def test_gcdlcm
    30.gcdlcm(31)
  end

  def test_lcm
    30.lcm(50)
  end

  def test_magnitude
    30.magnitude
  end

  def test_modulo_
    30.modulo(30)
    30.modulo(3.1)
    30.modulo(3r/5)
  end

  def test_next
    30.next
  end

  def test_nobits?
    0xf0.nobits?(0xf)
    0xf1.nobits?(0xf)
    30.nobits?(ToInt.new)
  end

  def test_nonzero?
    30.nonzero?
    0.nonzero?
  end

  def test_numerator
    30.numerator
  end

  def test_pow
    1.pow(30)
    1.pow(2.0)
    1.pow(30.to_c)
    3.pow(3, 5)
  end

  def test_quo
    3.quo(1)
    3.quo(2.1)
    3.quo(4r/5)
    3.quo(10.to_c)
  end

  def test_rationalize
    3.rationalize
    3.rationalize(30)
  end

  def test_remainder
    3.remainder(1)
    3.remainder(1.3)
    3.remainder(1r/3)
  end

  def test_round
    13.round()
    13.round(half: :up)
    14.round(-1, half: :down)
    15.round(ToInt.new)
  end

  def test_step
    3.step { break }
    3.step
    3.step(10, 2) {}
    3.step(10, 2)
    3.step(10, 1.1) {}
    3.step(10, 1.1)

    3.step(to: 30) { break }
    3.step(to: 30)
    3.step(to: 30, by: 100) {}
    3.step(to: 30, by: 100)
    3.step(to: 30, by: 10.0) {}
    3.step(to: 30, by: 10.0)
  end

  def test_times
    3.times {}
    3.times
  end

  def test_truncate
    100.truncate
    100.truncate(10)
    100.truncate(ToInt.new(-2))
  end

  def test_upto
    5.upto(10) {}
    5.upto(10.1) {}
  end
end


class IntegerSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Integer)"

  def test_try_convert
    assert_send_type(
      "(Integer) -> Integer",
      Integer, :try_convert, 10
    )
    assert_send_type(
      "(ToInt) -> Integer",
      Integer, :try_convert, ToInt.new(10)
    )
    assert_send_type(
      "(String) -> nil",
      Integer, :try_convert, "10"
    )
  end
end

class IntegerInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Integer"

  def test_pow
    assert_send_type "(Integer) -> Integer",
                     1, :pow, 2
    assert_send_type "(Integer) -> Rational",
                     -2, :pow, -1
    assert_send_type "(Integer, Integer) -> Integer",
                     1, :pow, 2, 10
    assert_send_type "(Float) -> Float",
                     1, :pow, 1.0
    assert_send_type "(Float) -> Complex",
                     -9, :pow, 0.1
    assert_send_type "(Rational) -> Float",
                     2, :pow, 1/2r
    assert_send_type "(Rational) -> Rational",
                     1, :pow, 1r
    assert_send_type "(Rational) -> Complex",
                     -3, :pow, -4/3r
    assert_send_type "(Complex) -> Complex",
                     1, :pow, 1i
  end
end

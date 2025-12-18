require_relative "test_helper"
require "bigdecimal"
require "bigdecimal/math"

class BigMathSingletonTest < Test::Unit::TestCase
  include TestHelper
  library "bigdecimal", "bigdecimal-math"
  testing "singleton(::BigMath)"

  def test_E
    assert_send_type  "(::Numeric prec) -> ::BigDecimal",
                      BigMath, :E, 10
  end

  def test_PI
    assert_send_type  "(::Numeric prec) -> ::BigDecimal",
                      BigMath, :PI, 10
  end

  def test_acos
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :acos, BigDecimal('0.5'), 32
  end

  def test_acosh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :acosh, BigDecimal('2'), 32
  end

  def test_asin
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :asin, BigDecimal('0.5'), 32
  end

  def test_asinh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :asinh, BigDecimal('1'), 32
  end

  def test_atan
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :atan, BigDecimal('1.23'), 10
  end

  def test_atan2
    assert_send_type "(::BigDecimal, ::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :atan2, BigDecimal('-1'), BigDecimal('1'), 32
  end

  def test_atanh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :atanh, BigDecimal('0.5'), 32
  end

  def test_cbrt
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :cbrt, BigDecimal('2'), 32
  end

  def test_cos
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :cos, BigDecimal('1.23'), 10
  end

  def test_cosh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :cosh, BigDecimal('1'), 32
  end

  def test_erf
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :erf, BigDecimal('1'), 32
  end

  def test_erfc
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :erfc, BigDecimal('10'), 32
  end

  def test_exp
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :exp, BigDecimal('1.23'), 10
  end

  def test_frexp
    assert_send_type "(::BigDecimal) -> [::BigDecimal, ::Integer]",
                     BigMath, :frexp, BigDecimal(123.456)
  end

  def test_gamma
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :gamma, BigDecimal('0.5'), 32
  end

  def test_hypot
    assert_send_type "(::BigDecimal, ::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :hypot, BigDecimal('1'), BigDecimal('2'), 32
  end

  def test_ldexp
    assert_send_type "(::BigDecimal, ::Integer) -> ::BigDecimal",
                     BigMath, :ldexp, BigDecimal("0.123456e0"), 3
  end

  def test_lgamma
    assert_send_type "(::BigDecimal, ::Numeric) -> [::BigDecimal, ::Integer]",
                     BigMath, :lgamma, BigDecimal('0.5'), 32
  end

  def test_log
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :log, BigDecimal('1.23'), 10
  end

  def test_log2
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :log2, BigDecimal('3'), 32
  end

  def test_sin
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :sin, BigDecimal('1.23'), 10
  end

  def test_sinh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :sinh, BigDecimal('1'), 32
  end

  def test_sqrt
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :sqrt, BigDecimal('1.23'), 10
  end

  def test_tanh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     BigMath, :tanh, BigDecimal('1'), 32
  end
end

class BigMathTest < Test::Unit::TestCase
  include TestHelper
  library "bigdecimal", "bigdecimal-math"
  testing "::BigMath"

  class TestClass
    include BigMath
  end

  def test_E
    assert_send_type  "(::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :E, 10
  end

  def test_PI
    assert_send_type  "(::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :PI, 10
  end

  def test_acos
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :acos, BigDecimal('0.5'), 32
  end

  def test_acosh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :acosh, BigDecimal('2'), 32
  end

  def test_asin
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :asin, BigDecimal('0.5'), 32
  end

  def test_asinh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :asinh, BigDecimal('1'), 32
  end

  def test_atan
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :atan, BigDecimal('1.23'), 10
  end

  def test_atan2
    assert_send_type "(::BigDecimal, ::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :atan2, BigDecimal('-1'), BigDecimal('1'), 32
  end

  def test_atanh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :atanh, BigDecimal('0.5'), 32
  end

  def test_cbrt
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :cbrt, BigDecimal('2'), 32
  end

  def test_cos
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :cos, BigDecimal('1.23'), 10
  end

  def test_cosh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :cosh, BigDecimal('1'), 32
  end

  def test_erf
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :erf, BigDecimal('1'), 32
  end

  def test_erfc
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :erfc, BigDecimal('10'), 32
  end

  def test_exp
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :exp, BigDecimal('1.23'), 10
  end

  def test_frexp
    assert_send_type "(::BigDecimal) -> [::BigDecimal, ::Integer]",
                     TestClass.new, :frexp, BigDecimal(123.456)
  end

  def test_gamma
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :gamma, BigDecimal('0.5'), 32
  end

  def test_hypot
    assert_send_type "(::BigDecimal, ::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :hypot, BigDecimal('1'), BigDecimal('2'), 32
  end

  def test_ldexp
    assert_send_type "(::BigDecimal, ::Integer) -> ::BigDecimal",
                     TestClass.new, :ldexp, BigDecimal("0.123456e0"), 3
  end

  def test_lgamma
    assert_send_type "(::BigDecimal, ::Numeric) -> [::BigDecimal, ::Integer]",
                     TestClass.new, :lgamma, BigDecimal('0.5'), 32
  end

  def test_log
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :log, BigDecimal('1.23'), 10
  end

  def test_log2
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :log2, BigDecimal('3'), 32
  end
  def test_sin
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :sin, BigDecimal('1.23'), 10
  end

  def test_sinh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :sinh, BigDecimal('1'), 32
  end

  def test_sqrt
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :sqrt, BigDecimal('1.23'), 10
  end

  def test_tanh
    assert_send_type "(::BigDecimal, ::Numeric) -> ::BigDecimal",
                     TestClass.new, :tanh, BigDecimal('1'), 32
  end
end

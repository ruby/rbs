require_relative "test_helper"
require "bigdecimal"
require "bigdecimal/math"

class BigMathSingletonTest < Minitest::Test
  include TypeAssertions
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

  def test_atan
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :atan, BigDecimal('1.23'), 10
  end

  def test_cos
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :cos, BigDecimal('1.23'), 10
  end

  def test_exp
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :exp, BigDecimal('1.23'), 10
  end

  def test_log
    assert_send_type  "(::BigDecimal, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :log, BigDecimal('1.23'), 10
  end

  def test_sin
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :sin, BigDecimal('1.23'), 10
  end

  def test_sqrt
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      BigMath, :sqrt, BigDecimal('1.23'), 10
  end
end

class BigMathTest < Minitest::Test
  include TypeAssertions
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

  def test_atan
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :atan, BigDecimal('1.23'), 10
  end

  def test_cos
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :cos, BigDecimal('1.23'), 10
  end

  def test_sin
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :sin, BigDecimal('1.23'), 10
  end

  def test_sqrt
    assert_send_type  "(::BigDecimal x, ::Numeric prec) -> ::BigDecimal",
                      TestClass.new, :sqrt, BigDecimal('1.23'), 10
  end
end

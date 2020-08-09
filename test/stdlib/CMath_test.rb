require_relative "test_helper"


class CMathTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::CMath"


  def test_acos
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :acos
  end

  def test_acosh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :acosh
  end

  def test_asin
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :asin
  end

  def test_asinh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :asinh
  end

  def test_atan
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :atan
  end

  def test_atan2
    assert_send_type  "(::Numeric y, ::Numeric x) -> ::Numeric",
                      CMath.new, :atan2
  end

  def test_atanh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :atanh
  end

  def test_cbrt
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :cbrt
  end

  def test_cos
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :cos
  end

  def test_cosh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :cosh
  end

  def test_exp
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :exp
  end

  def test_log
    assert_send_type  "(::Numeric z, ?::Numeric b) -> ::Numeric",
                      CMath.new, :log
  end

  def test_log10
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :log10
  end

  def test_log2
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :log2
  end

  def test_sin
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :sin
  end

  def test_sinh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :sinh
  end

  def test_sqrt
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :sqrt
  end

  def test_tan
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :tan
  end

  def test_tanh
    assert_send_type  "(::Numeric z) -> ::Numeric",
                      CMath.new, :tanh
  end
end

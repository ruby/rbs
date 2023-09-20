require_relative 'test_helper'

class MathSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(::Math)'

  def test_E
    assert_const_type 'Float', 'Math::E'
  end

  def test_PI
    assert_const_type 'Float', 'Math::PI'
  end

  def test_DomainError
    assert_const_type 'Class', 'Math::DomainError'
  end

  class Double < Numeric
    def initialize(num) @num = num end
    def to_f; @num end
  end

  def with_double(num)
    yield num
    yield Double.new(num)
  end

  def test_acos
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :acos, double
    end
  
    refute_send_type  '(_ToF) -> Float',
                      Math, :acos, ToF.new(0.0)
  end

  def test_acosh
    with_double 2.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :acosh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :acosh, ToF.new(2.0)
  end

  def test_asin
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :asin, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :asin, ToF.new(0.0)
  end

  def test_asinh
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :asinh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :asinh, ToF.new(0.0)
  end

  def test_atan
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :atan, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :atan, ToF.new(0.0)
  end

  def test_atan2
    with_double 0.0 do |y|
      with_double 0.0 do |x|
        assert_send_type  '(Math::double, Math::double) -> Float',
                          Math, :atan2, y, x
      end
    end

    refute_send_type  '(_ToF, _ToF) -> Float',
                      Math, :atan2, ToF.new(0.0), ToF.new(0.0)
  end

  def test_atanh
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :atanh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :atanh, ToF.new(0.0)
  end

  def test_cbrt
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :cbrt, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :cbrt, ToF.new(0.0)
  end

  def test_cos
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :cos, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :cos, ToF.new(0.0)
  end

  def test_cosh
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :cosh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :cosh, ToF.new(0.0)
  end

  def test_erf
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :erf, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :erf, ToF.new(0.0)
  end

  def test_erfc
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :erfc, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :erfc, ToF.new(0.0)
  end

  def test_exp
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :exp, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :exp, ToF.new(0.0)
  end

  def test_frexp
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> [Float, Integer]',
                        Math, :frexp, double
    end

    refute_send_type  '(_ToF) -> [Float, Integer]',
                      Math, :frexp, ToF.new(0.0)
  end

  def test_gamma
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :gamma, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :gamma, ToF.new(0.0)
  end

  def test_hypot
    with_double 3.0 do |a|
      with_double 4.0 do |b|
        assert_send_type  '(Math::double, Math::double) -> Float',
                          Math, :hypot, a, b
      end
    end

    refute_send_type  '(_ToF, _ToF) -> Float',
                      Math, :hypot, ToF.new(3.0), ToF.new(4.0)
  end

  def test_ldexp
    with_double 0.0 do |double|
      with_int 2 do |int|
        assert_send_type  '(Math::double, int) -> Float',
                          Math, :ldexp, double, int
      end
    end

    refute_send_type  '(_ToF, Integer) -> Float',
                      Math, :ldexp, ToF.new(0.0), 2
  end

  def test_lgamma
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> [Float, 1]',
                        Math, :lgamma, double
    end

    with_double -0.3 do |double|
      assert_send_type  '(Math::double) -> [Float, -1]',
                        Math, :lgamma, double
    end

    refute_send_type  '(_ToF) -> [Float, Integer]',
                      Math, :lgamma, ToF.new(0.0)
  end

  def test_log
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :log, double
  
      with_double 0.0 do |base|
        assert_send_type  '(Math::double, Math::double) -> Float',
                          Math, :log, double, base
      end
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :log, ToF.new(0.0)
    refute_send_type  '(_ToF, _ToF) -> Float',
                      Math, :log, ToF.new(0.0), ToF.new(0.0)
  end

  def test_log10
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :log10, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :log10, ToF.new(0.0)
  end

  def test_log2
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :log2, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :log2, ToF.new(0.0)
  end

  def test_sin
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :sin, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :sin, ToF.new(0.0)
  end

  def test_sinh
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :sinh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :sinh, ToF.new(0.0)
  end

  def test_sqrt
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :sqrt, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :sqrt, ToF.new(0.0)
  end

  def test_tan
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :tan, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :tan, ToF.new(0.0)
  end

  def test_tanh
    with_double 0.0 do |double|
      assert_send_type  '(Math::double) -> Float',
                        Math, :tanh, double
    end

    refute_send_type  '(_ToF) -> Float',
                      Math, :tanh, ToF.new(0.0)
  end
end

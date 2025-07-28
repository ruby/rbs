require_relative "test_helper"

class NumericInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Numeric'

  def test_real
    assert_send_type '() -> Integer', 1, :real
    assert_send_type '() -> Float', 1.0, :real
    assert_send_type '() -> Rational', 1r, :real
  end

  def test_real?
    assert_send_type '() -> true', 1, :real?
    assert_send_type '() -> true', 1.0, :real?
    assert_send_type '() -> true', 1r, :real?
  end

  def test_zero?
    assert_send_type '() -> bool', 0, :zero?
    assert_send_type '() -> bool', 1r, :zero?
  end

  def test_angle
    assert_send_type '() -> 0', 1, :angle
    assert_send_type '() -> Float', -1, :angle
    assert_send_type '() -> Float', Float::NAN, :angle
  end

  def test_abs2
    assert_send_type '() -> Integer', 1, :abs2
    assert_send_type '() -> Float', 1.0, :abs2
    assert_send_type '() -> Rational', 1r, :abs2
  end

  def test_to_c
    assert_send_type '() -> Complex', 1, :to_c
    assert_send_type '() -> Complex', 1.0, :to_c
    assert_send_type '() -> Complex', 1r, :to_c
  end
end

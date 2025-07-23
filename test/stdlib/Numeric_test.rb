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
end

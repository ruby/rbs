require_relative "test_helper"
require "timeout"
require "bigdecimal"

class TimeoutSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "timeout"
  testing "singleton(::Timeout)"

  def test_timeout
    proc = Proc.new { |sec| sec * sec }
    assert_send_type  "(::Integer sec) { (::Integer sec) -> ::Integer } -> ::Integer",
                      Timeout, :timeout, 5, &proc
    assert_send_type  "(::Float sec) { (::Float sec) -> ::Float } -> ::Float",
                      Timeout, :timeout, 1.2, &proc
    assert_send_type  "(::Rational sec)  { (::Rational sec) -> ::Rational } -> ::Rational",
                      Timeout, :timeout, Rational(5, 3), &proc
    assert_send_type  "(::BigDecimal sec) { (::BigDecimal sec) -> ::BigDecimal } -> ::BigDecimal",
                      Timeout, :timeout, BigDecimal("1.123456789123456789"), &proc
  end
end

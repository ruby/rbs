require_relative "test_helper"
require "timeout"
require "bigdecimal"

class TimeoutSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "timeout"
  testing "singleton(::Timeout)"

  class TimeoutTestException < Exception; end # exception class for test

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

    hard_process = Proc.new { _calc_pi }
    refute_send_type  "(::Numeric sec): [T] { (::Numeric sec) -> T } -> T",
                      Timeout, :timeout, 0.001, &hard_process
    refute_send_type  "(::Numeric sec, singleton(Exception) klass): [T] { (::Numeric sec) -> T } -> T",
                      Timeout, :timeout, 0.001, TimeoutTestException, &hard_process
    refute_send_type  "(::Numeric sec, singleton(Exception) klass, String message): [T] { (::Numeric sec) -> T } -> T",
                      Timeout, :timeout, 0.001, TimeoutTestException, "timeout test error", &hard_process
  end

  def _calc_pi
    min = [0, 0]
    loop do
      x = rand
      y = rand
      x**2 + y**2 < 1.0 ?  min[0] += 1 : min[1] += 1
    end
  end
end

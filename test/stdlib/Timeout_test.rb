require_relative "test_helper"
require "timeout"
require "bigdecimal"

class TimeoutSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "timeout"
  testing "singleton(::Timeout)"

  def test_version
    assert_const_type "String", "Timeout::VERSION"
  end

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

    assert_send_type  "(nil sec) { (nil sec) -> nil } -> nil",
                      Timeout, :timeout, nil do |sec| sec end
    assert_send_type  "(::Integer sec, nil, nil) { (::Integer sec) -> ::Integer } -> ::Integer",
                      Timeout, :timeout, 5, nil, nil, &proc
    assert_send_type  "(::Integer sec, singleton(::ArgumentError), ::String) { (::Integer sec) -> ::Integer } -> ::Integer",
                      Timeout, :timeout, 5, ArgumentError, "too slow", &proc
  end
end

class TimeoutErrorTest < Test::Unit::TestCase
  include TestHelper

  library "timeout"
  testing "singleton(::Timeout::Error)"

  def test_handle_timeout
    assert_send_type "(String) { (Timeout::ExitException) -> Symbol } -> Symbol",
                     Timeout::Error, :handle_timeout, "msg" do |_exc|
      :ok
    end
  end
end

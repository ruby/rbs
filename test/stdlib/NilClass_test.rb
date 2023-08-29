require_relative "test_helper"

class NilClassInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::NilClass'

  def test_not
    assert_send_type "() -> true",
                     nil, :!
  end

  def test_and
    assert_send_type "(nil) -> false",
                     nil, :&, nil
    assert_send_type "(false) -> false",
                     nil, :&, false
    assert_send_type "(true) -> false",
                     nil, :&, true
    assert_send_type "(untyped) -> false",
                     nil, :&, Object.new
  end

  def test_eqq
    assert_send_type "(nil) -> true",
                     nil, :===, nil
    assert_send_type "(false) -> false",
                     nil, :===, false
    assert_send_type "(true) -> false",
                     nil, :===, true
    assert_send_type "(untyped) -> false",
                     nil, :===, Object.new
  end

  def test_match
    assert_send_type "(untyped) -> nil",
                     nil, :=~, Object.new
  end

  def test_xor
    assert_send_type "(nil) -> false",
                     nil, :^, nil
    assert_send_type "(false) -> false",
                     nil, :^, false
    assert_send_type "(true) -> true",
                     nil, :^, true
    assert_send_type "(untyped) -> true",
                     nil, :^, Object.new
  end

  def test_inspect
    assert_send_type "() -> 'nil'",
                     nil, :inspect
  end

  def test_nil?
    assert_send_type "() -> true",
                     nil, :nil?
  end

  def test_rationalize
    assert_send_type "() -> Rational",
                     nil, :rationalize
    assert_send_type "(untyped) -> Rational",
                     nil, :rationalize, Object.new
  end

  def test_to_a
    assert_send_type "() -> []",
                     nil, :to_a
  end

  def test_to_c
    assert_send_type "() -> Complex",
                     nil, :to_c
  end

  def test_to_f
    assert_send_type "() -> Float",
                     nil, :to_f
  end

  def test_to_h
    assert_send_type "() -> Hash[untyped, untyped]",
                     nil, :to_h
  end

  def test_to_i
    assert_send_type "() -> 0",
                     nil, :to_i
  end

  def test_to_r
    assert_send_type "() -> Rational",
                     nil, :to_r
  end

  def test_to_s
    assert_send_type "() -> ''",
                     nil, :to_s
  end

  def test_or
    assert_send_type "(nil) -> false",
                     nil, :|, nil
    assert_send_type "(false) -> false",
                     nil, :|, false
    assert_send_type "(true) -> true",
                     nil, :|, true
    assert_send_type "(untyped) -> true",
                     nil, :|, Object.new
  end
end

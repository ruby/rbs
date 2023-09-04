require_relative "test_helper"

class FalseClassInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::FalseClass'

  def test_not
    assert_send_type "() -> true",
                     false, :!
  end

  def test_and
    assert_send_type "(false) -> false",
                     false, :&, false
    assert_send_type "(true) -> false",
                     false, :&, true
    assert_send_type "(nil) -> false",
                     false, :&, nil
    assert_send_type "(untyped) -> false",
                     false, :&, Object.new
  end

  def test_eqq
    assert_send_type "(false) -> true",
                     false, :===, false
    assert_send_type "(true) -> false",
                     false, :===, true
    assert_send_type "(nil) -> false",
                     false, :===, nil
    assert_send_type "(untyped) -> false",
                     false, :===, Object.new
  end

  def test_xor
    assert_send_type "(false) -> false",
                     false, :^, false
    assert_send_type "(true) -> true",
                     false, :^, true
    assert_send_type "(nil) -> false",
                     false, :^, nil
    assert_send_type "(untyped) -> true",
                     false, :^, Object.new
  end

  def test_inspect
    assert_send_type "() -> 'false'",
                     false, :inspect
  end

  def test_to_s
    assert_send_type "() -> 'false'",
                     false, :to_s
  end

  def test_or
    assert_send_type "(false) -> false",
                     false, :|, false
    assert_send_type "(true) -> true",
                     false, :|, true
    assert_send_type "(nil) -> false",
                     false, :|, nil
    assert_send_type "(untyped) -> true",
                     false, :|, Object.new
  end
end

require_relative "test_helper"

class TrueClassInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::TrueClass'

  def test_not
    assert_send_type "() -> false",
                     true, :!
  end

  def test_and
    assert_send_type "(true) -> true",
                     true, :&, true
    assert_send_type "(nil) -> false",
                     true, :&, nil
    assert_send_type "(false) -> false",
                     true, :&, false
    assert_send_type "(untyped) -> true",
                     true, :&, Object.new
  end

  def test_eqq
    assert_send_type "(true) -> true",
                     true, :===, true
    assert_send_type "(nil) -> false",
                     true, :===, nil
    assert_send_type "(false) -> false",
                     true, :===, false
    assert_send_type "(untyped) -> false",
                     true, :===, Object.new
  end

  def test_xor
    assert_send_type "(true) -> false",
                     true, :^, true
    assert_send_type "(nil) -> true",
                     true, :^, nil
    assert_send_type "(false) -> true",
                     true, :^, false
    assert_send_type "(untyped) -> false",
                     true, :^, Object.new
  end

  def test_inspect
    assert_send_type "() -> 'true'",
                     true, :inspect
  end

  def test_to_s
    assert_send_type "() -> 'true'",
                     true, :to_s
  end

  def test_or
    assert_send_type "(true) -> true",
                     true, :|, true
    assert_send_type "(nil) -> true",
                     true, :|, nil
    assert_send_type "(false) -> true",
                     true, :|, false
    assert_send_type "(untyped) -> true",
                     true, :|, Object.new
  end
end

require_relative "../test_helper"

class EnumeratorArithmeticSequenceInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Enumerator::ArithmeticSequence"

  def test_begin
    assert_send_type "() -> Integer", 1.step(2), :begin
    assert_send_type "() -> nil", (..3).step(1), :begin
  end

  def test_end
    assert_send_type "() -> Integer", 1.step(2), :end
    assert_send_type "() -> nil", (1..).step(1), :end
  end

  def test_each
    assert_send_type "() -> Enumerator::ArithmeticSequence", 1.step(2), :each
    assert_send_type "() { (Integer) -> void } -> Enumerator::ArithmeticSequence", 1.step(2), :each do |i| end
    assert_send_type "() { (Float) -> void } -> Enumerator::ArithmeticSequence", 1.0.step(2), :each do |i| end
    assert_send_type "() { (Float) -> void } -> Enumerator::ArithmeticSequence", 1.step(2.0), :each do |i| end
    assert_send_type "() { (Float) -> void } -> Enumerator::ArithmeticSequence", 1.step(2, 1.0), :each do |i| end
  end

  def test_exclude_end?
    assert_send_type "() -> bool", 1.step(2), :exclude_end?
  end

  def test_first
    assert_send_type "() -> Integer", 1.step(2), :first
  end

  def test_last
    assert_send_type "() -> Integer", 1.step(2), :last
  end

  def test_size
    assert_send_type "() -> Integer", 1.step(2), :size
  end

  def test_step
    assert_send_type "() -> Integer", 1.step(2), :step
  end
end

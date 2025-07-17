require_relative "test_helper"

class NumericInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Numeric'

  def test_step
    assert_send_type '() -> Enumerator::ArithmeticSequence',
                     1, :step
    assert_send_type '() { (Integer) -> void } -> Integer',
                     1, :step do |i| break_from_block i end
    assert_send_type '(Float) -> Enumerator::ArithmeticSequence',
                     1, :step, 1.5
    assert_send_type '(Float) { (Float) -> void } -> Integer',
                     1, :step, 1.5 do |i| break_from_block i end
    assert_send_type '(Integer, Float) -> Enumerator::ArithmeticSequence',
                     1r, :step, 2, 0.2
    assert_send_type '(Integer, Float) { (Float) -> void } -> Rational',
                     1r, :step, 2, 0.2 do |i| end
    assert_send_type '(to: Rational) -> Enumerator::ArithmeticSequence',
                     1, :step, to: 2r
    assert_send_type '(to: Rational) { (Integer) -> void } -> Integer',
                     1, :step, to: 2r do |i| end
    assert_send_type '(by: Float) -> Enumerator::ArithmeticSequence',
                     1, :step, by: 0.2
    assert_send_type '(by: Float) { (Float) -> void } -> Rational',
                     1, :step, by: 0.2 do |i| break_from_block i end
    assert_send_type '(to: Rational, by: Float) -> Enumerator::ArithmeticSequence',
                     1, :step, to: 3r, by: 0.2
    assert_send_type '(to: Rational, by: Float) { (Float) -> void } -> Rational',
                     1, :step, to: 3r, by: 0.2 do |i| break_from_block i end
   end
end

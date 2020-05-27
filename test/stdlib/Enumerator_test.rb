require_relative "test_helper"
require "rbs/test/test_helper"

class EnumeratorYielderTest < Minitest::Test
  include RBS::Test::TypeAssertions

  testing "::Enumerator::Yielder"

  def test_ltlt
    Enumerator.new do |y|
      assert_send_type "(untyped) -> void",
                       y, :<<, 1
    end.next
  end

  def test_yield
    Enumerator.new do |y|
      assert_send_type "() -> void",
                       y, :yield
    end.next

    Enumerator.new do |y|
      assert_send_type "(untyped) -> void",
                       y, :yield, 1
    end.next

    Enumerator.new do |y|
      assert_send_type "(untyped, untyped) -> void",
                       y, :yield, 1, 2
    end.next
  end

  def test_to_proc
    Enumerator.new do |y|
      assert_send_type "() -> Proc",
                       y, :to_proc
      y << 42 # To avoid StopIteration error
    end.next
  end
end

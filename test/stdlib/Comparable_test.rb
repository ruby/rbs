require_relative "test_helper"

class ComparableTest < Test::Unit::TestCase
  include TestHelper

  class ComparableWithZero
    def initialize(value) = @value = value
    def <(zero) = @value < zero
    def >(zero) = @value > zero
  end

  class Test
    include Comparable

    def <=>(other)
      ComparableWithZero.new rand(2) - 1
    end
  end

  def obj
    @obj ||= Test.new
  end

  def test_operators
    testing "::Comparable" do
      assert_send_type "(::ComparableTest::Test) -> bool", obj, :<, obj
      assert_send_type "(::ComparableTest::Test) -> bool", obj, :<=, obj
      assert_send_type "(::ComparableTest::Test) -> bool", obj, :>, obj
      assert_send_type "(::ComparableTest::Test) -> bool", obj, :>=, obj
      assert_send_type "(::ComparableTest::Test) -> bool", obj, :==, obj
    end
  end

  def test_between?
    testing "::Comparable" do
      assert_send_type "(::ComparableTest::Test, ::ComparableTest::Test) -> bool", obj, :between?, obj, obj
    end
  end

  def test_clamp
    testing "::Comparable" do
      assert_send_type "(::ComparableTest::Test, ::ComparableTest::Test) -> ::ComparableTest::Test",
                       obj, :clamp, obj, obj
      assert_send_type "(::Range[::Integer]) -> (::ComparableTest::Test | ::Integer)",
                       obj, :clamp, 1..3
    end
  end
end

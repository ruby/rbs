require_relative "test_helper"
require "delegate"

class DelegatorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "delegate"
  testing "::Delegator[::String]"

  def test_get_obj
    assert_send_type "() -> String",
      string_delegator, :__getobj__
  end

  def test_delegate_method
    assert_send_type "(String) -> String",
      string_delegator, :<<, " world"
  end

  def test_Delegate_class
    assert_send_type '(singleton(Integer)) -> singleton(Delegator)',
      Kernel, :DelegateClass, Integer
  end

  private

  def string_delegator
    Class.new(Delegator) do
      def initialize
        super("hello")
      end

      def __getobj__
        @obj
      end

      def __setobj__(obj)
        @obj = obj
      end
    end.new
  end
end

class SimpleDelegatorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "delegate"
  testing "::SimpleDelegator[::String]"

  def test_get_obj
    assert_send_type "() -> String",
      string_delegator, :__getobj__
  end

  def test_delegate_method
    assert_send_type "(String) -> String",
      string_delegator, :<<, " world"
  end

  private

  def string_delegator
    Class.new(SimpleDelegator) do
      def initialize
        super("hello")
      end
    end.new
  end
end

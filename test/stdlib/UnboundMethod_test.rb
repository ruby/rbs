require_relative "test_helper"

class UnboundMethodTest < Test::Unit::TestCase
  include TypeAssertions
  testing "::UnboundMethod"

  class TestClass
    def m(a, m = 1, *rest, x, k: 1, **kwrest, &blk)
    end

    # to_s has super method
    def to_s
      ''
    end
  end

  def test_arity
    assert_send_type "() -> Integer",
                     unbound_method, :arity
  end

  def test_bind
    assert_send_type "(Object) -> Method",
                     unbound_method, :bind, 42
  end

  def test_name
    assert_send_type "() -> Symbol",
                     unbound_method, :name
  end

  def test_owner
    assert_send_type "() -> Module",
                     unbound_method, :owner
  end

  def test_parameters
    assert_send_type "() -> Array[[ Symbol ]]",
                     unbound_method, :parameters
    assert_send_type "() -> Array[[ Symbol, Symbol ]]",
                     TestClass.instance_method(:m), :parameters
  end

  def test_public?
    if_ruby31 do
      assert_send_type(
        "() -> bool",
        unbound_method, :public?
      )
    end
  end

  def test_private?
    if_ruby31 do
      assert_send_type(
        "() -> bool",
        unbound_method, :private?
      )
    end
  end

  def test_protected?
    if_ruby31 do
      assert_send_type(
        "() -> bool",
        unbound_method, :protected?
      )
    end
  end

  def test_source_location
    assert_send_type "() -> nil",
                     unbound_method, :source_location
    assert_send_type "() -> [ String, Integer ]",
                     TestClass.instance_method(:m), :source_location
  end

  def test_super_method
    assert_send_type "() -> nil",
                     TestClass.instance_method(:m), :super_method
    assert_send_type "() -> UnboundMethod",
                     TestClass.instance_method(:to_s), :super_method
  end

  def test_original_name
    assert_send_type "() -> Symbol",
                     unbound_method, :original_name
  end

  def test_bind_call
    assert_send_type "(Integer) -> String",
                     unbound_method, :bind_call, 42
    assert_send_type "(Integer, Integer) -> String",
                     unbound_method, :bind_call, 42, 16
    assert_send_type "(UnboundMethodTest::TestClass, Integer, Integer, foo: String) { () -> void } -> nil",
                     TestClass.instance_method(:m), :bind_call, TestClass.new, 42, 43, foo: 'bar' do end
  end

  def unbound_method
    Integer.instance_method(:to_s)
  end
end

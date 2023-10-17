require_relative "test_helper"

class EnumeratorTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Enumerator[::Integer, Array[::Integer]]"

  def test_map
    g = [1,2,3].to_enum
    assert_send_type "() { (Integer) -> String } -> Array[String]",
                     g, :map do |x| x.to_s end
    assert_send_type "() -> Enumerator[Integer, Array[untyped]]",
                     g, :map
  end

  def test_with_object
    g = [1,2,3].to_enum
    assert_send_type "(String) -> Enumerator[[Integer, String], String]", g, :with_object, ''
    assert_send_type "(String) { (Integer, String) -> untyped } -> String", g, :with_object, '' do end
  end
end

class EnumeratorSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Enumerator)"

  def test_produce
    assert_send_type(
      "(Integer initial) { (Integer) -> Integer } -> Enumerator[Integer, bot]",
      Enumerator, :produce, 1, &:succ
    )
  end

  def test_product
    assert_send_type(
      "(Array[String], Array[Integer]) -> Enumerator::Product[String | Integer]",
      Enumerator, :product, ["a", "b"], [1, 2]
    )
  end
end

class EnumeratorYielderTest < Test::Unit::TestCase
  include TypeAssertions

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

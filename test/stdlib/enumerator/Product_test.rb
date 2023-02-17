require_relative "../test_helper"

class EnumeratorProductInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Enumerator::Product[::Integer | ::String]"

  def test_each
    product = Enumerator::Product.new([1,2,3], ["a", "b", "c"])

    assert_send_type(
      "() { (Array[Integer | String]) -> void } -> Enumerator::Product[Integer | String]",
      product, :each, &-> (_) { }
    )
  end

  def test_rewind
    product = Enumerator::Product.new([1,2,3], ["a", "b", "c"])

    assert_send_type(
      "() -> Enumerator::Product[Integer | String]",
      product, :rewind
    )
  end

  def test_size
    product = Enumerator::Product.new([1,2,3], ["a", "b", "c"])

    assert_send_type(
      "() -> Integer",
      product, :size
    )
  end
end

class EnumeratorProductSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Enumerator::Product)"

  def test_new
    assert_send_type(
      "() -> Enumerator::Product[untyped]",
      Enumerator::Product, :new
    )

    assert_send_type(
      "(Array[Integer]) -> Enumerator::Product[Integer]",
      Enumerator::Product, :new, [1,2,3]
    )
  end
end

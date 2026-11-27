require_relative "test_helper"

class SetTest < Test::Unit::TestCase
  include TestHelper

  testing "::Set[::Integer]"

  def test_each
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[1], :each
    )

    assert_send_type(
      "() { (::Integer) -> ::Integer } -> ::Set[::Integer]",
      Set[1], :each
    ) do |x| x+1 end
  end

  def test_compare_by_identity
    assert_send_type(
      "() -> ::Set[::Integer]",
      Set[1], :compare_by_identity
    )
  end

  def test_classify
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Hash[untyped, ::Set[::Integer]]]",
      Set[1, 2], :classify
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Hash[bool, ::Set[::Integer]]",
      Set[1, 2], :classify
    ) do |x| x.odd? end
  end

  def test_collect!
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[], :collect!
    )
    assert_send_type(
      "() { (::Integer) -> ::Integer } -> ::Set[::Integer]",
      Set[1, 2], :collect!
    ) do |x| x + 1 end
  end

  def test_map!
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[], :map!
    )
    assert_send_type(
      "() { (::Integer) -> ::Integer } -> ::Set[::Integer]",
      Set[1, 2], :map!
    ) do |x| x + 1 end
  end

  def test_delete_if
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[1, 2], :delete_if
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Integer]",
      Set[1, 2], :delete_if
    ) do |x| x.odd? end
  end

  def test_reject!
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]?]",
      Set[1, 2], :reject!
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Integer]",
      Set[1, 2], :reject!
    ) do |x| x.odd? end
    assert_send_type(
      "() { (::Integer) -> bool } -> nil",
      Set[1, 2], :reject!
    ) do |x| false end
  end

  def test_divide
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Set[::Integer]]]",
      Set[1, 2], :divide
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Set[::Integer]]",
      Set[1, 2], :divide
    ) do |x| x.odd? end
  end

  def test_keep_if
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[1, 2], :keep_if
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Integer]",
      Set[1, 2], :keep_if
    ) do |x| x.odd? end
  end

  def test_select!
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]?]",
      Set[1, 2], :select!
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Integer]",
      Set[1, 2], :select!
    ) do |x| x.odd? end
    assert_send_type(
      "() { (::Integer) -> bool } -> nil",
      Set[1, 2], :select!
    ) do |x| true end
  end

  def test_filter!
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]?]",
      Set[1, 2], :filter!
    )
    assert_send_type(
      "() { (::Integer) -> bool } -> ::Set[::Integer]",
      Set[1, 2], :filter!
    ) do |x| x.odd? end
  end
end

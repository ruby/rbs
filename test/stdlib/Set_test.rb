require_relative "test_helper"

class SetTest < Test::Unit::TestCase
  include TypeAssertions

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
end

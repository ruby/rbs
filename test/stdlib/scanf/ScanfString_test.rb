require_relative "../test_helper"
require "scanf"

class ScanfStringInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "scanf"
  testing "::String"

  def test_scanf
    assert_send_type "(String str) -> Array", "foo", :scanf, "%d"
    assert_send_type(
      "(String str) ?{ (top) -> top } -> Array[top]", "2", :scanf, "%d"
    ) { |num| num }
  end
end

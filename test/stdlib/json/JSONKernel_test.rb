require_relative "../test_helper"
require "json"

class JSONKernelInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Kernel"

  def test_JSON
    assert_send_type("(String) -> Hash[String, Integer]", self, :JSON, '{"a": 1}')
    assert_send_type("(Array[Integer]) -> String", self, :JSON, [1, 2, 3])
  end
end

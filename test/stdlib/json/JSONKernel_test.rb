require_relative "../test_helper"
require "json"

class JSONKernelInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Kernel"

  def silent
    orig_stdout = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = orig_stdout
  end

  def test_j
    silent do
      assert_send_type("(Integer) -> nil", self, :j, 1)
      assert_send_type("(Array[Integer]) -> nil", self, :j, [1, 2, 3])
    end
  end

  def test_jj
    silent do
      assert_send_type("(Integer) -> nil", self, :jj, 1)
      assert_send_type("(Array[Integer]) -> nil", self, :jj, [1, 2, 3])
    end
  end

  def test_JSON
    assert_send_type("(String) -> Hash[String, Integer]", self, :JSON, '{"a": 1}')
    assert_send_type("(Array[Integer]) -> String", self, :JSON, [1, 2, 3])
  end
end

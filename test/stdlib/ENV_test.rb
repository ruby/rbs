require_relative "test_helper"

# initialize temporary class
class ENVClass
end

class ENVTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::ENVClass"

  def test_get
    assert_send_type "(String) -> String?",
                     ENV, :[], "HOME"
  end

  def test_set
    assert_send_type "(String, String?) -> String?",
                     ENV, :[]=, "ENVTest", "Case"
    assert_send_type "(String, String?) -> String?",
                     ENV, :[]=, "ENVTest", nil
  end

  def test_fetch
    assert_send_type "(String name, Symbol default) -> Symbol",
                     ENV, :fetch, "ENVTest", :default
  end
end

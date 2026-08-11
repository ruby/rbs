require_relative "../test_helper"
require "json"

class JSONDateInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Date"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer | Float]",
                     Date.today, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Date.today, :to_json
    assert_send_type "(nil) -> String",
                     Date.today, :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     Date.today, :to_json, JSON::State.new
  end
end

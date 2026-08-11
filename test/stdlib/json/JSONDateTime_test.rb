require_relative "../test_helper"
require "json"

class JSONDateTimeInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::DateTime"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer | Float]",
                     DateTime.now, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     DateTime.now, :to_json
    assert_send_type "(nil) -> String",
                     DateTime.now, :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     DateTime.now, :to_json, JSON::State.new
  end
end

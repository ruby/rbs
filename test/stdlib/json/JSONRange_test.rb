require_relative "../test_helper"
require "json"

class JSONRangeInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Range[Integer]"

  def test_as_json
    assert_send_type "() -> Hash[String, String | [Integer, Integer, bool]]",
                     (0..9), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     (0..9), :to_json
    assert_send_type "(nil) -> String",
                     (0..9), :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     (0..9), :to_json, JSON::State.new
  end
end

require_relative "../test_helper"
require "json"
require "json/add/range"

class JSONRangeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Range)"

  def test_json_create
    assert_send_type "(Hash[String, String | [Integer, Integer, bool]]) -> Range[Integer]",
                     Range, :json_create, (0..9).as_json
  end
end

class JSONRangeInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Range[Integer]"

  def test_as_json
    assert_send_type "() -> Hash[String, String | [Integer, Integer, bool]]",
                     (0..9), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     (0..9), :to_json
    assert_send_type "(JSON::State) -> String",
                     (0..9), :to_json, JSON::State.new
  end
end

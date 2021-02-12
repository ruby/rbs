require_relative "../test_helper"
require "json"
require "json/add/time"

class JSONTimeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Time)"

  def test_json_create
    assert_send_type "(Hash[String, String | Integer]) -> Time",
                     Time, :json_create, Time.now.as_json
  end
end

class JSONTimeInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Time"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer]",
                     Time.now, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Time.now, :to_json
    assert_send_type "(JSON::State) -> String",
                     Time.now, :to_json, JSON::State.new
  end
end

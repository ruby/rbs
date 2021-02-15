require_relative "../test_helper"
require "json"
require "json/add/date_time"

class JSONDateTimeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::DateTime)"

  def test_json_create
    assert_send_type "(Hash[String, String | Integer | Float]) -> DateTime",
                     DateTime, :json_create, DateTime.now.as_json
  end
end

class JSONDateTimeInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::DateTime"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer | Float]",
                     DateTime.now, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     DateTime.now, :to_json
    assert_send_type "(JSON::State) -> String",
                     DateTime.now, :to_json, JSON::State.new
  end
end

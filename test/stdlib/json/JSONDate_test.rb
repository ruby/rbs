require_relative "../test_helper"
require "json"
require "json/add/date"

class JSONDateSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Date)"

  def test_json_create
    assert_send_type "(Hash[String, String | Integer | Float]) -> Date",
                     Date, :json_create, Date.today.as_json
  end
end

class JSONDateInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Date"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer | Float]",
                     Date.today, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Date.today, :to_json
    assert_send_type "(JSON::State) -> String",
                     Date.today, :to_json, JSON::State.new
  end
end

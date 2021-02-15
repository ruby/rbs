require_relative "../test_helper"
require "json"
require "json/add/bigdecimal"

class JSONBigDecimalSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::BigDecimal)"

  def test_json_create
    assert_send_type "(Hash[String, String]) -> BigDecimal",
                     BigDecimal, :json_create, BigDecimal("0").as_json
  end
end

class JSONBigDecimalInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::BigDecimal"

  def test_as_json
    assert_send_type "() -> Hash[String, String]",
                     BigDecimal("0"), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     BigDecimal("0"), :to_json
    assert_send_type "(JSON::State) -> String",
                     BigDecimal("0"), :to_json, JSON::State.new
  end
end

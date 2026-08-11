require_relative "../test_helper"
require "json"

class JSONBigDecimalInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::BigDecimal"

  def test_as_json
    assert_send_type "() -> Hash[String, String]",
                     BigDecimal("0"), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     BigDecimal("0"), :to_json
    assert_send_type "(nil) -> String",
                     BigDecimal("0"), :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     BigDecimal("0"), :to_json, JSON::State.new
  end
end

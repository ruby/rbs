require_relative "../test_helper"
require "json"

class JSONRationalInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Rational"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer]",
                     Rational(1, 3), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Rational(1, 3), :to_json
    assert_send_type "(nil) -> String",
                     Rational(1, 3), :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     Rational(1, 3), :to_json, JSON::State.new
  end
end

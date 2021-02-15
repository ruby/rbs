require_relative "../test_helper"
require "json"
require "json/add/rational"

class JSONRationalSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Rational)"

  def test_json_create
    assert_send_type "(Hash[String, String | Integer]) -> Rational",
                     Rational, :json_create, Rational(1, 3).as_json
  end
end

class JSONRationalInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Rational"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer]",
                     Rational(1, 3), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Rational(1, 3), :to_json
    assert_send_type "(JSON::State) -> String",
                     Rational(1, 3), :to_json, JSON::State.new
  end
end

require_relative "../test_helper"
require "json"
require "json/add/complex"

class JSONComplexSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Complex)"

  def test_json_create
    assert_send_type "(Hash[String, String | Numeric]) -> Complex",
                     Complex, :json_create, Complex(0).as_json
  end
end

class JSONComplexInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Complex"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Numeric]",
                     Complex(0), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Complex(0), :to_json
    assert_send_type "(JSON::State) -> String",
                     Complex(0), :to_json, JSON::State.new
  end
end

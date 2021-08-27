require_relative "../test_helper"
require "json"
require "json/add/symbol"

class JSONSymbolSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Symbol)"

  def test_json_create
    assert_send_type "(Hash[String, String]) -> Symbol",
                     Symbol, :json_create, :foo.as_json
  end
end

class JSONSymbolInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Symbol"

  def test_as_json
    assert_send_type "() -> Hash[String, String]",
                     :foo, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     :foo, :to_json
    assert_send_type "(JSON::State) -> String",
                     :foo, :to_json, JSON::State.new
  end
end

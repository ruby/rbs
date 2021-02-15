require_relative "../test_helper"
require "json"
require "json/add/set"

class JSONSetSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Set)"

  def test_json_create
    assert_send_type "(Hash[String, String | Array[Integer]]) -> Set[Integer]",
                     Set, :json_create, Set[1, 2].as_json
  end
end

class JSONSetInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Set[Integer]"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Array[Integer]]",
                     Set[1, 2], :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Set[1, 2], :to_json
    assert_send_type "(JSON::State) -> String",
                     Set[1, 2], :to_json, JSON::State.new
  end
end

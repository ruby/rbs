require_relative "../test_helper"
require "json"
require "json/add/ostruct"

class JSONOpenStructSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::OpenStruct)"

  def test_json_create
    assert_send_type "(Hash[String, String | Hash[Symbol, untyped]]) -> OpenStruct",
                     OpenStruct, :json_create, OpenStruct.new("foo" => 1).as_json
  end
end

class JSONOpenStructInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::OpenStruct"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Hash[Symbol, untyped]]",
                     OpenStruct.new("foo" => 1), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     OpenStruct.new, :to_json
    assert_send_type "(JSON::State) -> String",
                     OpenStruct.new, :to_json, JSON::State.new
  end
end

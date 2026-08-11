require_relative "../test_helper"
require "json"

class JSONOpenStructInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::OpenStruct"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Hash[Symbol, untyped]]",
                     OpenStruct.new("foo" => 1), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     OpenStruct.new, :to_json
    assert_send_type "(nil) -> String",
                     OpenStruct.new, :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     OpenStruct.new, :to_json, JSON::State.new
  end
end

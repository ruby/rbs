require_relative "../test_helper"
require "json"

class JSONRegexpInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Regexp"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer]",
                     /foo/, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     /foo/, :to_json
    assert_send_type "(nil) -> String",
                     /foo/, :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     /foo/, :to_json, JSON::State.new
  end
end

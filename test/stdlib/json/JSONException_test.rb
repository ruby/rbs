require_relative "../test_helper"
require "json"

class JSONExceptionInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "::Exception"

  def test_as_json
    assert_send_type "() -> Hash[String, String | nil]",
                     Exception.new("foo"), :as_json
  end

  def test_as_json_with_backtrace
    "foo".unknown
  rescue => exception
    assert_send_type "() -> Hash[String, String | Array[String]]",
                     exception, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Exception.new("foo"), :to_json
    assert_send_type "(nil) -> String",
                     Exception.new("foo"), :to_json, nil
    assert_send_type "(JSON::State) -> String",
                     Exception.new("foo"), :to_json, JSON::State.new
  end
end

require_relative "../test_helper"
require "json"
require "json/add/regexp"

class JSONRegexpSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Regexp)"

  def test_json_create
    assert_send_type "(Hash[String, String | Integer]) -> Regexp",
                     Regexp, :json_create, /foo/.as_json
  end
end

class JSONRegexpInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "::Regexp"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Integer]",
                     /foo/, :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     /foo/, :to_json
    assert_send_type "(JSON::State) -> String",
                     /foo/, :to_json, JSON::State.new
  end
end

require_relative "../test_helper"
require "json"
require "json/add/exception"

class JSONExceptionSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "json"
  testing "singleton(::Exception)"

  def test_json_create
    assert_send_type "(Hash[String, String | nil]) -> Exception",
                     Exception, :json_create, Exception.new("foo").as_json
  end

  def test_json_create_with_backtrace
    "foo".unknown
  rescue => exception
    assert_send_type "(Hash[String, String | Array[String]]) -> Exception",
                     Exception, :json_create, exception.as_json
  end
end

class JSONExceptionInstanceTest < Test::Unit::TestCase
  include TypeAssertions

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
    assert_send_type "(JSON::State) -> String",
                     Exception.new("foo"), :to_json, JSON::State.new
  end
end

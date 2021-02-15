require_relative "../test_helper"
require "json"
require "json/add/struct"

class JSONStructSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  Foo = Struct.new(:a)

  library "json"
  testing "singleton(::Struct)"

  def test_json_create
    assert_send_type "(Hash[String, String | Array[Integer]]) -> Struct[Integer]",
                     Foo, :json_create, Foo.new(1).as_json
  end
end

class JSONStructInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  Foo = Struct.new(:a)

  library "json"
  testing "::Struct[Integer]"

  def test_as_json
    assert_send_type "() -> Hash[String, String | Array[Integer]]",
                     Foo.new(1), :as_json
  end

  def test_to_json
    assert_send_type "() -> String",
                     Foo.new(1), :to_json
    assert_send_type "(JSON::State) -> String",
                     Foo.new(1), :to_json, JSON::State.new
  end
end

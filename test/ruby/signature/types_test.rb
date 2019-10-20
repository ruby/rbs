require "test_helper"

class Ruby::Signature::TypesTest < Minitest::Test
  Types = Ruby::Signature::Types

  include TestHelper

  def test_to_s
    assert_equal "Array[Integer]", parse_type("Array[Integer]").to_s
    assert_equal "Array[Integer]?", parse_type("Array[Integer]?").to_s
    assert_equal "[ Integer, bool? ]", parse_type("[Integer, bool?]").to_s
    assert_equal "String | bool?", parse_type("String | bool?").to_s
    assert_equal "(String | bool)?", parse_type("(String | bool)?").to_s
    assert_equal "String & bool?", parse_type("String & bool?").to_s
    assert_equal "(String & bool)?", parse_type("(String & bool)?").to_s
    assert_equal "Integer | String & bool", parse_type("Integer | String & bool").to_s
    assert_equal "(Integer | String) & bool", parse_type("(Integer | String) & bool").to_s
    assert_equal "(Integer | String & bool)?", parse_type("(Integer | String & bool)?").to_s
    assert_equal "((Integer | String) & bool)?", parse_type("((Integer | String) & bool)?").to_s
    assert_equal "^() -> void", parse_type("^() -> void").to_s
    assert_equal "^(bool flag, ?untyped, *Symbol, name: String, ?email: nil, **Symbol) -> void", parse_type("^(bool flag, ?untyped, *Symbol, name: String, ?email: nil, **Symbol) -> void").to_s
  end
end

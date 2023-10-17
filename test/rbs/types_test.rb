require "test_helper"

class RBS::TypesTest < Test::Unit::TestCase
  Types = RBS::Types

  include TestHelper

  def test_to_s
    assert_equal "Array[Integer]", parse_type("Array[Integer]").to_s
    assert_equal "Array[Integer]?", parse_type("Array[Integer]?").to_s
    assert_equal '"foo"?', parse_type('"foo" ?').to_s
    assert_equal '"foo\\\\n"', parse_type(%q{'foo\n'}).to_s
    assert_equal '"foo\\n"', parse_type('"foo\n"').to_s
    assert_equal ":foo ?", parse_type(":foo ?").to_s
    assert_equal "[ Integer, bool? ]", parse_type("[Integer, bool?]").to_s
    assert_equal "[ ]", parse_type("[   ]").to_s
    assert_equal "{ }", Types::Record.new(fields: {}, location: nil).to_s # NOTE: parse_type("{ }") is syntax error
    assert_equal "{ a: 1 }", parse_type("{ a: 1 }").to_s
    assert_equal "{ :+ => 1 }", parse_type("{ :+ => 1 }").to_s
    assert_equal '{ a: 1, 1 => 42, "foo" => untyped }', parse_type("{ a: 1, 1 => 42, 'foo' => untyped }").to_s
    assert_equal '{ type: untyped }', parse_type("{ :type => untyped }").to_s
    assert_equal "String | bool?", parse_type("String | bool?").to_s
    assert_equal "(String | bool)?", parse_type("(String | bool)?").to_s
    assert_equal "String & bool?", parse_type("String & bool?").to_s
    assert_equal "(String & bool)?", parse_type("(String & bool)?").to_s
    assert_equal "Integer | String & bool", parse_type("Integer | String & bool").to_s
    assert_equal "(Integer | String) & bool", parse_type("(Integer | String) & bool").to_s
    assert_equal "(Integer | String & bool)?", parse_type("(Integer | String & bool)?").to_s
    assert_equal "((Integer | String) & bool)?", parse_type("((Integer | String) & bool)?").to_s
    assert_equal "^() -> void", parse_type("^() -> void").to_s
    assert_equal "(^() -> void)?", parse_type("(^() -> void)?").to_s
    assert_equal "^(bool flag, ?untyped, *Symbol, name: String, ?email: nil, **Symbol) -> void", parse_type("^(bool flag, ?untyped, *Symbol, name: String, ?email: nil, **Symbol) -> void").to_s
    assert_equal "^(untyped untyped, untyped footype) -> void", parse_type("^(untyped `untyped`, untyped footype) -> void").to_s
  end

  def test_has_self_type?
    [
      "self",
      "[self]",
      "Array[self]",
      "^(self) -> void",
      "^() { () [self: self] -> void } -> void"
    ].each do |str|
      type = parse_type(str)
      assert_predicate type, :has_self_type?
    end

    [
      "Integer",
      "^() { () [self: untyped] -> void } -> void"
    ].each do |str|
      type = parse_type(str)
      refute_predicate type, :has_self_type?
    end
  end

  def test_has_classish_type?
    [
      "instance",
      "class",
      "class?",
      "^() -> instance",
      "^() { () [self: class] -> void } -> void"
    ].each do |str|
      type = parse_type(str)
      assert_predicate type, :has_classish_type?
    end

    [
      "Integer",
      "^() { () [self: untyped] -> void } -> void"
    ].each do |str|
      type = parse_type(str)
      refute_predicate type, :has_classish_type?
    end
  end

  def test_with_nonreturn_void?
    [
      "void",
      "[void]",
      "void?"
    ].each do |str|
      type = parse_type(str)
      assert_predicate type, :with_nonreturn_void?
    end

    [
      "^() -> void",
      "[Ineger, String]",
      "Enumerator[Integer, void]"
    ].each do |str|
      type = parse_type(str)
      refute_predicate type, :with_nonreturn_void?
    end
  end
end

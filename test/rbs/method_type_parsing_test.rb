require "test_helper"

class RBS::MethodTypeParsingTest < Test::Unit::TestCase
  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace

  def test_method_type
    Parser.parse_method_type("()->void").yield_self do |type|
      assert_equal "() -> void", type.to_s
    end

    Parser.parse_method_type("(foo?: Integer, bar!: String)->void")
    Parser.parse_method_type("(?foo?: Integer, ?bar!: String)->void")
  end

  def test_method_type_eof_re
    Parser.parse_method_type("()->void~ Integer", eof_re: /~/).yield_self do |type|
      assert_equal "() -> void", type.to_s
    end
  end

  def test_method_type_eof_re_error
    # `eof_re` has higher priority than other token.
    # Specifying type token may result in a SyntaxError
    error = assert_raises Parser::SyntaxError do
      Parser.parse_method_type("()-> { foo: bar } }", eof_re: /}/).yield_self do |type|
        assert_equal "() -> void", type.to_s
      end
    end

    assert_equal "}", error.error_value
  end
end

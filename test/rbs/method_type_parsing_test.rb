require "test_helper"

class RBS::MethodTypeParsingTest < Test::Unit::TestCase
  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  Location = RBS::Location

  def test_method_type
    Parser.parse_method_type("()->void").yield_self do |type|
      assert_equal "() -> void", type.to_s
    end

    Parser.parse_method_type("(foo?: Integer, bar!: String)->void")
    Parser.parse_method_type("(?foo?: Integer, ?bar!: String)->void")
  end

  def test_method_param
    Parser.parse_method_type("(untyped _)->void").yield_self do |type|
      assert_equal "(untyped _) -> void", type.to_s
    end
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

  def test_method_parameter_location
    Parser.parse_method_type("(untyped a, ?Integer b, *String c, Symbol d) -> void").tap do |type|
      type.type.required_positionals[0].tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "a", param.location[:name].source
      end

      type.type.optional_positionals[0].tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "b", param.location[:name].source
      end

      type.type.rest_positionals.tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "c", param.location[:name].source
      end

      type.type.trailing_positionals[0].tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "d", param.location[:name].source
      end
    end

    Parser.parse_method_type("(a: untyped a, ?b: Integer b, **String c) -> void").tap do |type|
      type.type.required_keywords[:a].tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "a", param.location[:name].source
      end

      type.type.optional_keywords[:b].tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "b", param.location[:name].source
      end

      type.type.rest_keywords.tap do |param|
        assert_instance_of Location::WithChildren, param.location
        assert_equal "c", param.location[:name].source
      end
    end
  end
end

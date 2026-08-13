require "test_helper"

class RBS::MethodTypeParsingTest < Test::Unit::TestCase
  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  Location = RBS::Location

  def parse_type(string)
    buffer = Buffer.new(content: string.encode(Encoding::UTF_8), name: "sample.rbs")
    RBS::Parser.parse_type(buffer)
  end

  def parse_method_type(string)
    buffer = Buffer.new(content: string.encode(Encoding::UTF_8), name: "sample.rbs")
    RBS::Parser.parse_method_type(buffer)
  end

  def parse_signature(string)
    buffer = Buffer.new(content: string.encode(Encoding::UTF_8), name: "sample.rbs")
    RBS::Parser.parse_signature(buffer)
  end

  def test_method_type
    Parser.parse_method_type("()->void").yield_self do |type|
      assert_equal "() -> void", type.to_s
    end

    Parser.parse_method_type("(foo?: Integer, bar!: String)->void")
    Parser.parse_method_type("(?foo?: Integer, ?bar!: String)->void")
  end

  def test_method_type__void_in_paren
    Parser.parse_method_type("() -> (void)").tap do |type|
      assert_instance_of Types::Bases::Void, type.type.return_type
    end
  end

  def test_method_param
    Parser.parse_method_type("(untyped _, top __, Object _2, String _abc_123)->void").yield_self do |type|
      assert_equal "(untyped _, top __, Object _2, String _abc_123) -> void", type.to_s
    end

    Parser.parse_method_type("(untyped _)->void").yield_self do |type|
      assert_equal "(untyped _) -> void", type.to_s
    end
  end

  def test_forwarding_parameter_syntax_is_not_enabled
    # `(...)` forwarding parameters are gated behind a C-level parser option
    # (`rbs_parser_options_t`) that the Ruby API doesn't expose, so parsing
    # them from Ruby is always an error.
    error = assert_raise(RBS::ParsingError) do
      parse_method_type("(...) -> void")
    end
    assert_include error.message, "forwarding parameter syntax is not enabled"

    assert_raise(RBS::ParsingError) do
      parse_method_type("(String message, ...) -> void")
    end
  end

  def test_forwarding_parameter_syntax_is_not_enabled_in_signature
    assert_raise(RBS::ParsingError) do
      parse_signature(<<~RBS)
        class Foo
          def foo: (...) -> void
                 | ...
        end
      RBS
    end
  end

  def test_forwarding_parameter_rejects_nonleading_parameters
    [
      "(?String value, ...) -> void",
      "(*String values, ...) -> void",
      "(value: String, ...) -> void",
      "(?value: String, ...) -> void",
      "(**String values, ...) -> void",
    ].each do |source|
      assert_raise(RBS::ParsingError) do
        parse_method_type(source)
      end
    end
  end

  def test_forwarding_parameter_must_be_last
    [
      "(..., String) -> void",
      "(..., ...) -> void",
      "(...,) -> void",
    ].each do |source|
      assert_raise(RBS::ParsingError) do
        parse_method_type(source)
      end
    end
  end

  def test_forwarding_parameter_cannot_have_explicit_block
    [
      "(...) { () -> void } -> void",
      "(...) ?{ () -> void } -> void",
    ].each do |source|
      assert_raise(RBS::ParsingError) do
        parse_method_type(source)
      end
    end
  end

  def test_forwarding_parameter_is_not_allowed_in_block_types
    assert_raise(RBS::ParsingError) do
      parse_method_type("() { (...) -> void } -> void")
    end
  end

  def test_forwarding_parameter_is_not_allowed_in_proc_types
    [
      "^(...) -> void",
      "^(String, ...) -> void",
    ].each do |source|
      assert_raise(RBS::ParsingError) do
        parse_type(source)
      end
    end
  end

  def test_method_type_location
    Parser.parse_method_type("(untyped _)->void").yield_self do |type|
      assert_nil type.location[:type_params]
      assert_equal "(untyped _)->void", type.location[:type].source
    end

    Parser.parse_method_type("[A < _Foo[String]] (A) { (String) -> void } -> void").yield_self do |type|
      assert_equal "[A < _Foo[String]]", type.location[:type_params].source
      assert_equal "(A) { (String) -> void } -> void", type.location[:type].source
    end
  end

  def test_method_parameter_location
    Parser.parse_method_type("(untyped a, ?Integer b, *String c, Symbol d) -> void").tap do |type|
      type.type.required_positionals[0].tap do |param|
        assert_instance_of Location, param.location
        assert_equal "a", param.location[:name].source
      end

      type.type.optional_positionals[0].tap do |param|
        assert_instance_of Location, param.location
        assert_equal "b", param.location[:name].source
      end

      type.type.rest_positionals.tap do |param|
        assert_instance_of Location, param.location
        assert_equal "c", param.location[:name].source
      end

      type.type.trailing_positionals[0].tap do |param|
        assert_instance_of Location, param.location
        assert_equal "d", param.location[:name].source
      end
    end

    Parser.parse_method_type("(a: untyped a, ?b: Integer b, **String c) -> void").tap do |type|
      type.type.required_keywords[:a].tap do |param|
        assert_instance_of Location, param.location
        assert_equal "a", param.location[:name].source
      end

      type.type.optional_keywords[:b].tap do |param|
        assert_instance_of Location, param.location
        assert_equal "b", param.location[:name].source
      end

      type.type.rest_keywords.tap do |param|
        assert_instance_of Location, param.location
        assert_equal "c", param.location[:name].source
      end
    end
  end
end

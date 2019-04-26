require "test_helper"

class Ruby::Signature::MethodTypeParsingTest < Minitest::Test
  Parser = Ruby::Signature::Parser
  Buffer = Ruby::Signature::Buffer
  Types = Ruby::Signature::Types
  TypeName = Ruby::Signature::TypeName
  Namespace = Ruby::Signature::Namespace

  def test_method_type
    Parser.parse_method_type("()->void").yield_self do |type|
      assert_equal "() -> void", type.to_s
    end
  end
end

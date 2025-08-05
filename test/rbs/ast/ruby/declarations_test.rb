require "test_helper"

class RBS::AST::Ruby::DeclarationsTest < Test::Unit::TestCase
  include TestHelper

  include RBS::AST::Ruby

  def parse_ruby(source)
    buffer = RBS::Buffer.new(name: Pathname("a.rb"), content: source)
    [buffer, Prism.parse(source)]
  end

  def test_constant_decl__literal_type_integer
    buffer, result = parse_ruby("FOO = 42")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :FOO, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :FOO, decl.constant_name.name
    assert_equal "::Integer", decl.type.to_s
    assert_nil decl.type_annotation
  end

  def test_constant_decl__literal_type_float
    buffer, result = parse_ruby("PI = 3.14")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :PI, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :PI, decl.constant_name.name
    assert_equal "::Float", decl.type.to_s
  end

  def test_constant_decl__literal_type_string
    buffer, result = parse_ruby('NAME = "test"')
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :NAME, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :NAME, decl.constant_name.name
    assert_equal "::String", decl.type.to_s
  end

  def test_constant_decl__literal_type_boolean
    buffer, result = parse_ruby("ENABLED = true")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :ENABLED, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :ENABLED, decl.constant_name.name
    assert_equal "bool", decl.type.to_s
  end

  def test_constant_decl__literal_type_symbol
    buffer, result = parse_ruby("STATUS = :ready")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :STATUS, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :STATUS, decl.constant_name.name
    assert_equal "::Symbol", decl.type.to_s
  end

  def test_constant_decl__literal_type_nil
    buffer, result = parse_ruby("NOTHING = nil")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :NOTHING, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :NOTHING, decl.constant_name.name
    assert_equal "nil", decl.type.to_s
  end

  def test_constant_decl__complex_expression_fallback
    buffer, result = parse_ruby("COMPLEX = [1, 2, 3]")
    constant_node = result.value.statements.body[0]

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :COMPLEX, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      nil
    )

    assert_equal :COMPLEX, decl.constant_name.name
    assert_equal "untyped", decl.type.to_s
  end

  def test_constant_decl__with_explicit_type_annotation
    buffer, result = parse_ruby("ITEMS = []")
    constant_node = result.value.statements.body[0]

    # Create explicit type annotation
    type = RBS::Types::ClassInstance.new(
      name: RBS::TypeName.new(name: :Array, namespace: RBS::Namespace.empty),
      args: [RBS::Types::ClassInstance.new(
        name: RBS::TypeName.new(name: :String, namespace: RBS::Namespace.empty),
        args: [],
        location: nil
      )],
      location: nil
    )
    annotation = Annotations::NodeTypeAssertion.new(
      location: RBS::Location.new(buffer, 0, 10),
      prefix_location: RBS::Location.new(buffer, 0, 4),
      type: type
    )

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :ITEMS, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      annotation
    )

    assert_equal :ITEMS, decl.constant_name.name
    assert_equal "Array[String]", decl.type.to_s
    assert_not_nil decl.type_annotation
  end

  def test_constant_decl__type_annotation_takes_precedence
    buffer, result = parse_ruby("COUNT = 42")
    constant_node = result.value.statements.body[0]

    # Create explicit type annotation that overrides the inferred Integer type
    type = RBS::Types::ClassInstance.new(
      name: RBS::TypeName.new(name: :Float, namespace: RBS::Namespace.empty),
      args: [],
      location: nil
    )
    annotation = Annotations::NodeTypeAssertion.new(
      location: RBS::Location.new(buffer, 0, 10),
      prefix_location: RBS::Location.new(buffer, 0, 4),
      type: type
    )

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :COUNT, namespace: RBS::Namespace.empty),
      constant_node,
      nil,
      annotation
    )

    assert_equal :COUNT, decl.constant_name.name
    assert_equal "Float", decl.type.to_s  # Should use annotation, not infer Integer
  end

  def test_constant_decl__with_leading_comment
    buffer, result = parse_ruby("FOO = 42")
    constant_node = result.value.statements.body[0]

    # Create a leading comment
    leading_comment = CommentBlock.new(buffer, [])

    decl = Declarations::ConstantDecl.new(
      buffer,
      RBS::TypeName.new(name: :FOO, namespace: RBS::Namespace.empty),
      constant_node,
      leading_comment,
      nil
    )

    assert_equal :FOO, decl.constant_name.name
    assert_equal "::Integer", decl.type.to_s
    assert_equal leading_comment, decl.leading_comment
    assert_nil decl.type_annotation
  end
end

require "test_helper"

class RBS::InlineAnnotationParsingTest < Test::Unit::TestCase
  include RBS

  include TestHelper

  def test_parse__trailing_assertion
    Parser.parse_inline_trailing_annotation(": String", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::NodeTypeAssertion, annot
      assert_equal ": String", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "String", annot.type.location.source
    end

    Parser.parse_inline_trailing_annotation(": void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::NodeTypeAssertion, annot
      assert_equal ": void", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "void", annot.type.location.source
    end

    Parser.parse_inline_trailing_annotation(": self | class | instance", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::NodeTypeAssertion, annot
      assert_equal ": self | class | instance", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "self | class | instance", annot.type.location.source
    end
  end

  def test_error__trailing_assertion
    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation(": String[", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation(":", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation(": String is a ", 0...)
    end
  end

  def test_parse__colon_method_type_annotation
    Parser.parse_inline_leading_annotation(": (String) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ColonMethodTypeAnnotation, annot
      assert_equal ": (String) -> void", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "(String) -> void", annot.method_type.location.source
      assert_empty annot.annotations
    end

    Parser.parse_inline_leading_annotation(": %a{a} %a{b} (String) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ColonMethodTypeAnnotation, annot
      assert_equal ": %a{a} %a{b} (String) -> void", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "(String) -> void", annot.method_type.location.source
      assert_equal ["a", "b"], annot.annotations.map(&:string)
    end
  end

  def test_parse__rbs_method_types_annotation
    Parser.parse_inline_leading_annotation("@rbs %a{a} (String) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs %a{a} (String) -> void", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      annot.overloads[0].tap do |overload|
        assert_equal "(String) -> void", overload.method_type.location.source
        assert_equal ["a"], overload.annotations.map(&:string)
      end
      assert_empty annot.vertical_bar_locations
    end

    Parser.parse_inline_leading_annotation("@rbs %a{a} (String) -> void | [T] (T) -> T", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs %a{a} (String) -> void | [T] (T) -> T", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      annot.overloads[0].tap do |overload|
        assert_equal "(String) -> void", overload.method_type.location.source
        assert_equal ["a"], overload.annotations.map(&:string)
      end
      annot.overloads[1].tap do |overload|
        assert_equal "[T] (T) -> T", overload.method_type.location.source
        assert_equal [], overload.annotations.map(&:string)
      end
      assert_equal ["|"], annot.vertical_bar_locations.map(&:source)
    end
  end

  def test_error__unknown_annotation
    assert_raises RBS::ParsingError do
      Parser.parse_inline_leading_annotation("@rbs super String", 0...)
    end
  end

  def test_parse__skip
    Parser.parse_inline_leading_annotation("@rbs skip", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::SkipAnnotation, annot
      assert_equal "@rbs skip", annot.location.source
      assert_equal "skip", annot.skip_location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs skip -- some comment here", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::SkipAnnotation, annot
      assert_equal "@rbs skip -- some comment here", annot.location.source
      assert_equal "skip", annot.skip_location.source
      assert_equal "-- some comment here", annot.comment_location.source
    end
  end

  def test_parse__return
    Parser.parse_inline_leading_annotation("@rbs return: void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ReturnTypeAnnotation, annot
      assert_equal "@rbs return: void", annot.location.source
      assert_equal "return", annot.return_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "void", annot.return_type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs return: self | class | instance -- some comment here", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ReturnTypeAnnotation, annot
      assert_equal "@rbs return: self | class | instance -- some comment here", annot.location.source
      assert_equal "return", annot.return_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "self | class | instance", annot.return_type.location.source
      assert_equal "-- some comment here", annot.comment_location.source
    end
  end

  def test_parse__type_application
    Parser.parse_inline_trailing_annotation("[String]", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::TypeApplicationAnnotation, annot
      assert_equal "[String]", annot.location.source
      assert_equal "[", annot.prefix_location.source
      assert_equal "]", annot.close_bracket_location.source
      assert_equal 1, annot.type_args.size
      assert_equal "String", annot.type_args[0].location.source
      assert_empty annot.comma_locations
    end

    Parser.parse_inline_trailing_annotation("[String, Integer]", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::TypeApplicationAnnotation, annot
      assert_equal "[String, Integer]", annot.location.source
      assert_equal "[", annot.prefix_location.source
      assert_equal "]", annot.close_bracket_location.source
      assert_equal 2, annot.type_args.size
      assert_equal "String", annot.type_args[0].location.source
      assert_equal "Integer", annot.type_args[1].location.source
      assert_equal [","], annot.comma_locations.map(&:source)
    end
  end

  def test_error__type_application
    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation("[String", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation("[]", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation("[String,]", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation("[,String]", 0...)
    end
  end

  def test_parse__instance_variable
    Parser.parse_inline_leading_annotation("@rbs @name: String", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::InstanceVariableAnnotation, annot
      assert_equal "@rbs @name: String", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@name", annot.ivar_name_location.source
      assert_equal :@name, annot.ivar_name
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs @age: Integer? -- person's age", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::InstanceVariableAnnotation, annot
      assert_equal "@rbs @age: Integer? -- person's age", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@age", annot.ivar_name_location.source
      assert_equal :@age, annot.ivar_name
      assert_equal ":", annot.colon_location.source
      assert_equal "Integer?", annot.type.location.source
      assert_equal "-- person's age", annot.comment_location.source
    end

    Parser.parse_inline_leading_annotation("@rbs @items: Array[String]", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::InstanceVariableAnnotation, annot
      assert_equal "@rbs @items: Array[String]", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@items", annot.ivar_name_location.source
      assert_equal :@items, annot.ivar_name
      assert_equal ":", annot.colon_location.source
      assert_equal "Array[String]", annot.type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs @sci: self | class | instance", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::InstanceVariableAnnotation, annot
      assert_equal "@rbs @sci: self | class | instance", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@sci", annot.ivar_name_location.source
      assert_equal :@sci, annot.ivar_name
      assert_equal ":", annot.colon_location.source
      assert_equal "self | class | instance", annot.type.location.source
      assert_nil annot.comment_location
    end
  end

  def test_error__instance_variable
    assert_raises RBS::ParsingError do
      Parser.parse_inline_leading_annotation("@rbs @name", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_leading_annotation("@rbs @name:", 0...)
    end

    assert_raises RBS::ParsingError do
      Parser.parse_inline_leading_annotation("@rbs @name: void", 0...)
    end
  end

  def test_parse__class_alias_without_type_name
    Parser.parse_inline_trailing_annotation(": class-alias", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ClassAliasAnnotation, annot
      assert_equal ": class-alias", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "class-alias", annot.keyword_location.source
      assert_nil annot.type_name_location
      assert_nil annot.type_name
    end
  end

  def test_parse__class_alias_with_type_name
    Parser.parse_inline_trailing_annotation(": class-alias Foo::Bar", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ClassAliasAnnotation, annot
      assert_equal ": class-alias Foo::Bar", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "class-alias", annot.keyword_location.source
      assert_equal "Foo::Bar", annot.type_name_location.source
      assert_equal TypeName.parse("Foo::Bar"), annot.type_name
    end
  end

  def test_parse__module_alias_without_type_name
    Parser.parse_inline_trailing_annotation(": module-alias", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ModuleAliasAnnotation, annot
      assert_equal ": module-alias", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "module-alias", annot.keyword_location.source
      assert_nil annot.type_name_location
      assert_nil annot.type_name
    end
  end

  def test_parse__module_alias_with_type_name
    Parser.parse_inline_trailing_annotation(": module-alias Kernel::Helper", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ModuleAliasAnnotation, annot
      assert_equal ": module-alias Kernel::Helper", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "module-alias", annot.keyword_location.source
      assert_equal "Kernel::Helper", annot.type_name_location.source
      assert_equal TypeName.parse("Kernel::Helper"), annot.type_name
    end
  end

  def test_error__class_alias_with_interface_name
    # Interface names (starting with _) are not valid for class-alias
    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation(": class-alias _Interface", 0...)
    end
  end

  def test_error__module_alias_with_type_variable
    # Type variables (lowercase names) are not valid for module-alias
    assert_raises RBS::ParsingError do
      Parser.parse_inline_trailing_annotation(": module-alias element", 0...)
    end
  end

  def test_parse__method_types_annotation
    Parser.parse_inline_leading_annotation("@rbs (String) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs (String) -> void", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal 1, annot.overloads.size
      annot.overloads[0].tap do |overload|
        assert_equal "(String) -> void", overload.method_type.location.source
        assert_empty overload.annotations
      end
      assert_empty annot.vertical_bar_locations
      assert_nil annot.dot3_location
    end

    Parser.parse_inline_leading_annotation("@rbs (String) -> void | (Integer) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs (String) -> void | (Integer) -> void", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal 2, annot.overloads.size
      annot.overloads[0].tap do |overload|
        assert_equal "(String) -> void", overload.method_type.location.source
      end
      annot.overloads[1].tap do |overload|
        assert_equal "(Integer) -> void", overload.method_type.location.source
      end
      assert_equal ["|"], annot.vertical_bar_locations.map(&:source)
      assert_nil annot.dot3_location
    end
  end

  def test_parse__method_types_annotation__with_dot3
    Parser.parse_inline_leading_annotation("@rbs (Float, Float) -> Float | ...", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs (Float, Float) -> Float | ...", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal 1, annot.overloads.size
      annot.overloads[0].tap do |overload|
        assert_equal "(Float, Float) -> Float", overload.method_type.location.source
      end
      assert_equal ["|"], annot.vertical_bar_locations.map(&:source)
      assert_equal "...", annot.dot3_location.source
    end

    Parser.parse_inline_leading_annotation("@rbs () -> void | %a{foo} () -> String | ...", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs () -> void | %a{foo} () -> String | ...", annot.location.source
      assert_equal 2, annot.overloads.size
      annot.overloads[0].tap do |overload|
        assert_equal "() -> void", overload.method_type.location.source
      end
      annot.overloads[1].tap do |overload|
        assert_equal "() -> String", overload.method_type.location.source
        assert_equal ["foo"], overload.annotations.map(&:string)
      end
      assert_equal ["|", "|"], annot.vertical_bar_locations.map(&:source)
      assert_equal "...", annot.dot3_location.source
    end
  end

  def test_parse__method_types_annotation__only_dot3
    Parser.parse_inline_leading_annotation("@rbs ...", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::MethodTypesAnnotation, annot
      assert_equal "@rbs ...", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_empty annot.overloads
      assert_empty annot.vertical_bar_locations
      assert_equal "...", annot.dot3_location.source
    end
  end

  def test_parse__param_type
    Parser.parse_inline_leading_annotation("@rbs x: untyped", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ParamTypeAnnotation, annot
      assert_equal "@rbs x: untyped", annot.location.source
      assert_equal "x", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "untyped", annot.param_type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs abc: untyped -- some comment here", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ParamTypeAnnotation, annot
      assert_equal "@rbs abc: untyped -- some comment here", annot.location.source
      assert_equal "abc", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "untyped", annot.param_type.location.source
      assert_equal "-- some comment here", annot.comment_location.source
    end
  end

  def test_parse__splat_param_type
    Parser.parse_inline_leading_annotation("@rbs *a: String", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::SplatParamTypeAnnotation, annot
      assert_equal "@rbs *a: String", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "*", annot.star_location.source
      assert_equal "a", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.param_type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs *a: String -- The rest args", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::SplatParamTypeAnnotation, annot
      assert_equal "@rbs *a: String -- The rest args", annot.location.source
      assert_equal "*", annot.star_location.source
      assert_equal "a", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.param_type.location.source
      assert_equal "-- The rest args", annot.comment_location.source
    end

    Parser.parse_inline_leading_annotation("@rbs *: String", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::SplatParamTypeAnnotation, annot
      assert_equal "@rbs *: String", annot.location.source
      assert_equal "*", annot.star_location.source
      assert_nil annot.name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.param_type.location.source
      assert_nil annot.comment_location
    end
  end

  def test_parse__double_splat_param_type
    Parser.parse_inline_leading_annotation("@rbs **b: bool", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::DoubleSplatParamTypeAnnotation, annot
      assert_equal "@rbs **b: bool", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "**", annot.star2_location.source
      assert_equal "b", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "bool", annot.param_type.location.source
      assert_nil annot.comment_location
    end

    Parser.parse_inline_leading_annotation("@rbs **opts: bool -- The keyword args", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::DoubleSplatParamTypeAnnotation, annot
      assert_equal "@rbs **opts: bool -- The keyword args", annot.location.source
      assert_equal "**", annot.star2_location.source
      assert_equal "opts", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "bool", annot.param_type.location.source
      assert_equal "-- The keyword args", annot.comment_location.source
    end

    Parser.parse_inline_leading_annotation("@rbs **: bool", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::DoubleSplatParamTypeAnnotation, annot
      assert_equal "@rbs **: bool", annot.location.source
      assert_equal "**", annot.star2_location.source
      assert_nil annot.name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "bool", annot.param_type.location.source
      assert_nil annot.comment_location
    end
  end

  def test_parse__param_type__skip
    Parser.parse_inline_leading_annotation("@rbs skip: untyped", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::ParamTypeAnnotation, annot
      assert_equal "@rbs skip: untyped", annot.location.source
      assert_equal "skip", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "untyped", annot.param_type.location.source
      assert_nil annot.comment_location
    end
  end

  def test_parse__block_type_annotation
    Parser.parse_inline_leading_annotation("@rbs &block: () [self: String] -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::BlockParamTypeAnnotation, annot
      assert_equal "@rbs &block: () [self: String] -> void", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "&", annot.ampersand_location.source
      assert_equal "block", annot.name_location.source
      assert_equal ":", annot.colon_location.source
      assert_nil annot.question_location
      assert_equal "() [self: String] -> void", annot.type_location.source
      assert_instance_of Types::Function, annot.type
      assert_nil annot.comment_location
      assert_equal :block, annot.name
      assert_equal false, annot.optional?
      assert_equal true, annot.required?
    end

      Parser.parse_inline_leading_annotation("@rbs &: ? (?) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotations::BlockParamTypeAnnotation, annot
      assert_equal "@rbs &: ? (?) -> void", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "&", annot.ampersand_location.source
      assert_nil annot.name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "?", annot.question_location.source
      assert_equal "(?) -> void", annot.type_location.source
      assert_instance_of Types::UntypedFunction, annot.type
      assert_nil annot.comment_location
      assert_nil annot.name
      assert_equal true, annot.optional?
      assert_equal false, annot.required?
    end
  end

  def test_error__block_type_annotation
    error = assert_raises RBS::ParsingError do
      Parser.parse_inline_leading_annotation("@rbs &block: () { () -> void } -> void", 0...)
    end
    assert_match(/block is not allowed in this context/, error.message)
    assert_match(/pLBRACE/, error.message)
    assert_equal "{", error.location.source
  end
end

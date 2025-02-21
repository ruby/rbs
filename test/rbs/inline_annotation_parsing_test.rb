require "test_helper"

class RBS::InlineAnnotationParsingTest < Test::Unit::TestCase
  include RBS

  include TestHelper

  def test_skip
    Parser.parse_inline("@rbs skip", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::SkipAnnotation, annot
      assert_equal "@rbs skip", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "skip", annot.skip_location.source
      assert_nil annot.comment
    end

    Parser.parse_inline("@rbs skip -- skipping", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::SkipAnnotation, annot
      assert_equal "@rbs skip -- skipping", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "skip", annot.skip_location.source
      assert_equal "-- skipping", annot.comment.source
    end
  end

  def test_colon_method_type
    Parser.parse_inline(": (untyped) -> void", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ColonMethodTypeAnnotation, annot
      assert_equal ": (untyped) -> void", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "(untyped) -> void", annot.method_type.location.source
    end

    Parser.parse_inline(": [T] (T) -> T", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ColonMethodTypeAnnotation, annot
      assert_equal ": [T] (T) -> T", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "[T] (T) -> T", annot.method_type.location.source
    end

    Parser.parse_inline(": { () -> void } -> top", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ColonMethodTypeAnnotation, annot
      assert_equal ": { () -> void } -> top", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "{ () -> void } -> top", annot.method_type.location.source
    end

    Parser.parse_inline(": %a{foo} () -> top", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ColonMethodTypeAnnotation, annot
      assert_equal ": %a{foo} () -> top", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_equal "() -> top", annot.method_type.location.source
      assert_equal ["foo"], annot.annotations.map(&:string)
    end
  end

  def test_method_types_annotation
    Parser.parse_inline("@rbs (untyped) -> void | %a{pure} () -> String?", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::MethodTypesAnnotation, annot
      assert_equal "@rbs (untyped) -> void | %a{pure} () -> String?", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source

      annot.overloads[0] do |overload|
        assert_empty overload.annotations
        assert_equal "(untyped) -> void", overload.method_type.location.source
      end

      annot.overloads[1] do |overload|
        assert_equal ["pure"], overload.annotations.map(&:string)
        assert_equal "() -> String?", overload.method_type.location.source
      end

      assert_equal ["|"], annot.vertical_bar_locations.map(&:source)
    end

    Parser.parse_inline("@rbs %a{pure} () -> String?", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::MethodTypesAnnotation, annot
      assert_equal "@rbs %a{pure} () -> String?", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source

      annot.overloads[0] do |overload|
        assert_equal ["pure"], overload.annotations.map(&:string)
        assert_equal "() -> String?", overload.method_type.location.source
      end

      assert_empty annot.vertical_bar_locations.map(&:source)
    end
  end

  def test_return_type_annotation
    Parser.parse_inline("@rbs return: String -- returns a string", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ReturnTypeAnnotation, annot
      assert_equal "@rbs return: String -- returns a string", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "return", annot.return_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.return_type.location.source
      assert_equal "-- returns a string", annot.comment.source
    end
  end

  def test_param_type_annotation
    Parser.parse_inline("@rbs param: String -- a string", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ParamTypeAnnotation, annot
      assert_equal "@rbs param: String -- a string", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "param", annot.param_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- a string", annot.comment.source
    end
  end

  def test_splat_param_type_annotation
    Parser.parse_inline("@rbs *args: String -- strings", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::SplatParamTypeAnnotation, annot
      assert_equal "@rbs *args: String -- strings", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "*", annot.operator_location.source
      assert_equal "args", annot.param_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- strings", annot.comment.source
    end

    Parser.parse_inline("@rbs *: String -- strings", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::SplatParamTypeAnnotation, annot
      assert_equal "@rbs *: String -- strings", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "*", annot.operator_location.source
      assert_nil annot.param_name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- strings", annot.comment.source
    end
  end

  def test_double_splat_param_type_annotation
    Parser.parse_inline("@rbs **args: String -- strings", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::DoubleSplatParamTypeAnnotation, annot
      assert_equal "@rbs **args: String -- strings", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "**", annot.operator_location.source
      assert_equal "args", annot.param_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- strings", annot.comment.source
    end

    Parser.parse_inline("@rbs **: String -- strings", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::DoubleSplatParamTypeAnnotation, annot
      assert_equal "@rbs **: String -- strings", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "**", annot.operator_location.source
      assert_nil annot.param_name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- strings", annot.comment.source
    end
  end

  def test_block_param_type_annotation
    Parser.parse_inline("@rbs &block: (String) -> void -- block", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::BlockParamTypeAnnotation, annot
      assert_equal "@rbs &block: (String) -> void -- block", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "&", annot.operator_location.source
      assert_equal "block", annot.param_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_nil annot.question_mark_location
      assert_instance_of Types::Block, annot.block
      assert annot.block.required
      assert_equal "-- block", annot.comment.source
    end

    Parser.parse_inline("@rbs &: ? () [self: instance] -> void -- block", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::BlockParamTypeAnnotation, annot
      assert_equal "@rbs &: ? () [self: instance] -> void -- block", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "&", annot.operator_location.source
      assert_nil annot.param_name_location
      assert_equal ":", annot.colon_location.source
      assert_equal "?", annot.question_mark_location.source
      assert_instance_of Types::Block, annot.block
      refute annot.block.required
      assert_equal "-- block", annot.comment.source
    end
  end

  def test_override_annotation
    Parser.parse_inline("@rbs override", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::OverrideAnnotation, annot
      assert_equal "@rbs override", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "override", annot.override_location.source
    end
  end

  def test_generic_annotation
    Parser.parse_inline("@rbs generic A", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::GenericAnnotation, annot
      assert_equal "@rbs generic A", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "generic", annot.generic_location.source
      assert_nil annot.unchecked_location
      assert_nil annot.variance_location
      assert_equal "A", annot.name_location.source
      assert_nil annot.upper_bound_operator_location
      assert_nil annot.upper_bound
      assert_nil annot.default_type_operator_location
      assert_nil annot.default_type
      assert_nil annot.comment
    end

    Parser.parse_inline("@rbs generic unchecked out A < String = untyped -- hello", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::GenericAnnotation, annot
      assert_equal "@rbs generic unchecked out A < String = untyped -- hello", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "generic", annot.generic_location.source
      assert_equal "unchecked", annot.unchecked_location.source
      assert_equal "out", annot.variance_location.source
      assert_equal "A", annot.name_location.source
      assert_equal "<", annot.upper_bound_operator_location.source
      assert_instance_of RBS::Types::ClassInstance, annot.upper_bound
      assert_equal "=", annot.default_type_operator_location.source
      assert_instance_of RBS::Types::Bases::Any, annot.default_type
      assert_equal "-- hello", annot.comment.source
    end
  end

  def test_annotation_annotation
    Parser.parse_inline("@rbs %a{foo} %a{bar}", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::RBSAnnotationAnnotation, annot
      assert_equal "@rbs %a{foo} %a{bar}", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal ["foo", "bar"], annot.annotations.map(&:string)
    end
  end

  def test_type_assertion
    Parser.parse_inline_assertion(": String?", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::NodeTypeAssertion, annot
      assert_equal ": String?", annot.location.source
      assert_equal ":", annot.prefix_location.source
      assert_instance_of RBS::Types::Optional, annot.type
    end
  end

  def test_type_application
    Parser.parse_inline_assertion("[String?, nil]", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::NodeApplication, annot
      assert_equal "[String?, nil]", annot.location.source
      assert_equal "[", annot.prefix_location.source
      assert_instance_of RBS::Types::Optional, annot.types[0]
      assert_instance_of RBS::Types::Bases::Nil, annot.types[1]
      assert_equal "]", annot.suffix_location.source
    end
  end

  def test_inherits_annotation
    Parser.parse_inline("@rbs inherits Foo", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::InheritsAnnotation, annot

      assert_equal "@rbs inherits Foo", annot.location.source
      assert_equal "inherits", annot.inherits_location.source
      assert_equal TypeName.parse("Foo"), annot.type_name
      assert_equal "Foo", annot.type_name_location.source
      assert_nil annot.open_paren_location
      assert_empty annot.type_args
      assert_nil annot.close_paren_location
      assert_nil annot.comment
    end

    Parser.parse_inline("@rbs inherits Foo[_Each[untyped], untyped] -- comment", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::InheritsAnnotation, annot

      assert_equal "@rbs inherits Foo[_Each[untyped], untyped] -- comment", annot.location.source
      assert_equal "inherits", annot.inherits_location.source
      assert_equal TypeName.parse("Foo"), annot.type_name
      assert_equal "Foo", annot.type_name_location.source
      assert_equal "[", annot.open_paren_location.source
      assert_equal "_Each[untyped]", annot.type_args[0].location.source
      assert_equal "untyped", annot.type_args[1].location.source
      assert_equal "]", annot.close_paren_location.source
      assert_equal "-- comment", annot.comment.source
    end
  end

  def test_class_module_annotation
    omit("Implement `@rbs class/@rbs module` annotation")

    Parser.parse_inline("@rbs class Foo[String?, nil]", 0...).tap do |annot|
    end

    Parser.parse_inline("@rbs module Foo[String?, nil]", 0...).tap do |annot|
    end
  end

  def test_module_self_annotation
    Parser.parse_inline("@rbs module-self _Foo", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ModuleSelfAnnotation, annot

      assert_equal "@rbs module-self _Foo", annot.location.source
      assert_equal "module-self", annot.module_self_location.source
      assert_equal TypeName.parse("_Foo"), annot.type_name
      assert_equal "_Foo", annot.type_name_location.source
      assert_nil annot.open_paren_location
      assert_empty annot.type_args
      assert_nil annot.close_paren_location
    end

    Parser.parse_inline("@rbs module-self Foo[String?, nil] -- comment", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ModuleSelfAnnotation, annot

      assert_equal "@rbs module-self Foo[String?, nil] -- comment", annot.location.source
      assert_equal "module-self", annot.module_self_location.source
      assert_equal TypeName.parse("Foo"), annot.type_name
      assert_equal "Foo", annot.type_name_location.source
      assert_equal "[", annot.open_paren_location.source
      assert_equal "String?", annot.type_args[0].location.source
      assert_equal "nil", annot.type_args[1].location.source
      assert_equal "]", annot.close_paren_location.source
      assert_equal "-- comment", annot.comment.source
    end
  end

  def test_instance_variable_annotation
    Parser.parse_inline("@rbs @name: String -- name of something", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::IvarTypeAnnotation, annot

      assert_equal "@rbs @name: String -- name of something", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@name", annot.var_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- name of something", annot.comment.source
    end

    Parser.parse_inline("@rbs @rbs: String -- name of something", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::IvarTypeAnnotation, annot

      assert_equal "@rbs @rbs: String -- name of something", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@rbs", annot.var_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- name of something", annot.comment.source
    end

    Parser.parse_inline("@rbs self.@name: String -- name of something", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ClassIvarTypeAnnotation, annot

      assert_equal "@rbs self.@name: String -- name of something", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "self", annot.self_location.source
      assert_equal ".", annot.dot_location.source
      assert_equal "@name", annot.var_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- name of something", annot.comment.source
    end

    Parser.parse_inline("@rbs self.@rbs: String -- name of something", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ClassIvarTypeAnnotation, annot

      assert_equal "@rbs self.@rbs: String -- name of something", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "self", annot.self_location.source
      assert_equal ".", annot.dot_location.source
      assert_equal "@rbs", annot.var_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- name of something", annot.comment.source
    end

    Parser.parse_inline("@rbs @@name: String -- name of something", 0...).tap do |annot|
      assert_instance_of AST::Ruby::Annotation::ClassVarTypeAnnotation, annot

      assert_equal "@rbs @@name: String -- name of something", annot.location.source
      assert_equal "@rbs", annot.prefix_location.source
      assert_equal "@@name", annot.var_name_location.source
      assert_equal ":", annot.colon_location.source
      assert_equal "String", annot.type.location.source
      assert_equal "-- name of something", annot.comment.source
    end
  end

  def test_embbed_syntax
    omit("Implement `@rbs!` annotation")
    Parser.parse_inline(<<~RBS, 0...).tap do |annot|
        @rbs!
          interface _Hello
            def foo: () -> void
          end

          type world = top
      RBS
    end
  end

  def test_use
    omit("Implement `@rbs use` annotation")
    Parser.parse_inline_uses(<<~RBS, 0...).tap do |uses|
        use Foo, Bar::*, Baz as B
      RBS
    end
  end
end

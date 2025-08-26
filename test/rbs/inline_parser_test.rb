require "test_helper"

class RBS::InlineParserTest < Test::Unit::TestCase
  include TestHelper

  def parse(src)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: src)

    prism = Prism.parse(src)
    RBS::InlineParser.parse(buffer, prism)
  end

  def test_parse__class
    result = parse(<<~RUBY)
      class Hello
        class World
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Hello"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, member
        assert_equal RBS::TypeName.parse("World"), member.class_name
      end
    end
  end

  def test_error__class__non_constant_name
    result = parse(<<~RUBY)
      class (C = Object)::Hello
        class World
        end
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics, size: 1) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantClassName, diagnostic
      assert_equal ("(C = Object)::Hello"), diagnostic.location.source
      assert_equal "Class name must be a constant", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_parse__module
    result = parse(<<~RUBY)
      module Hello
        module World
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, decl
      assert_equal RBS::TypeName.parse("Hello"), decl.module_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, member
        assert_equal RBS::TypeName.parse("World"), member.module_name
      end
    end
  end

  def test_error__module__non_constant_name
    result = parse(<<~RUBY)
      module (C = Object)::Hello
        module World
        end
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics, size: 1) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantModuleName, diagnostic
      assert_equal ("(C = Object)::Hello"), diagnostic.location.source
      assert_equal "Module name must be a constant", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_parse__def
    result = parse(<<~RUBY)
      class Foo
        def foo; end
      end
    RUBY

    assert_empty result.diagnostics

    assert_equal 1, result.declarations.size
    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_equal :foo, member.name
        assert_equal "def foo; end", member.location.source
      end
    end
  end

  def test_error__def__toplevel
    result = parse(<<~RUBY)
      def foo; end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelMethodDefinition, diagnostic
      assert_equal "foo", diagnostic.location.source
      assert_equal "Top-level method definition is not supported", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_error__def__singleton
    result = parse(<<~RUBY)
      module Foo
        def self.foo; end
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NotImplementedYet, diagnostic
      assert_equal "self", diagnostic.location.source
      assert_equal "Singleton method definition is not supported yet", diagnostic.message
    end
  end

  def test_parse__def_return_type_assertion
    result = parse(<<~RUBY)
      class Foo
        def foo #: void
          ""
        end

        def bar = "" #: void
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["() -> void"], member.overloads.map { _1.method_type.to_s }
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["(?) -> untyped"], member.overloads.map { _1.method_type.to_s }
      end
    end
  end

  def test_error__def_return_type_assertion
    result = parse(<<~RUBY)
      class Foo
        def foo #: void[
          ""
        end
      end
    RUBY

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal ": void[", diagnostic.location.source
      assert_equal "Syntax error: expected a token `pEOF`", diagnostic.message
    end

    result.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["(?) -> untyped"], member.overloads.map { _1.method_type.to_s }
      end
    end
  end

  def test_parse__def_colon_method_type
    result = parse(<<~RUBY)
      class Foo
        #: () -> void
        #
        def foo
          ""
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["() -> void"], member.overloads.map { _1.method_type.to_s }
      end
    end
  end

  def test_parse__def_method_types
    result = parse(<<~RUBY)
      class Foo
        # @rbs () -> void
        #    | (String) -> bot
        def foo(x = nil)
          ""
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["() -> void", "(String) -> bot"], member.overloads.map { _1.method_type.to_s }
      end
    end
  end

  def test_parse__skip_class_module
    result = parse(<<~RUBY)
      # @rbs skip -- not a constant
      class (c::)Foo
      end

      # @rbs skip
      module Bar
      end
    RUBY

    assert_empty result.diagnostics

    assert_empty result.declarations
  end

  def test_parse__skip_def
    result = parse(<<~RUBY)
      class Foo
        # @rbs skip
        def foo
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_empty decl.members
    end
  end

  def test_parse__return_type
    result = parse(<<~RUBY)
      class Foo
        # @rbs return: void
        def foo
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_instance_of Array, member.annotations
        assert_equal ["() -> void"], member.overloads.map { _1.method_type.to_s }
      end
    end
  end

  def test_parse__include
    result = parse(<<~RUBY)
      class Foo
        include Bar
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::IncludeMember, member
        assert_equal RBS::TypeName.parse("Bar"), member.module_name
        assert_equal "include Bar", member.location.source
        assert_equal "Bar", member.name_location.source
      end
    end
  end

  def test_parse__extend
    result = parse(<<~RUBY)
      class Foo
        extend Bar
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::ExtendMember, member
        assert_equal RBS::TypeName.parse("Bar"), member.module_name
        assert_equal "extend Bar", member.location.source
        assert_equal "Bar", member.name_location.source
      end
    end
  end

  def test_parse__prepend
    result = parse(<<~RUBY)
      class Foo
        prepend Bar
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PrependMember, member
        assert_equal RBS::TypeName.parse("Bar"), member.module_name
        assert_equal "prepend Bar", member.location.source
        assert_equal "Bar", member.name_location.source
      end
    end
  end

  def test_error__include_multiple_arguments
    result = parse(<<~RUBY)
      class Foo
        include Bar, Baz
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "include Bar, Baz", diagnostic.location.source
      assert_equal "Mixing multiple modules with one call is not supported", diagnostic.message
    end
  end

  def test_error__extend_multiple_arguments
    result = parse(<<~RUBY)
      class Foo
        extend Bar, Baz
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "extend Bar, Baz", diagnostic.location.source
      assert_equal "Mixing multiple modules with one call is not supported", diagnostic.message
    end
  end

  def test_error__prepend_multiple_arguments
    result = parse(<<~RUBY)
      class Foo
        prepend Bar, Baz
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "prepend Bar, Baz", diagnostic.location.source
      assert_equal "Mixing multiple modules with one call is not supported", diagnostic.message
    end
  end

  def test_error__include_non_constant
    result = parse(<<~RUBY)
      class Foo
        include bar
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "bar", diagnostic.location.source
      assert_equal "Module name must be a constant", diagnostic.message
    end
  end

  def test_error__extend_non_constant
    result = parse(<<~RUBY)
      class Foo
        extend bar
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "bar", diagnostic.location.source
      assert_equal "Module name must be a constant", diagnostic.message
    end
  end

  def test_error__prepend_non_constant
    result = parse(<<~RUBY)
      class Foo
        prepend bar
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_equal "bar", diagnostic.location.source
      assert_equal "Module name must be a constant", diagnostic.message
    end
  end

  def test_parse__include_with_type_application
    result = parse(<<~RUBY)
      class Foo
        include Bar #[String]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::IncludeMember, member
        assert_equal RBS::TypeName.parse("Bar"), member.module_name
        assert_equal "include Bar", member.location.source
        assert_equal "Bar", member.name_location.source
        assert_equal 1, member.type_args.size
        assert_equal "String", member.type_args[0].to_s
      end
    end
  end

  def test_parse__extend_with_type_application
    result = parse(<<~RUBY)
      class Foo
        extend(
          Enumerable
        ) #[Integer, void]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::ExtendMember, member
        assert_equal RBS::TypeName.parse("Enumerable"), member.module_name
        assert_equal "extend(\n    Enumerable\n  )", member.location.source
        assert_equal "Enumerable", member.name_location.source
        assert_equal 2, member.type_args.size
        assert_equal "Integer", member.type_args[0].to_s
        assert_equal "void", member.type_args[1].to_s
      end
    end
  end

  def test_parse__prepend_with_type_application
    result = parse(<<~RUBY)
      class Foo
        prepend Bar #[String, Integer]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PrependMember, member
        assert_equal RBS::TypeName.parse("Bar"), member.module_name
        assert_equal "prepend Bar", member.location.source
        assert_equal "Bar", member.name_location.source
        assert_equal 2, member.type_args.size
        assert_equal "String", member.type_args[0].to_s
        assert_equal "Integer", member.type_args[1].to_s
      end
    end
  end

  def test_parse__attr_reader
    result = parse(<<~RUBY)
      class Foo
        attr_reader :name
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        assert_equal "attr_reader :name", member.location.source

        assert_nil member.type_annotation
        assert_nil member.type
      end
    end
  end

  def test_parse__attr_writer
    result = parse(<<~RUBY)
      class Foo
        attr_writer :name
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrWriterMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        assert_equal "attr_writer :name", member.location.source

        assert_nil member.type_annotation
        assert_nil member.type
      end
    end
  end

  def test_parse__attr_accessor
    result = parse(<<~RUBY)
      class Foo
        attr_accessor :name
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrAccessorMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        assert_equal "attr_accessor :name", member.location.source

        assert_nil member.type_annotation
        assert_nil member.type
      end
    end
  end

  def test_parse__attr_reader_with_type
    result = parse(<<~RUBY)
      class Foo
        attr_reader :name #: String
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        assert_equal "attr_reader :name", member.location.source

        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
        assert_equal "String", member.type.to_s
      end
    end
  end

  def test_parse__attr_writer_with_type
    result = parse(<<~RUBY)
      class Foo
        attr_writer :count #: Integer
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrWriterMember, member

        assert_equal [:count], member.names
        assert_equal [":count"], member.name_locations.map(&:source)

        assert_equal "attr_writer :count", member.location.source

        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
        assert_equal "Integer", member.type.to_s
      end
    end
  end

  def test_parse__attr_accessor_with_type
    result = parse(<<~RUBY)
      class Foo
        attr_accessor :data #: Array[String]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrAccessorMember, member

        assert_equal [:data], member.names
        assert_equal [":data"], member.name_locations.map(&:source)

        assert_equal "attr_accessor :data", member.location.source

        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
        assert_equal "Array[String]", member.type.to_s
      end
    end
  end

  def test_parse__attr_multiple_args
    result = parse(<<~RUBY)
      class Foo
        attr_reader :name, :age
        attr_writer :x, :y, :z
        attr_accessor :foo, :bar
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      # attr_reader :name, :age should create one member with multiple names
      assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, decl.members[0]
      assert_equal [:name, :age], decl.members[0].names
      assert_equal [":name", ":age"], decl.members[0].name_locations.map(&:source)
      assert_nil decl.members[0].type_annotation
      assert_nil decl.members[0].type

      # attr_writer :x, :y, :z should create one member with multiple names
      assert_instance_of RBS::AST::Ruby::Members::AttrWriterMember, decl.members[1]
      assert_equal [:x, :y, :z], decl.members[1].names
      assert_equal [":x", ":y", ":z"], decl.members[1].name_locations.map(&:source)
      assert_nil decl.members[1].type_annotation
      assert_nil decl.members[1].type

      # attr_accessor :foo, :bar should create one member with multiple names
      assert_instance_of RBS::AST::Ruby::Members::AttrAccessorMember, decl.members[2]
      assert_equal [:foo, :bar], decl.members[2].names
      assert_equal [":foo", ":bar"], decl.members[2].name_locations.map(&:source)
      assert_nil decl.members[2].type_annotation
      assert_nil decl.members[2].type
    end
  end

  def test_parse__attr_with_comment_annotation
    result = parse(<<~RUBY)
      class Foo
        # @rbs name: String
        attr_reader :name

        # @rbs age: Integer
        attr_writer :age

        # @rbs data: Array[Hash[Symbol, untyped]]
        attr_accessor :data
      end
    RUBY

    # The @rbs annotations should be reported as syntax errors (invalid format)
    assert_equal 3, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal "@rbs name: String", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal "@rbs age: Integer", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal "@rbs data: Array[Hash[Symbol, untyped]]", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        # The @rbs annotation should be ignored
        assert_nil member.type_annotation
        assert_nil member.type

        # The comment block should be attached
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal ["@rbs name: String"], member.leading_comment.comment_buffer.lines
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrWriterMember, member

        assert_equal [:age], member.names
        assert_equal [":age"], member.name_locations.map(&:source)

        # The @rbs annotation should be ignored
        assert_nil member.type_annotation
        assert_nil member.type

        # The comment block should be attached
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal ["@rbs age: Integer"], member.leading_comment.comment_buffer.lines
      end

      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrAccessorMember, member

        assert_equal [:data], member.names
        assert_equal [":data"], member.name_locations.map(&:source)

        # The @rbs annotation should be ignored
        assert_nil member.type_annotation
        assert_nil member.type

        # The comment block should be attached
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal ["@rbs data: Array[Hash[Symbol, untyped]]"], member.leading_comment.comment_buffer.lines
      end
    end
  end

  def test_error__attr_toplevel
    result = parse(<<~RUBY)
      attr_reader :name
      attr_writer :age
      attr_accessor :data
    RUBY

    # Should have errors for toplevel attribute definitions
    assert_equal 3, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelAttributeDefinition, diagnostic
      assert_equal "attr_reader", diagnostic.location.source
      assert_equal "Top-level attribute definition is not supported", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelAttributeDefinition, diagnostic
      assert_equal "attr_writer", diagnostic.location.source
      assert_equal "Top-level attribute definition is not supported", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelAttributeDefinition, diagnostic
      assert_equal "attr_accessor", diagnostic.location.source
      assert_equal "Top-level attribute definition is not supported", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_parse__attr_skip
    result = parse(<<~RUBY)
      class Foo
        # @rbs skip
        attr_reader :ignored

        attr_accessor :name #: String
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      # Only one member should be present (the skipped one should be ignored)
      assert_equal 1, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrAccessorMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
        assert_equal "String", member.type.to_s
      end
    end
  end

  def test_error__attr_non_symbol
    result = parse(<<~RUBY)
      class Foo
        attr_reader "name"
        attr_writer 123
        attr_accessor foo()
      end
    RUBY

    # Should have errors for non-symbol attribute names
    assert_equal 3, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AttributeNonSymbolName, diagnostic
      assert_equal '"name"', diagnostic.location.source
      assert_equal "Attribute name must be a symbol", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AttributeNonSymbolName, diagnostic
      assert_equal '123', diagnostic.location.source
      assert_equal "Attribute name must be a symbol", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AttributeNonSymbolName, diagnostic
      assert_equal 'foo()', diagnostic.location.source
      assert_equal "Attribute name must be a symbol", diagnostic.message
    end
  end

  def test_error__attr_type_syntax_error
    result = parse(<<~RUBY)
      class Foo
        attr_reader :name #: String[
        attr_writer :age #: Integer)
      end
    RUBY

    # Should have syntax errors for malformed type annotations
    assert_equal 2, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal ": String[", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal ": Integer)", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, member

        assert_equal [:name], member.names
        assert_equal [":name"], member.name_locations.map(&:source)

        # The invalid type annotation should be ignored
        assert_nil member.type_annotation
        assert_nil member.type
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrWriterMember, member

        assert_equal [:age], member.names
        assert_equal [":age"], member.name_locations.map(&:source)

        # The invalid type annotation should be ignored
        assert_nil member.type_annotation
        assert_nil member.type
      end
    end
  end

  def test_parse__class_with_super_class
    result = parse(<<~RUBY)
      class Child < Parent
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Child"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("Parent"), decl.super_class.name
      assert_empty decl.super_class.args
    end
  end

  def test_parse__class_with_super_class_nested
    result = parse(<<~RUBY)
      class UsersController < ApplicationController
        class Error < StandardError
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("UsersController"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("ApplicationController"), decl.super_class.name
      assert_empty decl.super_class.args

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, member
        assert_equal RBS::TypeName.parse("Error"), member.class_name
        assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, member.super_class
        assert_equal RBS::TypeName.parse("StandardError"), member.super_class.name
        assert_empty member.super_class.args
      end
    end
  end

  def test_parse__class_with_super_class_type_application
    result = parse(<<~RUBY)
      class StringArray < Array #[String]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("StringArray"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("Array"), decl.super_class.name
      assert_equal 1, decl.super_class.args.size
      assert_equal "String", decl.super_class.args[0].to_s
    end
  end

  def test_parse__class_with_super_class_complex_type_application
    result = parse(<<~RUBY)
      class MyHash < Hash #[Symbol, Array[Integer]]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("MyHash"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("Hash"), decl.super_class.name
      assert_equal 2, decl.super_class.args.size
      assert_equal "Symbol", decl.super_class.args[0].to_s
      assert_equal "Array[Integer]", decl.super_class.args[1].to_s
    end
  end

  def test_parse__class_with_qualified_super_class
    result = parse(<<~RUBY)
      class MyError < ActiveRecord::RecordNotFound
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("MyError"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("ActiveRecord::RecordNotFound"), decl.super_class.name
      assert_empty decl.super_class.args
    end
  end

  def test_error__class_with_non_constant_super_class
    result = parse(<<~RUBY)
      class Child < parent
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantSuperClassName, diagnostic
      assert_equal "parent", diagnostic.location.source
      assert_equal "Super class name must be a constant", diagnostic.message
    end

    # The class should still be created but without super class
    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Child"), decl.class_name
      assert_nil decl.super_class
    end
  end

  def test_error__class_with_dynamic_super_class
    result = parse(<<~RUBY)
      Parent = Class.new
      class Child < Parent.new
      end
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantSuperClassName, diagnostic
      assert_equal "Parent.new", diagnostic.location.source
      assert_equal "Super class name must be a constant", diagnostic.message
    end

    # The class should still be created but without super class
    result.declarations[1].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Child"), decl.class_name
      assert_nil decl.super_class
    end
  end

  def test_parse__class_with_super_class_and_members
    result = parse(<<~RUBY)
      class Person < ActiveRecord::Base #[Person]
        attr_reader :name #: String

        def age
          25
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Person"), decl.class_name
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperClass, decl.super_class
      assert_equal RBS::TypeName.parse("ActiveRecord::Base"), decl.super_class.name
      assert_equal 1, decl.super_class.args.size
      assert_equal "Person", decl.super_class.args[0].to_s

      assert_equal 2, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::AttrReaderMember, member
        assert_equal [:name], member.names
        assert_equal "String", member.type.to_s
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_equal :age, member.name
      end
    end
  end

  def test_parse__instance_variable
    result = parse(<<~RUBY)
      class Person
        # @rbs @name: String
        # @rbs @age: Integer?

        def initialize(name, age)
          @name = name
          @age = age
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Person"), decl.class_name

      # Should have 3 members: 2 instance variable members + 1 def member
      assert_equal 3, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::InstanceVariableMember, member
        assert_equal :@name, member.name
        assert_equal "String", member.type.to_s
        assert_instance_of RBS::AST::Ruby::Annotations::InstanceVariableAnnotation, member.annotation
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::InstanceVariableMember, member
        assert_equal :@age, member.name
        assert_equal "Integer?", member.type.to_s
        assert_instance_of RBS::AST::Ruby::Annotations::InstanceVariableAnnotation, member.annotation
      end

      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_equal :initialize, member.name
      end
    end
  end

  def test_error__instance_variable_ignored
    result = parse(<<~RUBY)
      # @rbs @global_decl: String

      class Foo
        def initialize
          # @rbs @method_decl: Integer
        end

        tap do
          # @rbs @block_decl: String
        end

        # @rbs @method_decl2: untyped
        def foo
        end
      end
    RUBY

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::UnusedInlineAnnotation, diagnostic
      assert_equal "@rbs @global_decl: String", diagnostic.location.source
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::UnusedInlineAnnotation, diagnostic
      assert_equal "@rbs @method_decl: Integer", diagnostic.location.source
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::UnusedInlineAnnotation, diagnostic
      assert_equal "@rbs @method_decl2: untyped", diagnostic.location.source
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::UnusedInlineAnnotation, diagnostic
      assert_equal "@rbs @block_decl: String", diagnostic.location.source
    end
  end

  def test_parse__constant_declaration_basic
    result = parse(<<~RUBY)
      class Example
        FOO = 42
        BAR = "hello"
        BAZ = true
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Example"), decl.class_name

      assert_equal 3, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("FOO"), member.constant_name
        assert_equal "FOO = 42", member.location.source
        assert_equal "FOO", member.name_location.source
        assert_equal "::Integer", member.type.to_s
        assert_nil member.type_annotation
        assert_nil member.leading_comment
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("BAR"), member.constant_name
        assert_equal "BAR = \"hello\"", member.location.source
        assert_equal "BAR", member.name_location.source
        assert_equal "::String", member.type.to_s
        assert_nil member.type_annotation
        assert_nil member.leading_comment
      end

      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("BAZ"), member.constant_name
        assert_equal "BAZ = true", member.location.source
        assert_equal "BAZ", member.name_location.source
        assert_equal "bool", member.type.to_s
        assert_nil member.type_annotation
        assert_nil member.leading_comment
      end
    end
  end

  def test_parse__constant_declaration_with_type_annotation
    result = parse(<<~RUBY)
      class TypedConstants
        ITEMS = [] #: Array[String]
        COUNT = 0 #: Float
        CONFIG = {} #: Hash[Symbol, untyped]
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("TypedConstants"), decl.class_name

      assert_equal 3, decl.members.size

      # Test ITEMS with Array[String] annotation
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("ITEMS"), member.constant_name
        assert_equal "Array[String]", member.type.to_s
        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
      end

      # Test COUNT with Float annotation (overriding inferred Integer)
      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("COUNT"), member.constant_name
        assert_equal "Float", member.type.to_s
        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
      end

      # Test CONFIG with Hash[Symbol, untyped] annotation
      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("CONFIG"), member.constant_name
        assert_equal "Hash[Symbol, untyped]", member.type.to_s
        assert_instance_of RBS::AST::Ruby::Annotations::NodeTypeAssertion, member.type_annotation
      end
    end
  end

  def test_parse__constant_declaration_with_leading_comment
    result = parse(<<~RUBY)
      class DocumentedConstants
        # This is a port number
        PORT = 8080

        # @deprecated Use NEW_API instead
        OLD_API_URL = "http://old.example.com"

        # Multiple line comment
        # explaining the purpose
        # of this constant
        VERSION = "1.0.0"
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("DocumentedConstants"), decl.class_name

      assert_equal 3, decl.members.size

      # Test PORT with single line comment
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("PORT"), member.constant_name
        assert_equal "::Integer", member.type.to_s
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal "# This is a port number", member.leading_comment.location.source
      end

      # Test OLD_API_URL with @deprecated comment
      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("OLD_API_URL"), member.constant_name
        assert_equal "::String", member.type.to_s
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal "# @deprecated Use NEW_API instead", member.leading_comment.location.source
      end

      # Test VERSION with multi-line comment
      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("VERSION"), member.constant_name
        assert_equal "::String", member.type.to_s
        assert_instance_of RBS::AST::Ruby::CommentBlock, member.leading_comment
        assert_equal <<-COMMENT.chomp, member.leading_comment.location.source
# Multiple line comment
  # explaining the purpose
  # of this constant
COMMENT
      end
    end
  end

  def test_parse__constant_declaration_skip
    result = parse(<<~RUBY)
      class SkipTest
        # @rbs skip
        SKIPPED_CONSTANT = "ignored"

        NORMAL_CONSTANT = 42
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("SkipTest"), decl.class_name

      # Only one member should be present (the skipped one should be ignored)
      assert_equal 1, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("NORMAL_CONSTANT"), member.constant_name
        assert_equal "::Integer", member.type.to_s
      end
    end
  end

  def test_parse__constant_declaration_toplevel
    result = parse(<<~RUBY)
      GLOBAL_CONSTANT = "allowed"
      ANOTHER_GLOBAL = 123
    RUBY

    # Top-level constant definitions should be allowed
    assert_empty result.diagnostics

    # Should have 2 top-level constant declarations
    assert_equal 2, result.declarations.size

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, decl
      assert_equal RBS::TypeName.parse("GLOBAL_CONSTANT"), decl.constant_name
      assert_equal "GLOBAL_CONSTANT = \"allowed\"", decl.location.source
      assert_equal "GLOBAL_CONSTANT", decl.name_location.source
      assert_equal "::String", decl.type.to_s
      assert_nil decl.type_annotation
      assert_nil decl.leading_comment
    end

    result.declarations[1].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, decl
      assert_equal RBS::TypeName.parse("ANOTHER_GLOBAL"), decl.constant_name
      assert_equal "ANOTHER_GLOBAL = 123", decl.location.source
      assert_equal "ANOTHER_GLOBAL", decl.name_location.source
      assert_equal "::Integer", decl.type.to_s
      assert_nil decl.type_annotation
      assert_nil decl.leading_comment
    end
  end

  def test_error__constant_declaration_type_annotation_syntax_error
    result = parse(<<~RUBY)
      class SyntaxErrorTest
        MALFORMED_TYPE = [] #: Array[
        INVALID_TYPE = {} #: Hash}
      end
    RUBY

    # Should have syntax errors for malformed type annotations
    assert_equal 2, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal ": Array[", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::AnnotationSyntaxError, diagnostic
      assert_equal ": Hash}", diagnostic.location.source
      assert_match(/Syntax error:/, diagnostic.message)
    end

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("SyntaxErrorTest"), decl.class_name

      assert_equal 2, decl.members.size

      # Both constants should be present but with fallback types
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("MALFORMED_TYPE"), member.constant_name
        assert_equal "untyped", member.type.to_s # fallback for array literal
        assert_nil member.type_annotation # invalid annotation should be ignored
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("INVALID_TYPE"), member.constant_name
        assert_equal "untyped", member.type.to_s # fallback for hash literal
        assert_nil member.type_annotation # invalid annotation should be ignored
      end
    end
  end

  def test_parse__constant_declaration_various_name_formats
    result = parse(<<~RUBY)
      class NameFormats
        # Various valid Ruby constant name formats
        SCREAMING_SNAKE_CASE = 1
        CamelCase = 2
        PascalCase = 3
        XMLParser = 4
        HTTPClient = 5
        HTML5Parser = 6
        A = 7
        Z9 = 8
        MixedCASE_123 = 9
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("NameFormats"), decl.class_name

      # All 9 constant declarations should be parsed successfully
      assert_equal 9, decl.members.size

      expected_names = [
        "SCREAMING_SNAKE_CASE", "CamelCase", "PascalCase",
        "XMLParser", "HTTPClient", "HTML5Parser",
        "A", "Z9", "MixedCASE_123"
      ]

      decl.members.each_with_index do |member, i|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse(expected_names[i]), member.constant_name
        assert_equal "::Integer", member.type.to_s
      end
    end
  end

  def test_error__constant_declaration_non_constant_path
    result = parse(<<~RUBY)
      class TestClass
        # Dynamic constant path assignments should generate diagnostics
        (c = Object)::FOO = 123
        self::BAR = "hello"
        variable::BAZ = true
        method_call()::QUX = nil
      end
    RUBY

    # Should have diagnostics for each non-constant path
    assert_equal 4, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantConstantDeclaration, diagnostic
      assert_equal "(c = Object)::FOO", diagnostic.location.source
      assert_equal "Constant name must be a constant", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantConstantDeclaration, diagnostic
      assert_equal "self::BAR", diagnostic.location.source
      assert_equal "Constant name must be a constant", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantConstantDeclaration, diagnostic
      assert_equal "variable::BAZ", diagnostic.location.source
      assert_equal "Constant name must be a constant", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::NonConstantConstantDeclaration, diagnostic
      assert_equal "method_call()::QUX", diagnostic.location.source
      assert_equal "Constant name must be a constant", diagnostic.message
    end
  end

  def test_parse__constant_path_write_node
    result = parse(<<~RUBY)
      module Outer
        Foo::BAR = 123
        ::TopLevel::VALUE = true
      end
    RUBY

    # Should have no diagnostics for valid constant paths
    assert_equal 0, result.diagnostics.size

    # Should parse the module
    assert_equal 1, result.declarations.size
    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, decl
      assert_equal RBS::TypeName.parse("Outer"), decl.module_name

      assert_equal 2, decl.members.size

      # Check first constant: Foo::BAR = 123 #: Integer
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("Foo::BAR"), member.constant_name
        assert_equal "::Integer", member.type.to_s
      end

      # Check third constant: ::TopLevel::VALUE = true #: bool
      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::ConstantDecl, member
        assert_equal RBS::TypeName.parse("::TopLevel::VALUE"), member.constant_name
        assert_equal "bool", member.type.to_s
      end
    end
  end

  def test_parse__class_alias_without_type_name
    result = parse(<<~RUBY)
      MyString = String #: class-alias
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassModuleAliasDecl, decl
      assert_equal RBS::TypeName.parse("MyString"), decl.new_name
      assert_equal RBS::TypeName.parse("String"), decl.infered_old_name
      assert_instance_of RBS::AST::Ruby::Annotations::ClassAliasAnnotation, decl.annotation
      assert_nil decl.annotation.type_name
      assert_equal RBS::TypeName.parse("String"), decl.old_name
      assert_nil decl.leading_comment
    end
  end

  def test_parse__class_alias_with_type_name
    result = parse(<<~RUBY)
      # Alias for the standard Object class
      MyObject = some_object #: class-alias Object
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassModuleAliasDecl, decl
      assert_equal RBS::TypeName.parse("MyObject"), decl.new_name
      assert_nil decl.infered_old_name
      assert_instance_of RBS::AST::Ruby::Annotations::ClassAliasAnnotation, decl.annotation
      assert_equal RBS::TypeName.parse("Object"), decl.annotation.type_name
      assert_equal RBS::TypeName.parse("Object"), decl.old_name
      assert_equal "Alias for the standard Object class", decl.leading_comment.as_comment.string
    end
  end

  def test_parse__module_alias_without_type_name
    result = parse(<<~RUBY)
      MyKernel = Kernel #: module-alias
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassModuleAliasDecl, decl
      assert_equal RBS::TypeName.parse("MyKernel"), decl.new_name
      assert_equal RBS::TypeName.parse("Kernel"), decl.infered_old_name
      assert_instance_of RBS::AST::Ruby::Annotations::ModuleAliasAnnotation, decl.annotation
      assert_nil decl.annotation.type_name
      assert_equal RBS::TypeName.parse("Kernel"), decl.old_name
      assert_nil decl.leading_comment
    end
  end

  def test_parse__module_alias_with_type_name
    result = parse(<<~RUBY)
      # Alias for Enumerable module
      MyEnum = some_enumerable #: module-alias Enumerable
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassModuleAliasDecl, decl
      assert_equal RBS::TypeName.parse("MyEnum"), decl.new_name
      assert_nil decl.infered_old_name
      assert_instance_of RBS::AST::Ruby::Annotations::ModuleAliasAnnotation, decl.annotation
      assert_equal RBS::TypeName.parse("Enumerable"), decl.annotation.type_name
      assert_equal RBS::TypeName.parse("Enumerable"), decl.old_name
      assert_equal "Alias for Enumerable module", decl.leading_comment.as_comment.string
    end
  end

  def test_parse__class_alias_with_skip_annotation
    result = parse(<<~RUBY)
      # @rbs skip
      MyString = String #: class-alias
    RUBY

    assert_empty result.diagnostics

    assert_equal 0, result.declarations.size
  end

  def test_error__class_alias_non_constant_without_type_name
    result = parse(<<~RUBY)
      MyString = some_function() #: class-alias
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::ClassModuleAliasDeclarationMissingTypeName, diagnostic
      assert_equal ": class-alias", diagnostic.location.source
      assert_equal "Class name is missing in class alias declaration", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_error__module_alias_non_constant_without_type_name
    result = parse(<<~RUBY)
      MyModule = some_function() #: module-alias
    RUBY

    assert_equal 1, result.diagnostics.size
    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::ClassModuleAliasDeclarationMissingTypeName, diagnostic
      assert_equal ": module-alias", diagnostic.location.source
      assert_equal "Module name is missing in module alias declaration", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_parse__visibility_public_private
    result = parse(<<~RUBY)
      class Foo
        private

        def private_method
        end

        public

        def public_method
        end
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      assert_equal 4, decl.members.size

      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PrivateMember, member
        assert_equal "private", member.location.source
      end

      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_equal :private_method, member.name
      end

      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PublicMember, member
        assert_equal "public", member.location.source
      end

      decl.members[3].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member
        assert_equal :public_method, member.name
      end
    end
  end

  def test_error__visibility_toplevel
    result = parse(<<~RUBY)
      private

      public
    RUBY

    # Should have errors for top-level visibility declarations
    assert_equal 2, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelVisibilityDeclaration, diagnostic
      assert_equal "private", diagnostic.location.source
      assert_equal "Top-level visibility declaration is not supported", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::TopLevelVisibilityDeclaration, diagnostic
      assert_equal "public", diagnostic.location.source
      assert_equal "Top-level visibility declaration is not supported", diagnostic.message
    end

    assert_empty result.declarations
  end

  def test_error__visibility_with_arguments
    result = parse(<<~RUBY)
      class Foo
        private :method1

        public :method2
      end
    RUBY

    # This should generate diagnostics because visibility with arguments is not supported
    assert_equal 2, result.diagnostics.size

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::VisibilityCallWithArguments, diagnostic
      assert_equal ":method1", diagnostic.location.source
      assert_equal "Visibility methods with arguments are not supported", diagnostic.message
    end

    assert_any!(result.diagnostics) do |diagnostic|
      assert_instance_of RBS::InlineParser::Diagnostic::VisibilityCallWithArguments, diagnostic
      assert_equal ":method2", diagnostic.location.source
      assert_equal "Visibility methods with arguments are not supported", diagnostic.message
    end

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      assert_empty decl.members
    end
  end

  def test_parse__visibility_def_syntax
    result = parse(<<~RUBY)
      class Foo
        private def hello = "hello"
        
        public def world = "world"
        
        # @rbs (String) -> String
        private def greet(name) = "Hello \#{name}!"
      end
    RUBY

    assert_empty result.diagnostics

    result.declarations[0].tap do |decl|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, decl
      assert_equal RBS::TypeName.parse("Foo"), decl.class_name

      assert_equal 3, decl.members.size

      # private def hello
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PrivateDefMember, member
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member.member
        assert_equal :hello, member.member.name
        assert_equal "hello", member.member.name_location.source
      end

      # public def world
      decl.members[1].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PublicDefMember, member
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member.member
        assert_equal :world, member.member.name
        assert_equal "world", member.member.name_location.source
      end

      # private def greet with type annotation
      decl.members[2].tap do |member|
        assert_instance_of RBS::AST::Ruby::Members::PrivateDefMember, member
        assert_instance_of RBS::AST::Ruby::Members::DefMember, member.member
        assert_equal :greet, member.member.name
        assert_equal "greet", member.member.name_location.source
        
        # Check that the method has type annotation
        refute member.member.method_type.empty?
      end
    end
  end
end

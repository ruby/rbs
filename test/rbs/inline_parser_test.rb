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
    result.declarations[0].tap do |decl|
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
end

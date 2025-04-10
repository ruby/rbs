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
end

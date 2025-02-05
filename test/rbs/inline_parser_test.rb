require "test_helper"

class RBS::InlineParserTest < Test::Unit::TestCase
  def parse_ruby(source)
    [
      RBS::Buffer.new(name: "test.rb", content: source),
      Prism.parse(source)
    ]
  end

  def test_parse
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        def foo = 123
      end

      module Bar
        def self.bar = 123
      end

      class <<self
      end

      FOO = 123
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    pp ret
  end

  def test_parse__class_decl__super
    buffer, result = parse_ruby(<<~RUBY)
      class Foo < Object
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    pp ret.declarations[0]
  end

  def assert_any!(collection, &block)
    assert_block(build_message("No item passed the block", "?", collection)) do
      collection.each do |item|
        yield item
        return
      rescue Test::Unit::AssertionFailedError
        # skip
      end

      false
    end
  end

  def test_parse__class_decl__diagnostics__name
    buffer, result = parse_ruby(<<~RUBY)
      class (true && Object)::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "(true && Object)::Foo", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__class_decl__diagnostics__super
    buffer, result = parse_ruby(<<~RUBY)
      class Foo < c::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "c::Foo", _1.location.source
    end

    assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, ret.declarations[0]
  end

  def test_parse__class_decl__diagnostics__in_singleton
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          class Bar
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "Bar", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__singleton_class_decl__diagnostics__top_level
    buffer, result = parse_ruby(<<~RUBY)
      class <<self
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "<<self", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__singleton_class_decl__diagnostics__no_self
    buffer, result = parse_ruby(<<~RUBY)
      class <<Object
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "Object", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__singleton_class_decl__diagnostics__nested
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          class <<self
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "<<self", _1.location.source
    end

    assert_equal 1, ret.declarations.size
  end

  def test_parse__module_decl__no_const_name
    buffer, result = parse_ruby(<<~RUBY)
      module c::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "c::Foo", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__module_decl__inside_singleton_class
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          module Foo
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "Foo", _1.location.source
    end
  end

  def test_parse__private_public__diagnostics__outside_module
    buffer, result = parse_ruby(<<~RUBY)
      private
      public()
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "private", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "public", _1.location.source
    end
  end

  def test_parse__private_public__diagnostics__with_args
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        private :foo
        public(:bar)
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal ":foo", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal ":bar", _1.location.source
    end
  end

  def test_parse__private_public__diagnostics__with_receiver
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        Foo.private
        Bar.public
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "Foo", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "Bar", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__outside_module
    buffer, result = parse_ruby(<<~RUBY)
      include Foo
      extend Bar
      prepend Baz
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "include", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "prepend", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "extend", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__no_self_receiver
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        Bar.include Baz
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "Bar", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__arguments
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        include
        extend Bar, Baz
        prepend(*baz)
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "include", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "Bar, Baz", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "*baz", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__non_constant
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        include c
        extend c::Bar
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "c", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "c::Bar", _1.location.source
    end
  end
end

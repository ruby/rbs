require "test_helper"

class RBS::Environment::UseMapTest < Test::Unit::TestCase
  include TestHelper

  UseMap = RBS::Environment::UseMap
  Use = RBS::AST::Directives::Use

  attr_reader :map

  def setup
    super

    table = UseMap::Table.new()
    table.known_types << TypeName("::Foo")
    table.known_types << TypeName("::Foo::M")
    table.known_types << TypeName("::Foo::_I")
    table.known_types << TypeName("::Foo::a")
    table.compute_children()

    @map = UseMap.new(table: table)
  end

  def test_import_single_clause
    map.build_map(Use::SingleClause.new(type_name: TypeName("Foo::M"), new_name: nil, location: nil))
    map.build_map(Use::SingleClause.new(type_name: TypeName("Foo::_I"), new_name: :_FooI, location: nil))
    map.build_map(Use::SingleClause.new(type_name: TypeName("Foo::a"), new_name: :af, location: nil))

    assert_equal TypeName("::Foo::M"), map.resolve?(TypeName("M"))
    assert_equal TypeName("::Foo::_I"), map.resolve?(TypeName("_FooI"))
    assert_equal TypeName("::Foo::a"), map.resolve?(TypeName("af"))

    assert_nil map.resolve?(TypeName("::M"))
    assert_nil map.resolve?(TypeName("::_FooI"))
    assert_nil map.resolve?(TypeName("::af"))
  end

  def test_import_wildcard_clause
    map.build_map(Use::WildcardClause.new(namespace: Namespace("Foo::"), location: nil))

    assert_equal TypeName("::Foo::M"), map.resolve?(TypeName("M"))
    assert_equal TypeName("::Foo::_I"), map.resolve?(TypeName("_I"))
    assert_equal TypeName("::Foo::a"), map.resolve?(TypeName("a"))
  end

  def test_resolve_namespace
    map.build_map(Use::SingleClause.new(type_name: TypeName("Foo"), new_name: :Bar, location: nil))

    assert_equal TypeName("::Foo::M"), map.resolve?(TypeName("Bar::M"))
    assert_equal TypeName("::Foo::_I"), map.resolve?(TypeName("Bar::_I"))
    assert_equal TypeName("::Foo::a"), map.resolve?(TypeName("Bar::a"))
  end
end

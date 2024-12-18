require "test_helper"

class RBS::Environment::UseMapTest < Test::Unit::TestCase
  include TestHelper

  UseMap = RBS::Environment::UseMap
  Use = RBS::AST::Directives::Use

  attr_reader :map

  def setup
    super

    table = UseMap::Table.new()
    table.known_types << RBS::TypeName.parse("::Foo")
    table.known_types << RBS::TypeName.parse("::Foo::M")
    table.known_types << RBS::TypeName.parse("::Foo::_I")
    table.known_types << RBS::TypeName.parse("::Foo::a")
    table.compute_children()

    @map = UseMap.new(table: table)
  end

  def test_import_single_clause
    map.build_map(Use::SingleClause.new(type_name: RBS::TypeName.parse("Foo::M"), new_name: nil, location: nil))
    map.build_map(Use::SingleClause.new(type_name: RBS::TypeName.parse("Foo::_I"), new_name: :_FooI, location: nil))
    map.build_map(Use::SingleClause.new(type_name: RBS::TypeName.parse("Foo::a"), new_name: :af, location: nil))

    assert_equal RBS::TypeName.parse("::Foo::M"), map.resolve?(RBS::TypeName.parse("M"))
    assert_equal RBS::TypeName.parse("::Foo::_I"), map.resolve?(RBS::TypeName.parse("_FooI"))
    assert_equal RBS::TypeName.parse("::Foo::a"), map.resolve?(RBS::TypeName.parse("af"))

    assert_nil map.resolve?(RBS::TypeName.parse("::M"))
    assert_nil map.resolve?(RBS::TypeName.parse("::_FooI"))
    assert_nil map.resolve?(RBS::TypeName.parse("::af"))
  end

  def test_import_wildcard_clause
    map.build_map(Use::WildcardClause.new(namespace: RBS::Namespace.parse("Foo::"), location: nil))

    assert_equal RBS::TypeName.parse("::Foo::M"), map.resolve?(RBS::TypeName.parse("M"))
    assert_equal RBS::TypeName.parse("::Foo::_I"), map.resolve?(RBS::TypeName.parse("_I"))
    assert_equal RBS::TypeName.parse("::Foo::a"), map.resolve?(RBS::TypeName.parse("a"))
  end

  def test_resolve_namespace
    map.build_map(Use::SingleClause.new(type_name: RBS::TypeName.parse("Foo"), new_name: :Bar, location: nil))

    assert_equal RBS::TypeName.parse("::Foo::M"), map.resolve?(RBS::TypeName.parse("Bar::M"))
    assert_equal RBS::TypeName.parse("::Foo::_I"), map.resolve?(RBS::TypeName.parse("Bar::_I"))
    assert_equal RBS::TypeName.parse("::Foo::a"), map.resolve?(RBS::TypeName.parse("Bar::a"))
  end
end

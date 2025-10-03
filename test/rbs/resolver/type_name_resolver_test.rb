require "test_helper"

class RBS::Resolver::TypeNameResolverTest < Test::Unit::TestCase
  include TestHelper
  include RBS

  def test_resolve
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::Foo"), type_name("::Foo::Bar"), type_name("::Foo::Bar::Baz"), type_name("::Bar")],
      {}
    )

    assert_equal type_name("::Foo"),
                  resolver.resolve(type_name("::Foo"), context: nil)

    assert_equal type_name("::Foo"),
                  resolver.resolve(type_name("Foo"), context: nil)
    assert_equal type_name("::Bar"),
                  resolver.resolve(type_name("Bar"), context: nil)
    assert_nil resolver.resolve(type_name("Baz"), context: nil)

    assert_equal type_name("::Foo"),
                  resolver.resolve(type_name("Foo"), context: [nil, RBS::TypeName.parse("::Foo")])
    assert_equal type_name("::Foo::Bar"),
                  resolver.resolve(type_name("Bar"), context: [nil, RBS::TypeName.parse("::Foo")])
    assert_equal type_name("::Foo::Bar::Baz"),
                  resolver.resolve(type_name("Bar::Baz"), context: [nil, RBS::TypeName.parse("::Foo")])

    assert_equal type_name("::Bar"),
                  resolver.resolve(type_name("Bar"), context: [nil, RBS::TypeName.parse("::Foo::Bar::Baz")])
  end

  def test_resolve_failure
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::Foo"), type_name("::Foo::Foo"), type_name("::Foo::Bar")],
      {}
    )

    assert_nil resolver.resolve(type_name("Foo::Bar"), context: [[nil, RBS::TypeName.parse("::Foo")], RBS::TypeName.parse("::Foo::Foo")])
  end

  def test_duplicated_resolve
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::X"), type_name("::X::X")],
      {}
    )

    assert_equal type_name("::X::X"),
                  resolver.resolve(type_name("X"), context: [nil, RBS::TypeName.parse("::X")])
  end

  def test_top_resolve
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::X"), type_name("::X::Y"), type_name("::X::Y::Z"), type_name("::X::Y::Y")],
      {}
    )

    assert_equal type_name("::X::Y::Y"),
                  resolver.resolve(type_name("Y"),
                                  context: [[nil, RBS::TypeName.parse("::X::Y")], RBS::TypeName.parse("::X::Y::Z")])

    assert_nil resolver.resolve(type_name("Y::Z"),
                                context: [[nil, RBS::TypeName.parse("::X::Y")], RBS::TypeName.parse("::X::Y::Z")])

    assert_equal type_name("::X::Y::Z"),
                  resolver.resolve(type_name("Y::Z"),
                                  context: [[nil, RBS::TypeName.parse("::X")], RBS::TypeName.parse("::X::Y::Z")])
  end

  def test_object_name
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::MyObject"), type_name("::MyObject::name"), type_name("::MyObject::name2"), type_name("::Symbol"), type_name("::String")],
      {}
    )

    assert_equal type_name("::MyObject::name"),
                  resolver.resolve(type_name("name"), context: [nil, RBS::TypeName.parse("::MyObject")])
    assert_equal type_name("::MyObject::name2"),
                  resolver.resolve(type_name("name2"), context: [nil, RBS::TypeName.parse("::MyObject")])
  end

  def test_module_alias
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::MyObject"), type_name("::MyObject::name2"), type_name("::Symbol"), type_name("::foo")],
      {
        type_name("::Alias") => [type_name("::MyObject"), nil]
      }
    )

    assert_equal(
      type_name("::MyObject::name2"),
      resolver.resolve(type_name("Alias::name2"), context: nil)
    )
    assert_equal(
      type_name("::MyObject::name2"),
      resolver.resolve(type_name("Alias::name2"), context: [nil, type_name("::MyObject")])
    )
    assert_equal(
      type_name("::MyObject::name2"),
      resolver.resolve(type_name("name2"), context: [nil, type_name("::MyObject")])
    )
  end

  def test_module_alias2
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::M"), type_name("::M::N"), type_name("::M::N::O"), type_name("::C")],
      {
        type_name("::M::N2") => [type_name("N"), [nil, type_name("::M")]]
      }
    )

    assert_equal(
      type_name("::M::N"),
      resolver.resolve(type_name("M::N2"), context: [nil, RBS::TypeName.parse("::C")])
    )

    assert_equal(
      type_name("::M::N::O"),
      resolver.resolve(type_name("M::N2::O"), context: [nil, RBS::TypeName.parse("::C")])
    )
  end

  def test_module_alias_cyclic
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::M")],
      {
        type_name("::M::N1") => [type_name("N2"), [nil, type_name("::M")]],
        type_name("::M::N2") => [type_name("N3"), [nil, type_name("::M")]],
        type_name("::M::N3") => [type_name("N1"), [nil, type_name("::M")]]
      }
    )

    assert_nil resolver.resolve(type_name("M::N1"), context: nil)
    assert_nil resolver.resolve(type_name("M::N2"), context: nil)
    assert_nil resolver.resolve(type_name("M::N3"), context: nil)
  end

  def test_module_alias_to_out
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::M"), type_name("::M::M1")],
      {
        type_name("::M::N1") => [type_name("M"), nil],
        type_name("::M::N2") => [type_name("M"), nil],
      }
    )

    assert_equal type_name("::M::M1"), resolver.resolve(type_name("M::N1::N2::N1::N2::M1"), context: nil)
  end

  def test_module_alias_pocke
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::M"), type_name("::M::N"), type_name("::C")],
      {
        type_name("::M::N2") => [type_name("N"), [nil, type_name("::M")]],
      }
    )

    assert_equal type_name("::M::N"), resolver.resolve(type_name("M::N2"), context: [nil, type_name("::C")])
  end

  def test_module_alias_absolute
    resolver = Resolver::TypeNameResolver.new(
      Set[type_name("::M1"), type_name("::M2"), type_name("::Aliases")],
      {
        type_name("::Aliases::M1") => [type_name("::M1"), [nil, type_name("::Aliases")]],
        type_name("::Aliases::M2") => [type_name("::M2"), [nil, type_name("::Aliases")]],
      }
    )

    assert_equal type_name("::M2"), resolver.resolve(type_name("Aliases::M2"), context: nil)
    assert_equal type_name("::M2"), resolver.resolve(type_name("Aliases::M2"), context: [nil, type_name("::M1")])
  end
end

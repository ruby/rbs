require "test_helper"

class RBS::TypeNameResolverTest < Minitest::Test
  include TestHelper
  include RBS

  def test_resolve
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  class Bar
    class Baz
    end
  end
end

class Bar
end
EOF
      manager.build do |env|
        resolver = TypeNameResolver.from_env(env)

        assert_equal type_name("::Foo"),
                     resolver.resolve(type_name("::Foo"), context: [Namespace.root])

        assert_equal type_name("::Foo"),
                     resolver.resolve(type_name("Foo"), context: [Namespace.root])
        assert_equal type_name("::Bar"),
                     resolver.resolve(type_name("Bar"), context: [Namespace.root])
        assert_nil resolver.resolve(type_name("Baz"), context: [Namespace.root])

        assert_equal type_name("::Foo"),
                     resolver.resolve(type_name("Foo"), context: [Namespace.parse("::Foo"), Namespace.root])
        assert_equal type_name("::Foo::Bar"),
                     resolver.resolve(type_name("Bar"), context: [Namespace.parse("::Foo"), Namespace.root])
        assert_equal type_name("::Foo::Bar::Baz"),
                     resolver.resolve(type_name("Bar::Baz"), context: [Namespace.parse("::Foo"), Namespace.root])

        assert_equal type_name("::Bar"),
                     resolver.resolve(type_name("Bar"), context: [Namespace.parse("::Foo::Bar::Baz"), Namespace.root])
      end
    end
  end

  def test_duplicated_resolve
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class X
  class X
  end
end
EOF
      manager.build do |env|
        resolver = TypeNameResolver.from_env(env)

        assert_equal type_name("::X::X"),
                     resolver.resolve(type_name("X"), context: [Namespace.parse("::X")])
      end
    end
  end

  def test_top_resolve
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class X
  class Y
    class Z
    end

    class Y
    end
  end
end
EOF
      manager.build do |env|
        resolver = TypeNameResolver.from_env(env)

        assert_equal type_name("::X::Y::Y"),
                     resolver.resolve(type_name("Y"),
                                      context: [Namespace.parse("::X::Y::Z"),
                                                Namespace.parse("::X::Y")])

        assert_nil resolver.resolve(type_name("Y::Z"),
                                    context: [Namespace.parse("::X::Y::Z"),
                                              Namespace.parse("::X::Y")])

        assert_equal type_name("::X::Y::Z"),
                     resolver.resolve(type_name("Y::Z"),
                                      context: [Namespace.parse("::X::Y::Z"),
                                                Namespace.parse("::X"),
                                                Namespace.root])
      end
    end
  end

  def test_object_name
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class MyObject
  type name2 = ::Symbol
end

type MyObject::name = ::String
EOF
      manager.build do |env|
        resolver = TypeNameResolver.from_env(env)

        assert_equal type_name("::MyObject::name"),
                     resolver.resolve(type_name("name"), context: [Namespace.parse("::MyObject")])
        assert_equal type_name("::MyObject::name2"),
                     resolver.resolve(type_name("name2"), context: [Namespace.parse("::MyObject")])
      end
    end
  end
end

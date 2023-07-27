require "test_helper"

class TypeAliasDependencyTest < Test::Unit::TestCase
  include TestHelper

  include RBS

  def test_dependency
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
type foo = Integer

type bar = foo | String

type baz = bar | foo | Integer
      EOF

      manager.build do |env|
        alias_dependency = TypeAliasDependency.new(env: env)
        alias_dependency.transitive_closure()

        assert_equal Set[], alias_dependency.direct_dependencies[TypeName("::foo")]
        assert_equal Set[TypeName("::foo")], alias_dependency.direct_dependencies[TypeName("::bar")]
        assert_equal Set[TypeName("::foo"), TypeName("::bar")], alias_dependency.direct_dependencies[TypeName("::baz")]
      end
    end
  end

  def test_dependency__module_alias
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
  type foo = Integer

  type bar = Bar::foo
end

module Bar = Foo

type Foo::baz = Bar::bar | String
      EOF

      manager.build do |env|
        alias_dependency = TypeAliasDependency.new(env: env)
        alias_dependency.transitive_closure()

        assert_equal Set[], alias_dependency.direct_dependencies_of(TypeName("::Foo::foo"))
        assert_equal Set[], alias_dependency.direct_dependencies_of(TypeName("::Bar::foo"))
        assert_equal Set[TypeName("::Foo::foo")], alias_dependency.direct_dependencies_of(TypeName("::Foo::bar"))
        assert_equal Set[TypeName("::Foo::foo")], alias_dependency.direct_dependencies_of(TypeName("::Bar::bar"))
        assert_equal Set[TypeName("::Foo::bar")], alias_dependency.direct_dependencies_of(TypeName("::Foo::baz"))
        assert_equal Set[TypeName("::Foo::bar")], alias_dependency.direct_dependencies_of(TypeName("::Bar::baz"))

        assert_equal Set[], alias_dependency.dependencies_of(TypeName("::Foo::foo"))
        assert_equal Set[], alias_dependency.dependencies_of(TypeName("::Bar::foo"))
        assert_equal Set[TypeName("::Foo::foo")], alias_dependency.dependencies_of(TypeName("::Foo::bar"))
        assert_equal Set[TypeName("::Foo::foo")], alias_dependency.dependencies_of(TypeName("::Bar::bar"))
        assert_equal Set[TypeName("::Foo::foo"), TypeName("::Foo::bar")], alias_dependency.dependencies_of(TypeName("::Foo::baz"))
        assert_equal Set[TypeName("::Foo::foo"), TypeName("::Foo::bar")], alias_dependency.dependencies_of(TypeName("::Bar::baz"))
      end
    end
  end
end

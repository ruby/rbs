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

        assert_equal Set[], alias_dependency.direct_dependencies[RBS::TypeName.parse("::foo")]
        assert_equal Set[RBS::TypeName.parse("::foo")], alias_dependency.direct_dependencies[RBS::TypeName.parse("::bar")]
        assert_equal Set[RBS::TypeName.parse("::foo"), RBS::TypeName.parse("::bar")], alias_dependency.direct_dependencies[RBS::TypeName.parse("::baz")]
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

        assert_equal Set[], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Foo::foo"))
        assert_equal Set[], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Bar::foo"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo")], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Foo::bar"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo")], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Bar::bar"))
        assert_equal Set[RBS::TypeName.parse("::Foo::bar")], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Foo::baz"))
        assert_equal Set[RBS::TypeName.parse("::Foo::bar")], alias_dependency.direct_dependencies_of(RBS::TypeName.parse("::Bar::baz"))

        assert_equal Set[], alias_dependency.dependencies_of(RBS::TypeName.parse("::Foo::foo"))
        assert_equal Set[], alias_dependency.dependencies_of(RBS::TypeName.parse("::Bar::foo"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo")], alias_dependency.dependencies_of(RBS::TypeName.parse("::Foo::bar"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo")], alias_dependency.dependencies_of(RBS::TypeName.parse("::Bar::bar"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo"), RBS::TypeName.parse("::Foo::bar")], alias_dependency.dependencies_of(RBS::TypeName.parse("::Foo::baz"))
        assert_equal Set[RBS::TypeName.parse("::Foo::foo"), RBS::TypeName.parse("::Foo::bar")], alias_dependency.dependencies_of(RBS::TypeName.parse("::Bar::baz"))
      end
    end
  end
end

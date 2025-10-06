require "test_helper"

class TypeAliasRegularityTest < Test::Unit::TestCase
  include RBS
  include TestHelper

  def test_validate
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
type foo = Integer

type bar[T] = [bar[T], T, bar[T]]
            | nil

type baz[T] = baz[bar[T]]
            | nil
      EOF

      manager.build do |env|
        validator = TypeAliasRegularity.validate(env: env)

        refute_operator validator, :nonregular?, RBS::TypeName.parse("::foo")
        refute_operator validator, :nonregular?, RBS::TypeName.parse("::bar")

        assert_operator validator, :nonregular?, RBS::TypeName.parse("::baz")
        assert_equal(
          parse_type("::baz[::bar[T]]", variables: [:T]),
          validator.nonregular?(RBS::TypeName.parse("::baz")).nonregular_type
        )
      end
    end
  end

  def test_validate_mutual
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
type foo[T] = bar[T]

type bar[T] = baz[String | T]

type baz[T] = foo[Array[T]]
      EOF

      manager.build do |env|
        validator = TypeAliasRegularity.validate(env: env)

        assert_operator validator, :nonregular?, RBS::TypeName.parse("::foo")
        assert_equal(
          parse_type("::foo[Array[::String | T]]", variables: [:T]),
          validator.nonregular?(RBS::TypeName.parse("::foo")).nonregular_type
        )
      end
    end
  end

  def test_validate__module_aliases
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
end

module Bar = Foo

type Foo::foo = Integer

type Foo::bar[T] = [Foo::bar[T], T, Bar::bar[T]]
                 | nil

type Foo::baz[T] = Bar::baz[Foo::bar[T]]
                 | nil
      EOF

      manager.build do |env|
        validator = TypeAliasRegularity.validate(env: env)

        refute_operator validator, :nonregular?, RBS::TypeName.parse("::Foo::foo")
        refute_operator validator, :nonregular?, RBS::TypeName.parse("::Bar::foo")
        refute_operator validator, :nonregular?, RBS::TypeName.parse("::Foo::bar")
        refute_operator validator, :nonregular?, RBS::TypeName.parse("::Bar::bar")

        assert_operator validator, :nonregular?, RBS::TypeName.parse("::Foo::baz")
        assert_operator validator, :nonregular?, RBS::TypeName.parse("::Bar::baz")

        assert_equal(
          parse_type("::Foo::baz[::Foo::bar[T]]", variables: [:T]),
          validator.nonregular?(RBS::TypeName.parse("::Foo::baz")).nonregular_type
        )
      end
    end
  end
end

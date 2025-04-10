require "test_helper"

class ValidatorTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  Namespace = RBS::Namespace
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError

  def test_validate
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
class Array[A]
end

class String::Foo
end

class Foo
end

type Foo::Bar::Baz::t = Integer

type ty = String | Integer
      EOF

      manager.build do |env|
        root = nil

        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("::Foo"), context: root)
        validator.validate_type(parse_type("::String::Foo"), context: root)

        validator.validate_type(parse_type("Array[String]"), context: root)

        assert_raises InvalidTypeApplicationError do
          validator.validate_type(parse_type("Array"), context: root)
        end

        assert_raises InvalidTypeApplicationError do
          validator.validate_type(parse_type("Array[1,2,3]"), context: root)
        end

        validator.validate_type(parse_type("::ty"), context: root)

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("::ty2"), context: root)
        end

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("catcat"), context: root)
        end

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("::_NoSuchInterface"), context: root)
        end
      end
    end
  end

  def test_validate_recursive_type_alias
    SignatureManager.new do |manager|
      manager.add_file("bar.rbs", <<-EOF)
type x = x
type random = Float & Integer & random
type something = String | something | Integer

type x_1 = y
type y = z
type z = x_1

type test = test?

type i = String | Integer | i_1
type i_1 = Float | i_2 | String
type i_2 = string | i | Numeric

type u = String & Integer & u_1
type u_1 = Float & u_2 | String
type u_2 = string & u & Numeric
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)
        env.type_alias_decls.each do |name, decl|
          assert_raises RBS::RecursiveTypeAliasError do
            validator.validate_type_alias(entry: decl)
          end.tap do |error|
            assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
              #{error.message} (RBS::RecursiveTypeAliasError)

                #{decl.decl.location.source}
                #{"^" * decl.decl.location.source.length}
            DETAILED_MESSAGE
          end
        end
      end
    end
  end

  def test_recursive_type_aliases
    SignatureManager.new do |manager|
      manager.add_file("test.rbs", <<-EOF)
type x_2 = [x_2, x_2]
type test_1 = Array[Hash[test_1, String]]
class Bar
 type test_2 = Array[Hash[Integer, Hash[Integer, Bar::test_2]]]
end
type proc = ^(proc) -> proc
type record = { foo: record }
      EOF
      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        env.type_alias_decls.each do |name, entry|
          validator.validate_type_alias(entry: entry)
        end
      end
    end
  end

  def test_generic_type_aliases
    SignatureManager.new do |manager|
      manager.add_file("test.rbs", <<-EOF)
type foo[T] = [T, foo[T]]

type bar[T] = [bar[T?]]

type baz[out T] = ^(T) -> void
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type_alias(entry: env.type_alias_decls[type_name("::foo")])

        assert_raises RBS::NonregularTypeAliasError do
          validator.validate_type_alias(entry: env.type_alias_decls[type_name("::bar")])
        end.tap do |error|
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::NonregularTypeAliasError)

              type bar[T] = [bar[T?]]
              ^^^^^^^^^^^^^^^^^^^^^^^
          DETAILED_MESSAGE
        end

        assert_raises RBS::InvalidVarianceAnnotationError do
          validator.validate_type_alias(entry: env.type_alias_decls[type_name("::baz")])
        end
      end
    end
  end

  def test_generic_type_bound
    SignatureManager.new do |manager|
      manager.add_file("test.rbs", <<-EOF)
type foo[T < String, S < Array[T]] = [T, S]

type bar[T < _Foo[S], S < _Bar[T]] = nil
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type_alias(entry: env.type_alias_decls[type_name("::foo")])

        error = assert_raises(RBS::CyclicTypeParameterBound) do
          validator.validate_type_alias(entry: env.type_alias_decls[type_name("::bar")])
        end

        assert_equal error.type_name, RBS::TypeName.parse("::bar")
        assert_equal "[T < _Foo[S], S < _Bar[T]]", error.location.source
        assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
          #{error.message} (RBS::CyclicTypeParameterBound)

            type bar[T < _Foo[S], S < _Bar[T]] = nil
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^
        DETAILED_MESSAGE
      end
    end
  end

  def test_unchecked_type_alias
    SignatureManager.new do |manager|
      manager.add_file("test.rbs", <<-RBS)
class Foo[in A, out B]
end

type foo[unchecked out A, unchecked in B] = Foo[A, B]
      RBS

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type_alias(entry: env.type_alias_decls[type_name("::foo")])
      end
    end
  end

  def test_type_alias_unknown_type
    SignatureManager.new do |manager|
      manager.add_file("test.rbs", <<-RBS)
type foo = bar
      RBS

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        # No error is raised.
        validator.validate_type_alias(entry: env.type_alias_decls[type_name("::foo")])

        # Passing a block and validating the given type raises an error.
        assert_raises RBS::NoTypeFoundError do
          validator.validate_type_alias(entry: env.type_alias_decls[type_name("::foo")]) do |type|
            validator.validate_type(type, context: [])
          end
        end
      end
    end
  end

  def test_validate_class_alias
    SignatureManager.new do |manager|
      manager.add_file("bar.rbs", <<-EOF)
class Foo = Kernel

module Bar = NoSuchClass

class Baz = Baz
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        env.class_alias_decls[RBS::TypeName.parse("::Foo")].tap do |entry|
          assert_raises RBS::InconsistentClassModuleAliasError do
            validator.validate_class_alias(entry: entry)
          end.tap do |error|
            assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
              #{error.message} (RBS::InconsistentClassModuleAliasError)

                class Foo = Kernel
                ^^^^^^^^^^^^^^^^^^
            DETAILED_MESSAGE
          end
        end

        env.class_alias_decls[RBS::TypeName.parse("::Bar")].tap do |entry|
          assert_raises RBS::NoTypeFoundError do
            validator.validate_class_alias(entry: entry)
          end
        end

        env.class_alias_decls[RBS::TypeName.parse("::Baz")].tap do |entry|
          assert_raises RBS::CyclicClassAliasDefinitionError do
            validator.validate_class_alias(entry: entry)
          end.tap do |error|
            assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
              #{error.message} (RBS::CyclicClassAliasDefinitionError)

                class Baz = Baz
                ^^^^^^^^^^^^^^^
            DETAILED_MESSAGE
          end
        end
      end
    end
  end

  def test_validate_type__presence__module_alias_instance
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
end

module Bar = Foo

class Foo::Baz = Integer

type foo = Bar::Baz
      EOF

      manager.build do |env|
        root = nil

        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("Bar::Baz"), context: root)
      end
    end
  end

  def test_validate_type__presence__module_alias_singleton
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
end

module Bar = Foo

class Foo::Baz = Integer
      EOF

      manager.build do |env|
        root = nil

        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("singleton(Bar::Baz)"), context: root)
      end
    end
  end

  def test_validate_type__ality_module_alias
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
  type list[T] = nil | [T, list[T]]
end

module Bar = Foo
      EOF

      manager.build do |env|
        root = nil

        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("Bar::list[Bar]"), context: root)
      end
    end
  end

  def test_validate_type_alias__1
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
end

module Bar = Foo

class Baz = Numeric

type Foo::list[T < Baz] = nil | [T, Bar::list[T]]
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type_alias(entry: env.type_alias_decls[RBS::TypeName.parse("::Foo::list")])
      end
    end
  end

  def test_validate__generics_default
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
class A[T = String]
end

class Foo
  def foo: () -> A
end
      EOF

      manager.build do |env|
        root = nil

        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("::A"), context: root)
        validator.validate_type(parse_type("::A[Integer]"), context: root)
        assert_raises(RBS::InvalidTypeApplicationError) do
          validator.validate_type(parse_type("::A[Integer, untyped]"), context: root)
        end
      end
    end
  end

  def test_validate_type__variable
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
class Foo
  @foo: Nothing
  @bar: Integer

  self.@foo: Nothing
  self.@bar: Integer

  @@foo: Nothing
  @@bar: Integer
end
      EOF

      manager.build do |env|
        resolver = RBS::Resolver::TypeNameResolver.new(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        env.class_decls[RBS::TypeName.parse("::Foo")].primary_decl.members.tap do |members|
          members[0].tap do |member|
            assert_raises(RBS::NoTypeFoundError) do
              validator.validate_variable(member)
            end
          end

          members[1].tap do |member|
            validator.validate_variable(member)
          end

          members[2].tap do |member|
            assert_raises(RBS::NoTypeFoundError) do
              validator.validate_variable(member)
            end
          end

          members[3].tap do |member|
            validator.validate_variable(member)
          end

          members[4].tap do |member|
            assert_raises(RBS::NoTypeFoundError) do
              validator.validate_variable(member)
            end
          end

          members[5].tap do |member|
            validator.validate_variable(member)
          end
        end
      end
    end
  end
end

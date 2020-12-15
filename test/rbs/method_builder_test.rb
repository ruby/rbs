require "test_helper"

class RBS::MethodBuilderTest < Minitest::Test
  include TestHelper

  AST = RBS::AST
  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  MethodBuilder = RBS::DefinitionBuilder::MethodBuilder
  Definition = RBS::Definition
  BuiltinNames = RBS::BuiltinNames
  Types = RBS::Types
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError
  RecursiveAncestorError = RBS::RecursiveAncestorError
  SuperclassMismatchError = RBS::SuperclassMismatchError

  def test_instance_def
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def hello: () -> String
end

class Foo
  def hello: () -> Integer
           | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("::Foo"), methods.type

          methods.methods[:hello].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::MethodDefinition, hello.original
            assert_equal [parse_method_type("() -> ::String")], hello.original.types

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("() -> ::Integer")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_instance_attributes
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  attr_accessor symbol: Symbol
end

class Foo
  def symbol=: (Integer) -> void
             | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("::Foo"), methods.type

          methods.methods[:symbol].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::AttrAccessor, hello.original
            assert_equal parse_type("::Symbol"), hello.original.type
          end

          methods.methods[:symbol=].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::AttrAccessor, hello.original
            assert_equal parse_type("::Symbol"), hello.original.type

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("(::Integer) -> void")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_instance_alias
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[A, B]
  def bar: () -> String
         | ...

  alias bar foo
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("::Foo[A, B]", variables: [:A, :B]), methods.type

          methods.methods[:bar].tap do |bar|
            assert_instance_of MethodBuilder::Methods::Definition, bar

            assert_instance_of AST::Members::Alias, bar.original
            assert_equal :bar, bar.original.new_name

            assert_any!(bar.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal :bar, member.name
            end

            assert_equal [:public], bar.accessibilities
          end
        end
      end
    end
  end

  def test_singleton_def
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def self.hello: () -> String
end

class Foo
  def self.hello: () -> Integer
                | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_singleton(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("singleton(::Foo)"), methods.type

          methods.methods[:hello].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::MethodDefinition, hello.original
            assert_equal [parse_method_type("() -> ::String")], hello.original.types

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("() -> ::Integer")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_singleton_attributes
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  attr_accessor self.symbol: Symbol
end

class Foo
  def self.symbol=: (Integer) -> void
                  | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_singleton(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("singleton(::Foo)"), methods.type

          methods.methods[:symbol].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::AttrAccessor, hello.original
            assert_equal parse_type("::Symbol"), hello.original.type
          end

          methods.methods[:symbol=].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::AttrAccessor, hello.original
            assert_equal parse_type("::Symbol"), hello.original.type

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("(::Integer) -> void")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_singleton_alias
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[A, B]
  def self.bar: () -> String
              | ...

  alias self.bar self.foo
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_singleton(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("singleton(::Foo)"), methods.type

          methods.methods[:bar].tap do |bar|
            assert_instance_of MethodBuilder::Methods::Definition, bar

            assert_instance_of AST::Members::Alias, bar.original
            assert_equal :bar, bar.original.new_name

            assert_any!(bar.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal :bar, member.name
            end

            assert_equal [:public], bar.accessibilities
          end
        end
      end
    end
  end

  def test_interface_def
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _Foo
  def hello: () -> String

  def hello: () -> Integer
           | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_interface(type_name("::_Foo")).tap do |methods|
          assert_equal parse_type("::_Foo"), methods.type

          methods.methods[:hello].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::MethodDefinition, hello.original
            assert_equal [parse_method_type("() -> ::String")], hello.original.types

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("() -> ::Integer")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_interface_alias
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _Foo
  def hello: () -> String

  alias world hello

  def world: () -> Integer
           | ...
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_interface(type_name("::_Foo")).tap do |methods|
          assert_equal parse_type("::_Foo"), methods.type

          methods.methods[:world].tap do |hello|
            assert_instance_of MethodBuilder::Methods::Definition, hello

            assert_instance_of AST::Members::Alias, hello.original
            assert_equal :hello, hello.original.old_name

            assert_any!(hello.overloads, size: 1) do |member|
              assert_instance_of AST::Members::MethodDefinition, member
              assert_equal [parse_method_type("() -> ::Integer")], member.types
            end

            assert_equal :public, hello.accessibility
          end
        end
      end
    end
  end

  def test_methods_alias_def_error
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[A, B]
  def bar: () -> String

  alias bar foo
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        exn = assert_raises RBS::DuplicatedMethodDefinitionError do
          builder.build_instance(type_name("::Foo"))
        end

        assert_equal parse_type("::Foo[A, B]", variables: [:A, :B]), exn.type
        assert_equal :bar, exn.method_name
      end
    end
  end

  def test_methods_each
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[A, B]
  def foo: () -> String
  alias bar foo
  alias baz bar
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("::Foo[A, B]", variables: [:A, :B]), methods.type

          assert_equal [:foo, :bar, :baz], methods.each.to_a.map(&:name)
        end
      end
    end
  end

  def test_methods_each_error
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[A, B]
  alias bar foo
  alias baz bar
  alias foo baz
end
EOF
      manager.build do |env|
        builder = MethodBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |methods|
          assert_equal parse_type("::Foo[A, B]", variables: [:A, :B]), methods.type

          exn = assert_raises RBS::RecursiveAliasDefinitionError do
            methods.each.to_a
          end

          assert_equal Set[:foo, :bar, :baz], Set.new(exn.defs.map(&:name))
        end
      end
    end
  end
end

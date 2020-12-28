require "test_helper"

class RBS::AncestorBuilderTest < Test::Unit::TestCase
  include TestHelper

  AST = RBS::AST
  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  DefinitionBuilder = RBS::DefinitionBuilder
  Definition = RBS::Definition
  Ancestor = Definition::Ancestor
  BuiltinNames = RBS::BuiltinNames
  Types = RBS::Types
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError
  RecursiveAncestorError = RBS::RecursiveAncestorError
  SuperclassMismatchError = RBS::SuperclassMismatchError

  def test_one_ancestors_class
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module Foo[X]
end

module Bar[X]
end

interface _Baz[X]
end

class Hello[X] < Array[Integer]
  prepend Foo[X]

  include Bar[X]
  include _Baz[X]

  extend Foo[String]
  extend _Baz[String]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_equal [:X], a.params
          assert_equal Ancestor::Instance.new(name: type_name("::Array"), args: [parse_type("::Integer")], source: nil),
                       a.super_class
          assert_equal [Ancestor::Instance.new(name: type_name("::Bar"), args: [parse_type("X", variables: [:X])], source: nil)],
                       a.included_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::_Baz"), args: [parse_type("X", variables: [:X])], source: nil)],
                       a.included_interfaces
          assert_equal [
                         Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("X", variables: [:X])], source: nil),
                       ], a.prepended_modules
          assert_nil a.extended_modules
          assert_nil a.extended_interfaces
          assert_nil a.self_types
        end

        builder.one_singleton_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_nil a.params

          assert_equal Ancestor::Singleton.new(name: type_name("::Array")),
                       a.super_class
          assert_nil a.included_modules
          assert_nil a.included_interfaces
          assert_nil a.prepended_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("::String")], source: nil)],
                       a.extended_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::_Baz"), args: [parse_type("::String")], source: nil)],
                       a.extended_interfaces
          assert_nil a.self_types
        end
      end
    end
  end

  def test_one_ancestors_module
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module M1[X]
end

module M2[X]
end

interface _I1[X]
end

interface _I2[X]
end

module Hello[X] : _I1[Array[X]]
  prepend M1[X]

  include M2[X]
  include _I2[X]

  extend M1[String]
  extend _I1[String]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_equal [:X], a.params
          assert_nil a.super_class
          assert_equal [
                         Ancestor::Instance.new(name: type_name("::_I1"), args: [parse_type("::Array[X]", variables: [:X])], source: nil)
                       ],
                       a.self_types
          assert_equal [Ancestor::Instance.new(name: type_name("::M2"), args: [parse_type("X", variables: [:X])], source: nil)],
                       a.included_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::_I2"), args: [parse_type("X", variables: [:X])], source: nil)],
                       a.included_interfaces
          assert_equal [
                         Ancestor::Instance.new(name: type_name("::M1"), args: [parse_type("X", variables: [:X])], source: nil),
                       ],
                       a.prepended_modules
          assert_nil a.extended_modules
        end

        builder.one_singleton_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_nil a.params
          assert_equal Ancestor::Instance.new(name: type_name("::Module"), args: [], source: nil),
                       a.super_class
          assert_nil a.self_types
          assert_nil a.included_modules
          assert_nil a.prepended_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::M1"), args: [parse_type("::String")], source: nil)],
                       a.extended_modules
          assert_equal [Ancestor::Instance.new(name: type_name("::_I1"), args: [parse_type("::String")], source: nil)],
                       a.extended_interfaces
        end
      end
    end
  end

  def test_one_ancestors_module_no_self_type
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module M
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::M")).tap do |a|
          assert_equal type_name("::M"), a.type_name
          assert_equal [], a.params
          assert_nil a.super_class
          assert_equal [Ancestor::Instance.new(name: type_name("::Object"), args: [], source: nil)],
                       a.self_types
        end
      end
    end
  end

  def test_one_ancestors_interface
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
end

interface _I2[X]
  include _I1[Array[X]]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_interface_ancestors(type_name("::_I1")).tap do |a|
          assert_equal type_name("::_I1"), a.type_name
          assert_equal [:X], a.params
          assert_nil a.super_class
          assert_nil a.self_types
          assert_nil a.included_modules
          assert_equal [], a.included_interfaces
          assert_nil a.prepended_modules
          assert_nil a.extended_modules
          assert_nil a.extended_interfaces
        end

        builder.one_interface_ancestors(type_name("::_I2")).tap do |a|
          assert_equal type_name("::_I2"), a.type_name
          assert_equal [:X], a.params
          assert_nil a.super_class
          assert_nil a.self_types
          assert_nil a.included_modules
          assert_equal [
                         Ancestor::Instance.new(
                           name: type_name("::_I1"),
                           args: [parse_type("::Array[X]", variables: [:X])],
                           source: nil
                         )
                       ],
                       a.included_interfaces
          assert_nil a.prepended_modules
          assert_nil a.extended_modules
          assert_nil a.extended_interfaces
        end
      end
    end
  end

  def test_one_ancestors_basic_object
    SignatureManager.new(system_builtin: true) do |manager|
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal [], a.params
          assert_nil a.super_class
          assert_empty a.included_modules
          assert_empty a.prepended_modules
        end

        builder.one_singleton_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal Ancestor::Instance.new(name: type_name("::Class"), args: [], source: nil), a.super_class
          assert_empty a.extended_modules
        end
      end
    end
  end

  def test_instance_ancestors
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[X] < ::Object
end

class Foo[A]
  include Bar[A, String]
end

module Bar[Y, Z]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.instance_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Ancestor::Instance.new(
                           name: BuiltinNames::BasicObject.name,
                           args: [],
                           source: nil)
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Kernel")).tap do |a|
          assert_equal type_name("::Kernel"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Ancestor::Instance.new(
                           name: BuiltinNames::Kernel.name,
                           args: [],
                           source: nil
                         )
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Object")).tap do |a|
          assert_equal type_name("::Object"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil)
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::String")).tap do |a|
          assert_equal type_name("::String"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Ancestor::Instance.new(name: BuiltinNames::String.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Comparable.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil)
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [:X], a.params
          assert_equal [
                         Ancestor::Instance.new(name: type_name("::Foo"), args: [Types::Variable.build(:X)], source: nil),
                         Ancestor::Instance.new(name: type_name("::Bar"), args: [Types::Variable.build(:X), parse_type("::String")], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil)
                       ],
                       a.ancestors
        end
      end
    end
  end

  def test_instance_ancestors_super_class_validation
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class A < String
end

class A < Object
end

class B
end

class B < String
end

class B < ::String
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        # ::A is invalid.
        error = assert_raises SuperclassMismatchError do
          builder.instance_ancestors(type_name("::A"))
        end
        assert_equal error.name, type_name("::A")

        # ::B is valid.
        builder.instance_ancestors(type_name("::B"))
      end
    end
  end

  def test_singleton_ancestors
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo[X] < ::Object
end

class Foo[A]
  include Bar[A, String]
  extend Bar[String, Symbol]
end

module Bar[Y, Z]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.singleton_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal [
                         Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Ancestor::Instance.new(name: BuiltinNames::Class.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Module.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Object")).tap do |a|
          assert_equal type_name("::Object"), a.type_name
          assert_equal [
                         Ancestor::Singleton.new(name: BuiltinNames::Object.name),
                         Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Ancestor::Instance.new(name: BuiltinNames::Class.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Module.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Kernel")).tap do |a|
          assert_equal type_name("::Kernel"), a.type_name
          assert_equal [
                         Ancestor::Singleton.new(name: BuiltinNames::Kernel.name),
                         Ancestor::Instance.new(name: BuiltinNames::Module.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [
                         Ancestor::Singleton.new(name: type_name("::Foo")),
                         Ancestor::Instance.new(name: type_name("::Bar"), args: [parse_type("::String"), parse_type("::Symbol")], source: nil),
                         Ancestor::Singleton.new(name: BuiltinNames::Object.name),
                         Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Ancestor::Instance.new(name: BuiltinNames::Class.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Module.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [], source: nil),
                         Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [], source: nil),
                       ], a.ancestors
        end
      end
    end
  end

  def test_interface_ancestors
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
end

interface _I2[X, Y]
  include _I1[Hash[X, Y]]
end

interface _I3[X]
  include _I2[Integer, X]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.interface_ancestors(type_name("::_I3")).tap do |a|
          assert_instance_of Definition::InstanceAncestors, a
          assert_equal type_name("::_I3"), a.type_name
          assert_equal [:X], a.params
          assert_equal [
                         Ancestor::Instance.new(name: type_name("::_I3"), args: [parse_type("X", variables: [:X])], source: nil),
                         Ancestor::Instance.new(name: type_name("::_I2"), args: [parse_type("::Integer"), parse_type("X", variables: [:X])], source: nil),
                         Ancestor::Instance.new(name: type_name("::_I1"), args: [parse_type("::Hash[::Integer, X]", variables: [:X])], source: nil)
                       ],
                       a.ancestors
        end
      end
    end
  end

  def test_build_ancestors_cycle
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module X[A]
  include Y[A]
end

module Y[A]
  include X[Array[A]]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        assert_raises(RecursiveAncestorError) do
          builder.instance_ancestors(type_name("::X"))
        end
      end
    end
  end

  def test_build_invalid_type_application
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module X[A]
end

class Y[A, B]
end

class A < Y

end

class B < Y[Integer, void]
  include X
end

class C
  extend X
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        assert_raises InvalidTypeApplicationError do
          builder.instance_ancestors(type_name("::A"))
        end

        assert_raises InvalidTypeApplicationError do
          builder.instance_ancestors(type_name("::B"))
        end

        assert_raises InvalidTypeApplicationError do
          builder.singleton_ancestors(type_name("::C"))
        end
      end
    end
  end
end

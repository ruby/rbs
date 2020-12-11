require "test_helper"

class RBS::AncestorBuilderTest < Minitest::Test
  include TestHelper

  AST = RBS::AST
  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  DefinitionBuilder = RBS::DefinitionBuilder
  Definition = RBS::Definition
  BuiltinNames = RBS::BuiltinNames
  Types = RBS::Types
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError
  RecursiveAncestorError = RBS::RecursiveAncestorError
  SuperclassMismatchError = RBS::SuperclassMismatchError

  def test_one_ancestors
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module Foo[X]
end

interface _Bar[X, Y]
end

class Hello[X] < Array[Integer]
  prepend Foo[Integer]
  include _Bar[X, Integer]

  extend Foo[String]
  extend _Bar[String, String]
end

module World[X] : Array[String]
  prepend Foo[Integer]
  include _Bar[X, Integer]

  extend Foo[String]
  extend _Bar[String, String]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal [], a.params
          assert_nil a.super_class
          assert_empty a.included_modules
          assert_empty a.prepended_modules
        end

        builder.one_instance_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_equal [:X], a.params
          assert_equal Definition::Ancestor::Instance.new(name: type_name("::Array"), args: [parse_type("::Integer")]), a.super_class
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::_Bar"),
                                                            args: [
                                                              parse_type("X", variables: [:X]),
                                                              parse_type("::Integer")
                                                            ])
                       ],
                       a.included_modules
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("::Integer")]),
                       ],
                       a.prepended_modules
        end

        builder.one_instance_ancestors(type_name("::World")).tap do |a|
          assert_equal type_name("::World"), a.type_name
          assert_equal [:X], a.params
          assert_equal [Definition::Ancestor::Instance.new(name: type_name("::Array"), args: [parse_type("::String")])],
                       a.self_types
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::_Bar"),
                                                            args: [
                                                              parse_type("X", variables: [:X]),
                                                              parse_type("::Integer")
                                                            ])
                       ],
                       a.included_modules
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("::Integer")]),
                       ],
                       a.prepended_modules
        end

        builder.one_singleton_ancestors(type_name("::BasicObject")).tap do |a|
          assert_equal type_name("::BasicObject"), a.type_name
          assert_equal Definition::Ancestor::Instance.new(name: type_name("::Class"), args: []), a.super_class
          assert_empty a.extended_modules
        end

        builder.one_singleton_ancestors(type_name("::Hello")).tap do |a|
          assert_equal type_name("::Hello"), a.type_name
          assert_equal Definition::Ancestor::Singleton.new(name: type_name("::Array")), a.super_class
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("::String")]),
                         Definition::Ancestor::Instance.new(name: type_name("::_Bar"), args: [parse_type("::String"), parse_type("::String")])
                       ],
                       a.extended_modules
        end

        builder.one_singleton_ancestors(type_name("::World")).tap do |a|
          assert_equal type_name("::World"), a.type_name
          assert_equal Definition::Ancestor::Instance.new(name: type_name("::Module"), args: []), a.super_class
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [parse_type("::String")]),
                         Definition::Ancestor::Instance.new(name: type_name("::_Bar"), args: [parse_type("::String"), parse_type("::String")])
                       ],
                       a.extended_modules
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
          assert_equal [Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Kernel")).tap do |a|
          assert_equal type_name("::Kernel"), a.type_name
          assert_equal [], a.params
          assert_equal [Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [])],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Object")).tap do |a|
          assert_equal type_name("::Object"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::String")).tap do |a|
          assert_equal type_name("::String"), a.type_name
          assert_equal [], a.params
          assert_equal [
                         Definition::Ancestor::Instance.new(name: BuiltinNames::String.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Comparable.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])
                       ],
                       a.ancestors
        end

        builder.instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [:X], a.params
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [Types::Variable.build(:X)]),
                         Definition::Ancestor::Instance.new(name: type_name("::Bar"), args: [Types::Variable.build(:X), parse_type("::String")]),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])
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
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Class.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Object")).tap do |a|
          assert_equal type_name("::Object"), a.type_name
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::Object.name),
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Class.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Kernel")).tap do |a|
          assert_equal type_name("::Kernel"), a.type_name
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::Kernel.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], a.ancestors
        end

        builder.singleton_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: type_name("::Foo")),
                         Definition::Ancestor::Instance.new(name: type_name("::Bar"), args: [parse_type("::String"), parse_type("::Symbol")]),
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::Object.name),
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Class.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], a.ancestors
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

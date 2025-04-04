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
  MixinClassError = RBS::MixinClassError

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

          assert_equal 3, a.ancestors.size
          a.ancestors[0].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_nil ancestor.source
          end
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
        end

        builder.instance_ancestors(type_name("::String")).tap do |a|
          assert_equal type_name("::String"), a.type_name
          assert_equal [], a.params

          assert_equal 5, a.ancestors.size
          a.ancestors[0].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::String.name, ancestor.name
            assert_equal [], ancestor.args
            assert_nil ancestor.source
          end
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Comparable.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[3].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
        end

        builder.instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [:X], a.params

          assert_equal 5, a.ancestors.size
          a.ancestors[0].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal RBS::TypeName.parse("::Foo"), ancestor.name
            assert_equal [Types::Variable.build(:X)], ancestor.args
            assert_nil ancestor.source
          end
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal RBS::TypeName.parse("::Bar"), ancestor.name
            assert_equal [Types::Variable.build(:X), parse_type("::String")], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[3].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
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

          assert_equal 6, a.ancestors.size
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name), a.ancestors[0]
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Class.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Module.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[3].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[5].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
        end

        builder.singleton_ancestors(type_name("::Object")).tap do |a|
          assert_equal type_name("::Object"), a.type_name

          assert_equal 7, a.ancestors.size
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::Object.name), a.ancestors[0]
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name), a.ancestors[1]
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Class.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[3].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Module.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[5].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[6].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
        end

        builder.singleton_ancestors(type_name("::Kernel")).tap do |a|
          assert_equal type_name("::Kernel"), a.type_name

          assert_equal 5, a.ancestors.size
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::Kernel.name), a.ancestors[0]
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Module.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[3].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
        end

        builder.singleton_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name

          assert_equal 9, a.ancestors.size
          assert_equal Ancestor::Singleton.new(name: type_name("::Foo")), a.ancestors[0]
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::Bar"), ancestor.name
            assert_equal [parse_type("::String"), parse_type("::Symbol")], ancestor.args
            assert_instance_of AST::Members::Extend, ancestor.source
          end
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::Object.name), a.ancestors[2]
          assert_equal Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name), a.ancestors[3]
          a.ancestors[4].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Class.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[5].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Module.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[6].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Object.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
          a.ancestors[7].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::Kernel.name, ancestor.name
            assert_equal [], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[8].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal BuiltinNames::BasicObject.name, ancestor.name
            assert_equal [], ancestor.args
            assert_equal :super, ancestor.source
          end
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

          assert_equal 3, a.ancestors.size
          a.ancestors[0].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_I3"), ancestor.name
            assert_equal [parse_type("X", variables: [:X])], ancestor.args
            assert_nil ancestor.source
          end
          a.ancestors[1].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_I2"), ancestor.name
            assert_equal [parse_type("::Integer"), parse_type("X", variables: [:X])], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          a.ancestors[2].tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_I1"), ancestor.name
            assert_equal [parse_type("::Hash[::Integer, X]", variables: [:X])], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
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

class D
end

class E < D[Integer]
end

module F : D[Integer]
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

        assert_raises InvalidTypeApplicationError do
          builder.instance_ancestors(type_name("::E"))
        end

        assert_raises InvalidTypeApplicationError do
          builder.instance_ancestors(type_name("::F"))
        end
      end
    end
  end

  def test_invalid_mixin_include
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def foo: () -> untyped
end

class Qux
  include Foo
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        assert_raises MixinClassError do
          builder.instance_ancestors(type_name("::Qux"))
        end.tap do |error|
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::MixinClassError)

                include Foo
                ^^^^^^^^^^^
          DETAILED_MESSAGE
        end
      end
    end
  end

  def test_invalid_mixin_perpend
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def foo: () -> untyped
end

class Qux
  prepend Foo
end
EOF

  manager.build do |env|
        manager.build do |env|
          builder = DefinitionBuilder::AncestorBuilder.new(env: env)

          assert_raises MixinClassError do
            builder.instance_ancestors(type_name("::Qux"))
          end.tap do |error|
            assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
              #{error.message} (RBS::MixinClassError)

                  prepend Foo
                  ^^^^^^^^^^^
            DETAILED_MESSAGE
          end
        end
      end
    end
  end

  def test_invalid_mixin_extend
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def foo: () -> untyped
end

class Qux
  extend Foo
end
EOF

  manager.build do |env|
        manager.build do |env|
          builder = DefinitionBuilder::AncestorBuilder.new(env: env)

          assert_raises MixinClassError do
            builder.one_singleton_ancestors(type_name("::Qux"))
          end.tap do |error|
            assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
              #{error.message} (RBS::MixinClassError)

                  extend Foo
                  ^^^^^^^^^^
            DETAILED_MESSAGE
          end
        end
      end
    end
  end

  def test_alias_class_instance_ancestor
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        class Super
        end

        class SuperAlias = Super

        module M1
        end

        module M1Alias = M1

        module M2
        end

        module M2Alias = M2

        class Foo < SuperAlias
          include M1Alias
          prepend M2Alias
        end

        class Bar = Foo
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        as = builder.one_instance_ancestors(type_name("::Bar"))

        assert_instance_of DefinitionBuilder::AncestorBuilder::OneAncestors, as

        assert_equal type_name("::Foo"), as.type_name
        assert_equal type_name("::Super"), as.super_class.name
        assert_equal [type_name("::M1")], as.included_modules.map(&:name)
        assert_equal [type_name("::M2")], as.prepended_modules.map(&:name)
      end
    end
  end

  def test_alias_class_singleton_ancestor
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        class Super
        end

        class SuperAlias = Super

        module M1
        end

        module M1Alias = M1

        class Foo < SuperAlias
          extend M1Alias
        end

        class Bar = Foo
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        as = builder.one_singleton_ancestors(type_name("::Bar"))

        assert_instance_of DefinitionBuilder::AncestorBuilder::OneAncestors, as

        assert_equal type_name("::Foo"), as.type_name
        assert_equal type_name("::Super"), as.super_class.name
        assert_equal [type_name("::M1")], as.extended_modules.map(&:name)
      end
    end
  end

  def test_alias_module_instance_ancestor
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        module M1
        end

        module M1Alias = M1

        module M2
        end

        module M2Alias = M2

        module M3
        end

        module M3Alias = M3

        module M : M1Alias
          include M2Alias
          prepend M3Alias
        end

        module MAlias = M
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        as = builder.one_instance_ancestors(type_name("::MAlias"))

        assert_instance_of DefinitionBuilder::AncestorBuilder::OneAncestors, as

        assert_equal type_name("::M"), as.type_name
        assert_equal [type_name("::M1")], as.self_types.map(&:name)
        assert_equal [type_name("::M2")], as.included_modules.map(&:name)
        assert_equal [type_name("::M3")], as.prepended_modules.map(&:name)
      end
    end
  end

  def test_alias_module_singleton_ancestor
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        module Aliases
          module M1 = ::M1

          module M2 = ::M2
        end

        module M1
          extend Aliases::M2
        end

        module M2 end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        as = builder.one_singleton_ancestors(type_name("::Aliases::M1"))

        assert_instance_of DefinitionBuilder::AncestorBuilder::OneAncestors, as

        assert_equal type_name("::M1"), as.type_name
        assert_equal [type_name("::M2")], as.extended_modules.map(&:name)
      end
    end
  end

  def test_instance_ancestors__generic_default
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class A[T = String]
end

module B[S = Integer]
end

module C[T = bool]
end

class Foo < A
  include B
  prepend C
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [], a.params

          ancestors = a.ancestors.dup

          ancestors.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::C"), ancestor.name
            assert_equal [parse_type("bool")], ancestor.args
            assert_instance_of AST::Members::Prepend, ancestor.source
          end
          ancestors.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::Foo"), ancestor.name
            assert_equal [], ancestor.args
            assert_nil ancestor.source
          end
          ancestors.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::B"), ancestor.name
            assert_equal [parse_type("::Integer")], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end
          ancestors.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::A"), ancestor.name
            assert_equal [parse_type("::String")], ancestor.args
            assert_equal :super, ancestor.source
          end
        end
      end
    end
  end

  def test_one_singleton_ancestors__generic_default
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module A[T = String]
end

interface _B[T = Integer]
end

class Foo
  extend A
  extend _B
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_singleton_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name

          extended_modules = a.extended_modules.dup
          extended_modules.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::A"), ancestor.name
            assert_equal [parse_type("::String")], ancestor.args
            assert_instance_of AST::Members::Extend, ancestor.source
          end

          extended_interfaces = a.extended_interfaces.dup
          extended_interfaces.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_B"), ancestor.name
            assert_equal [parse_type("::Integer")], ancestor.args
            assert_instance_of AST::Members::Extend, ancestor.source
          end
        end
      end
    end
  end

  def test_one_instance_ancestors__generic_default
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class A[T = String]
end

module B[S = Integer]
end

module C[T = Symbol]
end

interface _D[T = untyped]
end

class Foo < A
  include B
  prepend C
  include _D
end

module Bar : A, _D
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name

          a.super_class.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::A"), ancestor.name
            assert_equal [parse_type("::String")], ancestor.args
            assert_equal :super, ancestor.source
          end

          included_modules = a.included_modules.dup
          included_modules.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::B"), ancestor.name
            assert_equal [parse_type("::Integer")], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end

          included_interfaces = a.included_interfaces.dup
          included_interfaces.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_D"), ancestor.name
            assert_equal [parse_type("untyped")], ancestor.args
            assert_instance_of AST::Members::Include, ancestor.source
          end

          prepended_modules = a.prepended_modules.dup
          prepended_modules.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::C"), ancestor.name
            assert_equal [parse_type("::Symbol")], ancestor.args
            assert_instance_of AST::Members::Prepend, ancestor.source
          end
        end

        builder.one_instance_ancestors(type_name("::Bar")).tap do |a|
          assert_equal type_name("::Bar"), a.type_name

          self_types = a.self_types.dup
          self_types.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::A"), ancestor.name
            assert_equal [parse_type("::String")], ancestor.args
            assert_instance_of AST::Declarations::Module::Self, ancestor.source
          end
          self_types.shift.tap do |ancestor|
            assert_instance_of Ancestor::Instance, ancestor
            assert_equal type_name("::_D"), ancestor.name
            assert_equal [parse_type("untyped")], ancestor.args
            assert_instance_of AST::Declarations::Module::Self, ancestor.source
          end
        end
      end
    end
  end

  def test__one_ancestors__class__ruby
    SignatureManager.new(system_builtin: true) do |manager|

      manager.ruby_files[Pathname("lib/foo.rb")] = <<~EOF
        class Foo
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder::AncestorBuilder.new(env: env)

        builder.one_instance_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_equal [], a.params

          assert_equal Ancestor::Instance.new(name: type_name("::Object"), args: [], source: :super), a.super_class
          assert_equal [],
                       a.included_modules
          assert_equal [],
                       a.included_interfaces
          assert_equal [], a.prepended_modules
          assert_nil a.extended_modules
          assert_nil a.extended_interfaces
          assert_nil a.self_types
        end

        builder.one_singleton_ancestors(type_name("::Foo")).tap do |a|
          assert_equal type_name("::Foo"), a.type_name
          assert_nil a.params

          assert_equal Ancestor::Singleton.new(name: type_name("::Object")), a.super_class
          assert_nil a.included_modules
          assert_nil a.included_interfaces
          assert_nil a.prepended_modules
          assert_equal [],
                       a.extended_modules
          assert_equal [],
                       a.extended_interfaces
          assert_nil a.self_types
        end
      end
    end
  end
end

require "test_helper"

class RBS::DefinitionBuilderTest < Minitest::Test
  include TestHelper

  AST = RBS::AST
  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  Declarations = RBS::AST::Declarations
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  DefinitionBuilder = RBS::DefinitionBuilder
  Definition = RBS::Definition
  BuiltinNames = RBS::BuiltinNames
  Types = RBS::Types
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError
  UnknownMethodAliasError = RBS::UnknownMethodAliasError
  InvalidVarianceAnnotationError = RBS::InvalidVarianceAnnotationError

  def assert_method_definition(method, types, accessibility: nil)
    assert_instance_of Definition::Method, method
    assert_equal types, method.method_types.map(&:to_s)
    assert_equal accessibility, method.accessibility if accessibility
    yield method.super if block_given?
  end

  def assert_ivar_definitioin(ivar, type)
    assert_instance_of Definition::Variable, ivar
    assert_equal parse_type(type), ivar.type
  end

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
        builder = DefinitionBuilder.new(env: env)

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
        builder = DefinitionBuilder.new(env: env)

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
        builder = DefinitionBuilder.new(env: env)

        # ::A is invalid.
        error = assert_raises RBS::SuperclassMismatchError do
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
        builder = DefinitionBuilder.new(env: env)

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
        builder = DefinitionBuilder.new(env: env)

        assert_raises do
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
        builder = DefinitionBuilder.new(env: env)

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

  def test_build_interface
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _Foo
  def bar: -> _Foo
  include _Hash
end

interface _Hash
  def hash: -> Integer
  def eql?: (untyped) -> bool
end

interface _Baz
  include _Hash[bool]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        foo = type_name("::_Foo")
        baz = type_name("::_Baz")

        builder.build_interface(foo).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:bar, :hash, :eql?].sort, definition.methods.keys.sort

          assert_method_definition definition.methods[:bar], ["() -> ::_Foo"], accessibility: :public
          assert_method_definition definition.methods[:hash], ["() -> ::Integer"], accessibility: :public
          assert_method_definition definition.methods[:eql?], ["(untyped) -> bool"], accessibility: :public
        end

        assert_raises InvalidTypeApplicationError do
          builder.build_interface(baz)
        end
      end
    end
  end

  def test_method_definition_members
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Foo
  def foo: () -> void
end

class Foo
  private
  def bar: () -> Foo
end

class Bar
  def foo: () -> String
end

module Baz
  class ::Bar
    def foo: (Integer) -> String | ...
  end

  class String
  end
end

class VisibilityError
  public
  def foo: () -> void

  private
  def foo: () -> void | ...
end

class InvalidOverloadError
  def foo: () -> void | ...
end

interface _TestInterface
  def test1: () -> String
  def test2: () -> Integer
end

class UsingTestInterface
  include _TestInterface

  def test2: (Integer) -> String | ...
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        env.class_decls[type_name("::Foo")].tap do |entry|
          methods = builder.method_definition_members(type_name("::Foo"), entry, kind: :instance)

          assert_operator methods, :key?, :foo
          methods[:foo].tap do |foo|
            assert_equal :public, foo[0]
            assert_nil foo[1]
            assert_equal [parse_method_type("() -> void")], foo[2].types
          end

          assert_operator methods, :key?, :bar
          methods[:bar].tap do |bar|
            assert_equal :private, bar[0]
            assert_nil bar[1]
            assert_equal [parse_method_type("() -> ::Foo")], bar[2].types
          end
        end

        env.class_decls[type_name("::Bar")].tap do |entry|
          methods = builder.method_definition_members(type_name("::Bar"), entry, kind: :instance)

          assert_operator methods, :key?, :foo
          methods[:foo].tap do |foo|
            assert_equal :public, foo[0]
            assert_nil foo[1]
            assert_equal [parse_method_type("() -> ::String")], foo[2].types
            assert_equal [parse_method_type("(::Integer) -> ::Baz::String")], foo[3].types
          end
        end

        env.class_decls[type_name("::VisibilityError")].tap do |entry|
          error = assert_raises RBS::InconsistentMethodVisibilityError do
            builder.method_definition_members(type_name("::VisibilityError"), entry, kind: :instance)
          end

          assert_equal type_name("::VisibilityError"), error.type_name
          assert_equal :foo, error.method_name
          assert_equal :instance, error.kind
          assert_equal 2, error.member_pairs.size
        end

        env.class_decls[type_name("::InvalidOverloadError")].tap do |entry|
          # Only overloading `...` method definitions (without non-overloading) is allowed
          builder.method_definition_members(type_name("::InvalidOverloadError"), entry, kind: :instance)
        end

        env.class_decls[type_name("::UsingTestInterface")].tap do |entry|
          methods = builder.method_definition_members(type_name("::UsingTestInterface"), entry, kind: :instance)

          methods[:test1].tap do |test1|
            assert_equal :public, test1[0]

            assert_instance_of Definition::Method, test1[1]
            assert_equal [parse_method_type("() -> ::String")], test1[1].method_types
          end

          methods[:test2].tap do |test2|
            assert_equal :public, test2[0]

            assert_instance_of Definition::Method, test2[1]
            assert_equal [parse_method_type("() -> ::Integer")], test2[1].method_types

            assert_instance_of AST::Members::MethodDefinition, test2[2]
            assert_equal [parse_method_type("(::Integer) -> ::String")], test2[2].types
          end
        end
      end
    end
  end

  def test_build_one_instance_methods
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  # doc1
  %a{hello}
  def foo: () -> String
         | (Integer) -> String
end

class Hello
  # doc2
  %a{world}
  def foo: (String) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          foo = definition.methods[:foo]

          assert_nil foo.super_method
          assert_equal [parse_method_type("(::String) -> ::String"),
                        parse_method_type("() -> ::String"),
                        parse_method_type("(::Integer) -> ::String")], foo.method_types
          assert_equal type_name("::Hello"), foo.defined_in
          assert_equal type_name("::Hello"), foo.implemented_in
          assert_includes foo.annotations, AST::Annotation.new(string: "hello", location: nil)
          assert_includes foo.annotations, AST::Annotation.new(string: "world", location: nil)
          assert_includes foo.comments, AST::Comment.new(string: "doc1\n", location: nil)
          assert_includes foo.comments, AST::Comment.new(string: "doc2\n", location: nil)
        end
      end
    end
  end

  def test_build_one_instance_interface_methods
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _Hello
  def hello: () -> String
end

class Hello
  include _Hello

  def hello: (Integer) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          hello = definition.methods[:hello]

          assert_nil hello.super_method
          assert_equal [parse_method_type("(::Integer) -> ::String"),
                        parse_method_type("() -> ::String")], hello.method_types
          assert_equal type_name("::_Hello"), hello.defined_in
          assert_equal type_name("::Hello"), hello.implemented_in
        end
      end
    end
  end

  def test_build_one_instance_attributes
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  attr_writer name: String
end

class Hello
  attr_reader email (): String?
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          definition.methods[:name=].tap do |name|
            assert_nil name.super_method
            assert_equal [parse_method_type("(::String name) -> ::String")], name.method_types
            assert_equal type_name("::Hello"), name.defined_in
            assert_equal type_name("::Hello"), name.implemented_in
          end

          definition.instance_variables[:@name].tap do |name|
            assert_nil name.parent_variable
            assert_equal parse_type("::String"), name.type
            assert_equal type_name("::Hello"), name.declared_in
          end

          definition.methods[:email].tap do |email|
            assert_nil email.super_method
            assert_equal [parse_method_type("() -> ::String?")], email.method_types
            assert_equal type_name("::Hello"), email.defined_in
            assert_equal type_name("::Hello"), email.implemented_in
          end

          refute_operator definition.instance_variables, :key?, :@email
        end
      end
    end
  end

  def test_build_one_instance_alias
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  alias mail_address email
end

class Hello
  attr_reader email (): String?
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          definition.methods[:email].tap do |email|
            assert_nil email.super_method
            assert_equal [parse_method_type("() -> ::String?")], email.method_types
            assert_equal type_name("::Hello"), email.defined_in
            assert_equal type_name("::Hello"), email.implemented_in
          end

          definition.methods[:mail_address].tap do |mail_address|
            assert_nil mail_address.super_method
            assert_equal [parse_method_type("() -> ::String?")], mail_address.method_types
            assert_equal type_name("::Hello"), mail_address.defined_in
            assert_equal type_name("::Hello"), mail_address.implemented_in
          end
        end
      end
    end
  end

  def test_build_one_instance_method_variance
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class A[out X, unchecked out Y]
  def foo: () -> X
  def bar: (X) -> void
  def baz: (Y) -> void
end

class B[in X, unchecked in Y]
  def foo: (X) -> void
  def bar: () -> X
  def baz: () -> Y
end

class C[Z]
  def foo: (Z) -> Z
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises(InvalidVarianceAnnotationError) { builder.build_one_instance(type_name("::A")) }.tap do |error|
          assert_equal [
                         InvalidVarianceAnnotationError::MethodTypeError.new(
                           method_name: :bar,
                           method_type: parse_method_type("(X) -> void", variables: [:X]),
                           param: Declarations::ModuleTypeParams::TypeParam.new(name: :X, variance: :covariant, skip_validation: false)
                         )
                       ], error.errors
        end
        assert_raises(InvalidVarianceAnnotationError) { builder.build_one_instance(type_name("::B")) }.tap do|error|
          assert_equal [
                         InvalidVarianceAnnotationError::MethodTypeError.new(
                           method_name: :bar,
                           method_type: parse_method_type("() -> X", variables: [:X]),
                           param: Declarations::ModuleTypeParams::TypeParam.new(name: :X, variance: :contravariant, skip_validation: false)
                         )
                       ], error.errors
        end
        builder.build_one_instance(type_name("::C"))
      end
    end
  end

  def test_build_one_instance_variance_inheritance
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Base[out X]
end

class A[out X] < Base[X]
end

class B[in X] < Base[X]
end

class C[X] < Base[X]
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::A"))
        builder.build_one_instance(type_name("::C"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_one_instance(type_name("::B")) }.tap do|error|
          assert_equal [
                         InvalidVarianceAnnotationError::InheritanceError.new(
                           param: Declarations::ModuleTypeParams::TypeParam.new(name: :X, variance: :contravariant, skip_validation: false)
                         )
                       ], error.errors
        end
      end
    end
  end

  def test_build_one_instance_mixin
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
module M[out X]
end

class A[out X]
  include M[X]
end

class B[in X]
  include M[X]
end

class C[X]
  include M[X]
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::A"))
        builder.build_one_instance(type_name("::C"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_one_instance(type_name("::B")) }.tap do|error|
          assert_equal [
                         InvalidVarianceAnnotationError::MixinError.new(
                           include_member: ::Object.new.tap {|x| x.define_singleton_method(:==) {|x| true } },
                           param: Declarations::ModuleTypeParams::TypeParam.new(name: :X, variance: :contravariant, skip_validation: false)
                         )
                       ], error.errors
        end
      end
    end
  end

  def test_build_one_instance_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
  @name: A
  @@count: Integer
  self.@email: String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition

          assert_equal [:@name].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@name].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("A", variables: [:A]), variable.type
          end

          assert_equal [:@@count].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@count].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::Integer"), variable.type
          end
        end
      end
    end
  end

  def test_build_one_singleton_methods
    SignatureManager.new do |manager|
      manager.files[Pathname("hello.rbs")] = <<EOF
class Hello
  def self.foo: () -> Hello

  def self.bar: () -> String
end

class Hello
  def self.bar: (Symbol) -> String | ...
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_singleton(type_name("::Hello")).yield_self do |definition|
          definition.methods[:foo].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal [parse_method_type("() -> ::Hello")], method.method_types
            assert_equal type_name("::Hello"), method.defined_in
            assert_equal type_name("::Hello"), method.implemented_in
          end

          definition.methods[:bar].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal [parse_method_type("(::Symbol) -> ::String"), parse_method_type("() -> ::String")], method.method_types
            assert_equal type_name("::Hello"), method.defined_in
            assert_equal type_name("::Hello"), method.implemented_in
          end
        end
      end
    end
  end

  def test_build_one_singleton_extend_interface_methods
    SignatureManager.new do |manager|
      manager.files[Pathname("hello.rbs")] = <<EOF
interface _Helloable[A]
  def hello: () -> A
  def world: () -> A
end

class Hello
  extend _Helloable[Integer]
end

class Hello
  def self.world: (Symbol) -> Integer | ...
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_singleton(type_name("::Hello")).yield_self do |definition|
          definition.methods[:hello].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal [parse_method_type("() -> ::Integer")], method.method_types
            assert_equal type_name("::_Helloable"), method.defined_in
            assert_equal type_name("::Hello"), method.implemented_in
          end

          definition.methods[:world].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal [parse_method_type("(::Symbol) -> ::Integer"), parse_method_type("() -> ::Integer")], method.method_types
            assert_equal type_name("::_Helloable"), method.defined_in
            assert_equal type_name("::Hello"), method.implemented_in
          end
        end
      end
    end
  end

  def test_build_one_singleton_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
  @name: A
  @@count: Integer
  self.@email: String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:@email].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@email].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
          end

          assert_equal [:@@count].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@count].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::Integer"), variable.type
          end
        end
      end
    end
  end

  def test_build_instance
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(BuiltinNames::Object.name).yield_self do |definition|
          assert_equal Set.new([:__id__, :initialize, :puts, :respond_to_missing?, :to_i]), Set.new(definition.methods.keys)

          definition.methods[:__id__].yield_self do |method|
            assert_method_definition method, ["() -> ::Integer"], accessibility: :public
          end

          definition.methods[:initialize].yield_self do |method|
            assert_method_definition method, ["() -> void"], accessibility: :private
          end

          definition.methods[:puts].yield_self do |method|
            assert_method_definition method, ["(*untyped) -> nil"], accessibility: :private
          end

          definition.methods[:respond_to_missing?].yield_self do |method|
            assert_method_definition method, ["(::Symbol, bool) -> bool"], accessibility: :private
          end
        end
      end
    end
  end

  def test_build_instance_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
  @name: A
  @@email: String
end

class Foo < Hello[String]
end

class Bar < Foo
  @name: String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Bar")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:@name].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@name].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal type_name("::Bar"), variable.declared_in
            assert_equal type_name("::Hello"), variable.parent_variable.declared_in
          end

          assert_equal [:@@email].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@email].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal type_name("::Hello"), variable.declared_in
          end
        end
      end
    end
  end

  def test_build_singleton
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(BuiltinNames::BasicObject.name).yield_self do |definition|
          assert_equal ["() -> ::BasicObject"], definition.methods[:new].method_types.map {|x| x.to_s }
        end

        builder.build_singleton(BuiltinNames::String.name).yield_self do |definition|
          assert_equal ["() -> ::String"], definition.methods[:new].method_types.map {|x| x.to_s }
        end
      end
    end
  end

  def test_build_singleton_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  self.@name: Integer
  @@email: String
end

class Foo < Hello
end

class Bar < Foo
  self.@name: String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::Bar")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:@name].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@name].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal type_name("::Bar"), variable.declared_in
            assert_equal type_name("::Hello"), variable.parent_variable.declared_in
          end

          assert_equal [:@@email].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@email].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal type_name("::Hello"), variable.declared_in
          end
        end
      end
    end
  end

  def test_build_alias
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  def foo: (String) -> void
  alias bar foo
end

interface _World
  def hello: () -> bool
  alias world hello
end

class Error
  alias self.xxx self.yyy
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:foo], ["(::String) -> void"]
          assert_method_definition definition.methods[:bar], ["(::String) -> void"]
        end

        builder.build_interface(type_name("::_World")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:hello], ["() -> bool"]
          assert_method_definition definition.methods[:world], ["() -> bool"]
        end

        assert_raises UnknownMethodAliasError do
          builder.build_singleton(type_name("::Error"))
        end
      end
    end
  end

  def test_build_one_module_instance
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _Each[A, B]
  def each: { (A) -> void } -> B
end

module Enumerable2[X, Y] : _Each[X, Y]
  def count: -> Integer
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Enumerable2")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:count, :each], definition.methods.keys.sort
          assert_method_definition definition.methods[:count], ["() -> ::Integer"]
          assert_method_definition definition.methods[:each], ["() { (X) -> void } -> Y"]
        end
      end
    end
  end

  def test_build_singleton_module
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _Each[A, B]
  def each: { (A) -> void } -> B
end

module Enumerable2[X, Y] : _Each[X, Y]
  def count: -> Integer
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::Enumerable2")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:__id__, :initialize, :puts, :respond_to_missing?, :to_i], definition.methods.keys.sort
          assert_method_definition definition.methods[:__id__], ["() -> ::Integer"]
          assert_method_definition definition.methods[:initialize], ["() -> void"]
          assert_method_definition definition.methods[:puts], ["(*untyped) -> nil"]
          assert_method_definition definition.methods[:respond_to_missing?], ["(::Symbol, bool) -> bool"]
        end
      end
    end
  end

  def test_attributes
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  attr_reader instance_reader: String
  attr_writer instance_writer(@writer): Integer
  attr_accessor instance_accessor(): Symbol
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:instance_reader], ["() -> ::String"]
          assert_ivar_definitioin definition.instance_variables[:@instance_reader], "::String"

          assert_method_definition definition.methods[:instance_writer=], ["(::Integer instance_writer) -> ::Integer"]
          assert_ivar_definitioin definition.instance_variables[:@writer], "::Integer"

          assert_method_definition definition.methods[:instance_accessor], ["() -> ::Symbol"]
          assert_method_definition definition.methods[:instance_accessor=], ["(::Symbol instance_accessor) -> ::Symbol"]
          assert_nil definition.instance_variables[:@instance_accessor]
        end
      end
    end
  end

  def test_initialize_new
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  def initialize: (String) -> void
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:initialize], ["(::String) -> void"]
        end

        builder.build_one_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::String) -> instance"]
        end
      end
    end
  end

  def test_initialize_new_generic
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
  def initialize: [X] () { (X) -> A } -> void
  def get: () -> A
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:initialize], ["[X] () { (X) -> A } -> void"]
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:new], ["[A, X] () { (X) -> A } -> ::Hello[A]"]
        end
      end
    end
  end

  def test_initialize_new_generic_empty
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:initialize], ["() -> void"]
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:new], ["() -> ::Hello[untyped]"]
        end
      end
    end
  end

  def test_initialize_new_generic_rename
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello[A]
  def initialize: [A] () { (A) -> void } -> void
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:initialize], ["[A] () { (A) -> void } -> void"]
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          definition.methods[:new].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal 1, method.method_types.size
            # [A, A@1] () { (A@1) -> void } -> ::Hello[A]
            assert_match(/\A\[A, A@(\d+)\] \(\) { \(A@\1\) -> void } -> ::Hello\[A\]\Z/, method.method_types[0].to_s)
          end
        end
      end
    end
  end

  def test_build_alias_forward
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  alias foo bar
  def bar: () -> Integer

  alias self.hoge self.huga
  def self.huga: () -> void
end

interface _Person
  alias first_name name
  def name: () -> String
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:foo], ["() -> ::Integer"]
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:hoge], ["() -> void"]
        end

        interface_name = type_name("::_Person")
        builder.build_interface(interface_name).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:first_name], ["() -> ::String"]
        end
      end
    end
  end

  def test_definition_method_type_def
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  # doc1
  %a{hello}
  def foo: () -> String
         | (Integer) -> String
end

class Hello
  # doc2
  %a{world}
  def foo: (String) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          foo = definition.methods[:foo]

          assert_nil foo.super_method
          assert_equal [parse_method_type("(::String) -> ::String"),
                        parse_method_type("() -> ::String"),
                        parse_method_type("(::Integer) -> ::String")], foo.method_types
          assert_equal type_name("::Hello"), foo.defined_in
          assert_equal type_name("::Hello"), foo.implemented_in
          assert_includes foo.annotations, AST::Annotation.new(string: "hello", location: nil)
          assert_includes foo.annotations, AST::Annotation.new(string: "world", location: nil)
          assert_includes foo.comments, AST::Comment.new(string: "doc1\n", location: nil)
          assert_includes foo.comments, AST::Comment.new(string: "doc2\n", location: nil)

          assert_equal 3, foo.defs.size

          foo.defs[0].tap do |defn|
            assert_equal parse_method_type("(::String) -> ::String"), defn.type
            assert_equal "doc2\n", defn.comment.string
            assert_equal ["world"], defn.annotations.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[1].tap do |defn|
            assert_equal parse_method_type("() -> ::String"), defn.type
            assert_equal "doc1\n", defn.comment.string
            assert_equal ["hello"], defn.annotations.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[2].tap do |defn|
            assert_equal parse_method_type("(::Integer) -> ::String"), defn.type
            assert_equal "doc1\n", defn.comment.string
            assert_equal ["hello"], defn.annotations.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end
        end
      end
    end
  end

  def test_definition_method_type_def_interface
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _Hello
  # _Hello#foo
  %a{_Hello#foo}
  def foo: () -> String
end

class Hello
  include _Hello

  # Hello#foo
  %a{Hello#foo}
  def foo: (Integer) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).tap do |definition|
          foo = definition.methods[:foo]

          assert_nil foo.super_method
          assert_equal [parse_method_type("(::Integer) -> ::String"),
                        parse_method_type("() -> ::String")], foo.method_types

          assert_equal 2, foo.defs.size

          foo.defs[0].tap do |defn|
            assert_equal parse_method_type("(::Integer) -> ::String"), defn.type
            assert_equal "Hello#foo\n", defn.comment.string
            assert_equal ["Hello#foo"], defn.annotations.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[1].tap do |defn|
            assert_equal parse_method_type("() -> ::String"), defn.type
            assert_equal "_Hello#foo\n", defn.comment.string
            assert_equal ["_Hello#foo"], defn.annotations.map(&:string)
            assert_equal type_name("::_Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end
        end
      end
    end
  end

  def test_build_with_unknown_super_class
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class A < B
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        error = assert_raises RBS::NoSuperclassFoundError do
          builder.build_instance(type_name("::A"))
        end
        assert_equal type_name("B"), error.type_name

        assert_raises RBS::NoSuperclassFoundError do
          builder.build_singleton(type_name("::A"))
        end
      end
    end
  end

  def test_build_instance_with_unknown_mixin
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class A
  include _Foo
end

class C
  extend Bar
end

class D
  prepend Baz
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises RBS::NoMixinFoundError do
          builder.build_instance(type_name("::A"))
        end.tap do |error|
          assert_equal type_name("_Foo"), error.type_name
          assert_instance_of RBS::AST::Members::Include, error.member
        end

        assert_raises RBS::NoMixinFoundError do
          builder.build_singleton(type_name("::C"))
        end.tap do |error|
          assert_equal type_name("Bar"), error.type_name
        end

        assert_raises RBS::NoMixinFoundError do
          builder.build_instance(type_name("::D"))
        end.tap do |error|
          assert_equal type_name("Baz"), error.type_name
        end
      end
    end
  end

  def test_build_absent_namespace
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello::World
end

interface Hello::_World
end

type Hello::world = 30
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises RBS::NoTypeFoundError do
          builder.build_instance(type_name("::Hello::World"))
        end

        assert_raises RBS::NoTypeFoundError do
          builder.build_singleton(type_name("::Hello::World"))
        end

        assert_raises RBS::NoTypeFoundError do
          builder.build_interface(type_name("::Hello::_World"))
        end

        assert_raises RBS::NoTypeFoundError do
          builder.expand_alias(type_name("::Hello::world"))
        end
      end
    end
  end

  def test_definition_method_type_def_overload_from_super
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class World
  def foo: () -> String
end

class Hello < World
  def foo: (Integer) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          foo = definition.methods[:foo]
          assert_equal ["(::Integer) -> ::String", "() -> ::String"], foo.method_types.map(&:to_s)
        end
      end
    end
  end

  def test_definition_method_type_def_overload_from_super_no_super
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  def foo: (Integer) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises RBS::InvalidOverloadMethodError do
          builder.build_instance(type_name("::Hello"))
        end
      end
    end
  end
end

require "test_helper"

class Ruby::Signature::DefinitionBuilderTest < Minitest::Test
  include TestHelper

  Environment = Ruby::Signature::Environment
  EnvironmentLoader = Ruby::Signature::EnvironmentLoader
  Declarations = Ruby::Signature::AST::Declarations
  TypeName = Ruby::Signature::TypeName
  Namespace = Ruby::Signature::Namespace
  DefinitionBuilder = Ruby::Signature::DefinitionBuilder
  Definition = Ruby::Signature::Definition
  BuiltinNames = Ruby::Signature::BuiltinNames
  Types = Ruby::Signature::Types

  class SignatureManager
    attr_reader :files

    def initialize
      @files = {}

      files[Pathname("builtin.rbi")] = BUILTINS
    end

    def self.new
      instance = super

      if block_given?
        yield instance
      else
        instance
      end
    end

    BUILTINS = <<SIG
class BasicObject
  def __id__: -> Integer

  private
  def initialize: -> void
end

class Object < BasicObject
  include Kernel
 
  public
  def __id__: -> Integer

  private
  def respond_to_missing?: (Symbol, bool) -> bool
end

module Kernel
  private
  def puts: (*any) -> nil
end

class Class < Module
end

class Module
end

class String
  include Comparable
  prepend Enumerable[String, void]

  def self.try_convert: (any) -> String?
end

class Integer
end

class Symbol
end

module Comparable
end

module Enumerable[A, B]
end
SIG

    def build
      Dir.mktmpdir do |tmpdir|
        tmppath = Pathname(tmpdir)

        files.each do |path, content|
          absolute_path = tmppath + path
          absolute_path.parent.mkpath
          absolute_path.write(content)
        end

        env = Environment.new()
        loader = EnvironmentLoader.new(env: env)
        loader.stdlib_root = nil
        loader.add path: tmppath
        loader.load

        yield env
      end
    end
  end

  def type_name(string)
    Namespace.parse(string).yield_self do |namespace|
      last = namespace.path.last
      TypeName.new(name: last, namespace: namespace.parent)
    end
  end

  def assert_method_definition(method, types, accessibility: nil)
    assert_instance_of Definition::Method, method
    assert_equal types, method.method_types.map(&:to_s)
    assert_equal accessibility, method.accessibility if accessibility
    yield method.super if block_given?
  end

  def test_build_ancestors
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
module X
end

class Foo
  extend X
end

module Y[A]
end

class Bar[X]
  include Y[X]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])).yield_self do |ancestors|
          assert_equal [Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: [])], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [])).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: BuiltinNames::String.name, args: [])).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Enumerable.name, args: [parse_type("::String"), parse_type("void")]),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::String.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Comparable.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name)).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Class.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Singleton.new(name: TypeName.new(name: :Foo, namespace: Namespace.root))).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: TypeName.new(name: :Foo, namespace: Namespace.root)),
                         Definition::Ancestor::Instance.new(name: TypeName.new(name: :X, namespace: Namespace.root), args: []),
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::Object.name),
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::BasicObject.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Class.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: TypeName.new(name: :Bar, namespace: Namespace.root), args: [parse_type("::Integer")])).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Instance.new(name: TypeName.new(name: :Bar, namespace: Namespace.root), args: [parse_type("::Integer")]),
                         Definition::Ancestor::Instance.new(name: TypeName.new(name: :Y, namespace: Namespace.root), args: [parse_type("::Integer")]),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Singleton.new(name: BuiltinNames::Kernel.name)).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Singleton.new(name: BuiltinNames::Kernel.name),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Module.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                         Definition::Ancestor::Instance.new(name: BuiltinNames::BasicObject.name, args: []),
                       ], ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: [])).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Instance.new(name: BuiltinNames::Kernel.name, args: []),
                       ], ancestors
        end
      end
    end
  end

  def test_build_ancestors_extension
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
module X[A]
end

module Y[A]
end

class Foo[A]
  include X[Integer]
  prepend Y[A]
  extend Y[1]
end

module Z[A]
end

extension Foo[X] (Foo)
  include Z[X]
  prepend Z[String]
  extend Y[2]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_ancestors(Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [Types::Variable.build(:A)])).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::Instance.new(name: type_name("::Y"), args: [Types::Variable.build(:A)]),
                         Definition::Ancestor::Instance.new(name: type_name("::Z"), args: [parse_type("::String")]),
                         Definition::Ancestor::ExtensionInstance.new(name: type_name("::Foo"),
                                                                     args: [Types::Variable.build(:A)],
                                                                     extension_name: :Foo),
                         Definition::Ancestor::Instance.new(name: type_name("::Z"), args: [Types::Variable.build(:A)]),
                         Definition::Ancestor::Instance.new(name: type_name("::Foo"), args: [Types::Variable.build(:A)]),
                         Definition::Ancestor::Instance.new(name: type_name("::X"), args: [parse_type("::Integer")]),
                         Definition::Ancestor::Instance.new(name: type_name("::Object"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::Kernel"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::BasicObject"), args: []),
                       ],
                       ancestors
        end

        builder.build_ancestors(Definition::Ancestor::Singleton.new(name: type_name("::Foo"))).yield_self do |ancestors|
          assert_equal [
                         Definition::Ancestor::ExtensionSingleton.new(name: type_name("::Foo"),
                                                                      extension_name: :Foo),
                         Definition::Ancestor::Instance.new(name: type_name("::Y"), args: [parse_type(2)]),
                         Definition::Ancestor::Singleton.new(name: type_name("::Foo")),
                         Definition::Ancestor::Instance.new(name: type_name("::Y"), args: [parse_type(1)]),
                         Definition::Ancestor::Singleton.new(name: type_name("::Object")),
                         Definition::Ancestor::Singleton.new(name: type_name("::BasicObject")),
                         Definition::Ancestor::Instance.new(name: type_name("::Class"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::Module"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::Object"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::Kernel"), args: []),
                         Definition::Ancestor::Instance.new(name: type_name("::BasicObject"), args: []),
                       ],
                       ancestors
        end
      end
    end
  end

  def test_build_ancestors_cycle
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
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
          builder.build_ancestors(Definition::Ancestor::Instance.new(
            name: type_name("::X"),
            args: [parse_type("::Integer")])
          )
        end
      end
    end
  end

  def test_build_invalid_type_application
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
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

        assert_raises DefinitionBuilder::InvalidTypeApplicationError do
          builder.build_ancestors(Definition::Ancestor::Instance.new(name: type_name("::A"), args: []))
        end

        assert_raises DefinitionBuilder::InvalidTypeApplicationError do
          builder.build_ancestors(Definition::Ancestor::Instance.new(name: type_name("::B"), args: []))
        end

        assert_raises DefinitionBuilder::InvalidTypeApplicationError do
          builder.build_ancestors(Definition::Ancestor::Singleton.new(name: type_name("::C")))
        end
      end
    end
  end

  def test_build_interface
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
interface _Foo
  def bar: -> _Foo
  include _Hash
end

interface _Hash
  def hash: -> Integer
  def eql?: (any) -> bool
end

interface _Baz
  include _Hash[bool]
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        foo = type_name("::_Foo")
        baz = type_name("::_Baz")

        builder.build_interface(foo, env.find_type_decl(foo)).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_equal [:bar, :hash, :eql?].sort, definition.methods.keys.sort

          assert_method_definition definition.methods[:bar], ["() -> ::_Foo"], accessibility: :public
          assert_method_definition definition.methods[:hash], ["() -> ::Integer"], accessibility: :public
          assert_method_definition definition.methods[:eql?], ["(any) -> bool"], accessibility: :public
        end

        assert_raises DefinitionBuilder::InvalidTypeApplicationError do
          builder.build_interface(baz, env.find_type_decl(baz))
        end
      end
    end
  end

  def test_build_one_instance_methods
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(BuiltinNames::Object.name).yield_self do |definition|
          definition.methods[:__id__].yield_self do |method|
            assert_method_definition method, ["() -> ::Integer"], accessibility: :public
          end

          definition.methods[:respond_to_missing?].yield_self do |method|
            assert_method_definition method, ["(::Symbol, bool) -> bool"], accessibility: :private
          end
        end
      end
    end
  end

  def test_build_one_extension_instance
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
class Hello
end

extension Hello (Test)
  def assert_equal: (any, any) -> void
  def self.setup: () -> void

  @name: String
  self.@email: String
  @@count: Integer

  include _Foo[bool]
end

interface _Foo[X]
  def foo: -> X
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello"), extension_name: :Test).yield_self do |definition|
          assert_equal [:assert_equal, :foo].sort, definition.methods.keys.sort

          definition.methods[:assert_equal].tap do |method|
            assert_method_definition method, ["(any, any) -> void"], accessibility: :public
          end

          definition.methods[:foo].tap do |method|
            assert_method_definition method, ["() -> bool"], accessibility: :public
          end

          assert_equal [:@name].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@name].tap do |variable|
            assert_equal parse_type("::String"), variable.type
          end

          assert_equal [:@@count].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@count].tap do |variable|
            assert_equal parse_type("::Integer"), variable.type
          end
        end
      end
    end
  end

  def test_build_one_extension_singleton
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
class Hello
end

extension Hello (Test)
  def assert_equal: (any, any) -> void
  def self.setup: () -> void

  @name: String
  self.@email: String
  @@count: Integer

  extend _Foo[bool]
end

interface _Foo[X]
  def foo: -> X
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_singleton(type_name("::Hello"), extension_name: :Test).yield_self do |definition|
          assert_equal [:setup, :foo].sort, definition.methods.keys.sort

          definition.methods[:setup].tap do |method|
            assert_method_definition method, ["() -> void"], accessibility: :public
          end

          definition.methods[:foo].tap do |method|
            assert_method_definition method, ["() -> bool"], accessibility: :public
          end

          assert_equal [:@email].sort, definition.instance_variables.keys.sort
          definition.instance_variables[:@email].tap do |variable|
            assert_equal parse_type("::String"), variable.type
          end

          assert_equal [:@@count].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@count].tap do |variable|
            assert_equal parse_type("::Integer"), variable.type
          end
        end
      end
    end
  end

  def test_build_one_instance_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
class Hello[A]
  @name: A
  @@count: Integer
  self.@email: String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_instance(type_name("::Hello")).yield_self do |definition|
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
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_one_singleton(BuiltinNames::String.name).yield_self do |definition|
          definition.methods[:try_convert].yield_self do |method|
            assert_method_definition method, ["(any) -> ::String?"], accessibility: :public
          end
        end
      end
    end
  end

  def test_build_one_singleton_variables
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
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
          assert_equal Set.new([:__id__, :initialize, :puts, :respond_to_missing?]), Set.new(definition.methods.keys)

          definition.methods[:__id__].yield_self do |method|
            assert_method_definition method, ["() -> ::Integer"], accessibility: :public
          end

          definition.methods[:initialize].yield_self do |method|
            assert_method_definition method, ["() -> void"], accessibility: :private
          end

          definition.methods[:puts].yield_self do |method|
            assert_method_definition method, ["(*any) -> nil"], accessibility: :private
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
      manager.files[Pathname("foo.rbi")] = <<EOF
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
            assert_equal :Bar, variable.declared_in.name.name
            assert_equal :Hello, variable.parent_variable.declared_in.name.name
          end

          assert_equal [:@@email].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@email].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal :Hello, variable.declared_in.name.name
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
      manager.files[Pathname("foo.rbi")] = <<EOF
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
            assert_equal :Bar, variable.declared_in.name.name
            assert_equal :Hello, variable.parent_variable.declared_in.name.name
          end

          assert_equal [:@@email].sort, definition.class_variables.keys.sort
          definition.class_variables[:@@email].yield_self do |variable|
            assert_instance_of Definition::Variable, variable
            assert_equal parse_type("::String"), variable.type
            assert_equal :Hello, variable.declared_in.name.name
          end
        end
      end
    end
  end

  def test_build_extension
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbi")] = <<EOF
class Hello
end

extension Hello (Hoge)
  def hoge: -> self
  def self.hoge: -> 1
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:hoge], ["() -> self"]
        end

        builder.build_singleton(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:hoge], ["() -> 1"]
        end
      end
    end
  end
end

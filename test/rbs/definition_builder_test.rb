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

  def assert_ivar_definition(ivar, type)
    assert_instance_of Definition::Variable, ivar

    type = parse_type(type) if type.is_a?(String)
    assert_equal type, ivar.type
  end

  def test_build_interface_def_alias
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def i1: (X) -> String

  alias i2 i1
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_I1")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::_I1"), definition.type_name
          assert_equal parse_type("::_I1[X]", variables: [:X]), definition.self_type
          assert_equal [:X], definition.type_params

          assert_equal Set[:i1, :i2], Set.new(definition.methods.keys)

          assert_method_definition definition.methods[:i1], ["(X) -> ::String"], accessibility: :public
          assert_method_definition definition.methods[:i2], ["(X) -> ::String"], accessibility: :public
        end
      end
    end
  end

  def test_build_interface_def_overload
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def i1: (X) -> String

  def i1: (X, Integer) -> String
        | ...
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_I1")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::_I1"), definition.type_name
          assert_equal parse_type("::_I1[X]", variables: [:X]), definition.self_type
          assert_equal [:X], definition.type_params

          assert_equal Set[:i1], Set.new(definition.methods.keys)

          assert_method_definition definition.methods[:i1],
                                   ["(X, ::Integer) -> ::String", "(X) -> ::String"],
                                   accessibility: :public
        end
      end
    end
  end

  def test_build_interface_def_alias_overload
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def i1: (X) -> String

  alias i2 i1

  def i1: (X, Integer) -> String
        | ...

  def i2: (X, Symbol) -> String
        | ...
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_I1")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::_I1"), definition.type_name
          assert_equal parse_type("::_I1[X]", variables: [:X]), definition.self_type
          assert_equal [:X], definition.type_params

          assert_equal Set[:i1, :i2], Set.new(definition.methods.keys)

          assert_method_definition definition.methods[:i1],
                                   ["(X, ::Integer) -> ::String", "(X) -> ::String"],
                                   accessibility: :public
          assert_method_definition definition.methods[:i2],
                                   ["(X, ::Symbol) -> ::String", "(X, ::Integer) -> ::String", "(X) -> ::String"],
                                   accessibility: :public
        end
      end
    end
  end

  def test_build_interface_include
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def i1: (X) -> String
end

interface _I2
  include _I1[String]

  def i2: () -> String
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_I2")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::_I2"), definition.type_name
          assert_equal parse_type("::_I2"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:i1, :i2], Set.new(definition.methods.keys)

          assert_method_definition definition.methods[:i1],
                                   ["(::String) -> ::String"],
                                   accessibility: :public
          assert_method_definition definition.methods[:i2],
                                   ["() -> ::String"],
                                   accessibility: :public
        end
      end
    end
  end

  def test_build_interface_include_alias_overload
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def i1: (X) -> String

  def i2: (X) -> String
end

interface _I2
  include _I1[String]

  def i1: () -> String
        | ...

  alias i3 i2
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_I2")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::_I2"), definition.type_name
          assert_equal parse_type("::_I2"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:i1, :i2, :i3], Set.new(definition.methods.keys)

          assert_method_definition definition.methods[:i1],
                                   ["() -> ::String", "(::String) -> ::String"],
                                   accessibility: :public
          assert_method_definition definition.methods[:i2],
                                   ["(::String) -> ::String"],
                                   accessibility: :public
          assert_method_definition definition.methods[:i3],
                                   ["(::String) -> ::String"],
                                   accessibility: :public
        end
      end
    end
  end

  def test_build_interface_error
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1
  def foo: () -> void | ...
end

interface _I2
  alias bar baz
end

interface _I3
  alias a b
  alias b c
  alias c a
end

interface _I4
  def foo: () -> void

  def foo: () -> void
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises(RBS::InvalidOverloadMethodError) do
          builder.build_interface(type_name("::_I1"))
        end

        assert_raises(RBS::UnknownMethodAliasError) do
          builder.build_interface(type_name("::_I2"))
        end

        assert_raises(RBS::RecursiveAliasDefinitionError) do
          builder.build_interface(type_name("::_I3"))
        end

        assert_raises(RBS::DuplicatedMethodDefinitionError) do
          builder.build_interface(type_name("::_I4"))
        end
      end
    end
  end

  def test_build_instance_module
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module Foo[X]
  @value: X
  def get: () -> X
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::Foo"), definition.type_name
          assert_equal parse_type("::Foo[X]", variables: [:X]), definition.self_type
          assert_equal [:X], definition.type_params

          assert_equal Set[:get], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:get], ["() -> X"], accessibility: :public

          assert_equal Set[:@value], Set.new(definition.instance_variables.keys)
          assert_ivar_definition definition.instance_variables[:@value], parse_type("X", variables: [:X])
        end
      end
    end
  end

  def test_build_instance_module_include_module
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module M1[X]
  @value: X
  def get: () -> X
end

module M2
  include M1[String]

  def get: (Integer) -> String
         | ...
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M2")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::M2"), definition.type_name
          assert_equal parse_type("::M2"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:get], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:get], ["(::Integer) -> ::String", "() -> ::String"], accessibility: :public

          assert_equal Set[:@value], Set.new(definition.instance_variables.keys)
          assert_ivar_definition definition.instance_variables[:@value], "::String"
        end
      end
    end
  end

  def test_build_instance_module_include_interface
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _I1[X]
  def get: () -> X
end

module M2
  include _I1[String]

  def get: (Integer) -> String
         | ...
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M2")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::M2"), definition.type_name
          assert_equal parse_type("::M2"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:get], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:get], ["(::Integer) -> ::String", "() -> ::String"], accessibility: :public

          assert definition.methods[:get].defs.all? {|td| td.implemented_in == TypeName("::M2") }
        end
      end
    end
  end

  def test_build_instance_module_self_types
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
interface _StringConvertible
  def to_str: () -> String
end

module M : _StringConvertible
  alias inspect to_str
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::M"), definition.type_name
          assert_equal parse_type("::M"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:to_str, :inspect], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:to_str], ["() -> ::String"], accessibility: :public
          assert_method_definition definition.methods[:inspect], ["() -> ::String"], accessibility: :public
        end
      end
    end
  end

  def test_build_instance_class_basic_object
    SignatureManager.new do |manager|
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::BasicObject")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::BasicObject"), definition.type_name
          assert_equal parse_type("::BasicObject"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:__id__, :initialize], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:__id__], ["() -> ::Integer"], accessibility: :public
          assert_method_definition definition.methods[:initialize], ["() -> void"], accessibility: :private

          assert_empty definition.instance_variables
        end
      end
    end
  end

  def test_build_instance_class_inherit
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::Hello"), definition.type_name
          assert_equal parse_type("::Hello"), definition.self_type
          assert_equal [], definition.type_params

          assert_equal Set[:__id__, :initialize, :puts, :to_i, :respond_to_missing?], Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:__id__], ["() -> ::Integer"], accessibility: :public
          assert_method_definition definition.methods[:initialize], ["() -> void"], accessibility: :private
          assert_method_definition definition.methods[:puts], ["(*untyped) -> nil"], accessibility: :private
          assert_method_definition definition.methods[:to_i], ["() -> ::Integer"], accessibility: :public

          assert_empty definition.instance_variables
        end
      end
    end
  end

  def test_build_comment_attributes
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

        builder.build_instance(type_name("::Hello")).tap do |definition|
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

  def test_build_instance_method_variance
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

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::A")) }
        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::B")) }

        builder.build_instance(type_name("::C"))
      end
    end
  end

  def test_variance_check_ancestors
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C[out X]
end

module M[out X]
end

interface _I[out X]
end

class Test0[out X]
end

class Test1[in X] < C[X]
end

class Test2[in X]
  include M[X]
end

class Test3[in X]
  include _I[X]
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Test0"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test1")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "C[X]", error.location.source
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test2")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "include M[X]", error.location.source
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test3")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "include _I[X]", error.location.source
        end
      end
    end
  end

  def test_variance_check_methods
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Test0[out X, in Y, Z]
  def foo: (Y, Z) -> [X, Z]

  attr_reader x: X
  attr_accessor z: Z
end

class Test1[out X]
  def foo: (X) -> void
end

class Test2[in X]
  attr_reader x: X
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Test0"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test1")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "(X) -> void", error.location.source
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test2")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "attr_reader x: X", error.location.source
        end
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

        builder.build_instance(type_name("::A"))
        builder.build_instance(type_name("::C"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::B")) }
      end
    end
  end

  def test_build_variance_validation
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

        builder.build_instance(type_name("::A"))
        builder.build_instance(type_name("::C"))

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::B")) }
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

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
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

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
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

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
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
          assert_ivar_definition definition.instance_variables[:@instance_reader], "::String"

          assert_method_definition definition.methods[:instance_writer=], ["(::Integer instance_writer) -> ::Integer"]
          assert_ivar_definition definition.instance_variables[:@writer], "::Integer"

          assert_method_definition definition.methods[:instance_accessor], ["() -> ::Symbol"]
          assert_method_definition definition.methods[:instance_accessor=], ["(::Symbol instance_accessor) -> ::Symbol"]
          assert_nil definition.instance_variables[:@instance_accessor]
        end
      end
    end
  end

  def test_singleton_attributes
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  attr_reader self.reader: String
  attr_writer self.writer(@writer): Integer
  attr_accessor self.accessor(): Symbol
end
EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:reader], ["() -> ::String"]
          assert_ivar_definition definition.instance_variables[:@reader], "::String"

          assert_method_definition definition.methods[:writer=], ["(::Integer writer) -> ::Integer"]
          assert_ivar_definition definition.instance_variables[:@writer], "::Integer"

          assert_method_definition definition.methods[:accessor], ["() -> ::Symbol"]
          assert_method_definition definition.methods[:accessor=], ["(::Symbol accessor) -> ::Symbol"]
          assert_nil definition.instance_variables[:@accessor]
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

        builder.build_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:initialize], ["(::String) -> void"], accessibility: :private
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::String) -> ::Hello"], accessibility: :public
        end
      end
    end
  end

  def test_initialize_new_override
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class C0
  def initialize: (Integer) -> void
end

class C1 < C0
  def self.new: (String) -> untyped
end

class C2 < C1
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C0")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::Integer) -> ::C0"]
        end

        builder.build_singleton(type_name("::C1")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::String) -> untyped"]
        end

        builder.build_singleton(type_name("::C2")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::String) -> untyped"]
        end
      end
    end
  end

  def test_initialize_new_no_module
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module M
  def initialize: (Integer) -> void
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::M")).tap do |definition|
          assert_instance_of Definition, definition

          refute_operator definition.methods, :key?, :new
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

          assert_method_definition definition.methods[:new], ["[A] () -> ::Hello[A]"]
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

        builder.build_instance(type_name("::Hello")).tap do |definition|
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

        builder.build_instance(type_name("::Hello")).tap do |definition|
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

  def test_new_from_included_initialize
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  include World
end

module World
  def initialize: (String, Integer) -> void
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          initalize = definition.methods[:initialize]
          assert_equal ["(::String, ::Integer) -> void"], initalize.method_types.map(&:to_s)
        end

        builder.build_singleton(type_name("::Hello")).tap do |definition|
          new = definition.methods[:new]
          assert_equal ["(::String, ::Integer) -> ::Hello"], new.method_types.map(&:to_s)
        end
      end
    end
  end

  def test_definition_variance_initialize
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello[out T]
  def get: () -> T

  def initialize: (T value) -> void
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)
        builder.build_instance(type_name("::Hello"))
      end
    end
  end

  def test_overload_super_method
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C1
  def f: () -> void

  def f: () -> Integer | ...
end

module M2
  def f: () -> String
end

class C2
  include M2
  def f: () -> Integer | ...
end

interface _I3
  def f: () -> String
end

class C3
  include _I3

  def f: () -> Integer | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::C1")).tap do |definition|
          assert_instance_of Definition, definition

          definition.methods[:f].tap do |f|
            assert_instance_of Definition::Method, f
            assert_nil f.super_method
          end
        end

        builder.build_instance(type_name("::C2")).tap do |definition|
          assert_instance_of Definition, definition

          definition.methods[:f].tap do |f|
            assert_instance_of Definition::Method, f
            refute_nil f.super_method
            assert_equal type_name("::M2"), f.super_method.defined_in
          end
        end

        builder.build_instance(type_name("::C3")).tap do |definition|
          assert_instance_of Definition, definition

          definition.methods[:f].tap do |f|
            assert_instance_of Definition::Method, f
            assert_nil f.super_method
          end
        end
      end
    end
  end
end

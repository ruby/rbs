require "test_helper"

class RBS::DefinitionBuilderTest < Test::Unit::TestCase
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
        end.tap do |error|
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::RecursiveAliasDefinitionError)

                alias a b
                ^^^^^^^^^
          DETAILED_MESSAGE
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

          assert_operator Set[:get], :subset?, Set.new(definition.methods.keys)
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

          assert_operator Set[:get], :subset?, Set.new(definition.methods.keys)
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

          assert_operator Set[:get], :subset?, Set.new(definition.methods.keys)
          assert_method_definition definition.methods[:get], ["(::Integer) -> ::String", "() -> ::String"], accessibility: :public

          assert definition.methods[:get].defs.all? {|td| td.implemented_in == RBS::TypeName.parse("::M2") }
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

  def test_build_comment_dedup
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Hello
  # doc1
  def foo: () -> String
         | (Integer) -> String
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          foo = definition.methods[:foo]

          assert_equal 1, foo.comments.size
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

  def test_build_interface_method_variance
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _A[out X, unchecked out Y]
  def foo: () -> X
  def bar: (X) -> void
  def baz: (Y) -> void
end

interface _B[in X, unchecked in Y]
  def foo: (X) -> void
  def bar: () -> X
  def baz: () -> Y
end

interface _C[Z]
  def foo: (Z) -> Z
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises(InvalidVarianceAnnotationError) { builder.build_interface(type_name("::_A")) }
        assert_raises(InvalidVarianceAnnotationError) { builder.build_interface(type_name("::_B")) }

        builder.build_interface(type_name("::_C"))
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
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidVarianceAnnotationError)

              class Test1[in X] < C[X]
                                  ^^^^
          DETAILED_MESSAGE
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test2")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "include M[X]", error.location.source
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidVarianceAnnotationError)

                include M[X]
                ^^^^^^^^^^^^
          DETAILED_MESSAGE
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test3")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "include _I[X]", error.location.source
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidVarianceAnnotationError)

                include _I[X]
                ^^^^^^^^^^^^^
          DETAILED_MESSAGE
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
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidVarianceAnnotationError)

                def foo: (X) -> void
                         ^^^^^^^^^^^
          DETAILED_MESSAGE
        end

        assert_raises(InvalidVarianceAnnotationError) { builder.build_instance(type_name("::Test2")) }.tap do |error|
          assert_equal :X, error.param.name
          assert_equal "attr_reader x: X", error.location.source
          assert_equal <<~DETAILED_MESSAGE, error.detailed_message if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidVarianceAnnotationError)

                attr_reader x: X
                ^^^^^^^^^^^^^^^^
          DETAILED_MESSAGE
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

  def test_build_singleton_instance_with_class_instance
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  def self?.foo: (instance) -> class
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(RBS::TypeName.parse("::Hello")).tap do |definition|
          assert_equal ["(instance) -> class"], definition.methods[:foo].method_types.map(&:to_s)
        end

        builder.build_singleton(RBS::TypeName.parse("::Hello")).tap do |definition|
          assert_equal ["(instance) -> class"], definition.methods[:foo].method_types.map(&:to_s)
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
        end.tap do |error|
          assert_equal error.detailed_message, <<~DETAILED_MESSAGE if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::UnknownMethodAliasError)

                alias self.xxx self.yyy
                ^^^^^^^^^^^^^^^^^^^^^^^
          DETAILED_MESSAGE
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
          assert_equal definition.methods[:instance_reader].method_types.first.location.source, "attr_reader instance_reader: String"
          assert_ivar_definition definition.instance_variables[:@instance_reader], "::String"

          assert_method_definition definition.methods[:instance_writer=], ["(::Integer instance_writer) -> ::Integer"]
          assert_equal definition.methods[:instance_writer=].method_types.first.location.source, "attr_writer instance_writer(@writer): Integer"
          assert_ivar_definition definition.instance_variables[:@writer], "::Integer"

          assert_method_definition definition.methods[:instance_accessor], ["() -> ::Symbol"]
          assert_equal definition.methods[:instance_accessor].method_types.first.location.source, "attr_accessor instance_accessor(): Symbol"
          assert_method_definition definition.methods[:instance_accessor=], ["(::Symbol instance_accessor) -> ::Symbol"]
          assert_equal definition.methods[:instance_accessor=].method_types.first.location.source, "attr_accessor instance_accessor(): Symbol"
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
          assert_equal definition.methods[:reader].method_types.first.location.source, "attr_reader self.reader: String"
          assert_ivar_definition definition.instance_variables[:@reader], "::String"

          assert_method_definition definition.methods[:writer=], ["(::Integer writer) -> ::Integer"]
          assert_equal definition.methods[:writer=].method_types.first.location.source, "attr_writer self.writer(@writer): Integer"
          assert_ivar_definition definition.instance_variables[:@writer], "::Integer"

          assert_method_definition definition.methods[:accessor], ["() -> ::Symbol"]
          assert_equal definition.methods[:accessor].method_types.first.location.source, "attr_accessor self.accessor(): Symbol"
          assert_method_definition definition.methods[:accessor=], ["(::Symbol accessor) -> ::Symbol"]
          assert_equal definition.methods[:accessor=].method_types.first.location.source, "attr_accessor self.accessor(): Symbol"
          assert_nil definition.instance_variables[:@accessor]
        end
      end
    end
  end

  def test_initialize_new
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  public

  def initialize: (String) -> void
  def initialize_copy: (self) -> self
  def initialize_clone: (self) -> self
  def initialize_dup: (self) -> self
  def respond_to_missing?: () -> bool

  def self.initialize: (String) -> void
  def self.initialize_copy: (self) -> self
  def self.initialize_clone: (self) -> self
  def self.initialize_dup: (self) -> self
  def self.respond_to_missing?: () -> bool
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).tap do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:initialize], ["(::String) -> void"], accessibility: :private
          assert_method_definition definition.methods[:initialize_copy], ["(self) -> self"], accessibility: :private
          assert_method_definition definition.methods[:initialize_clone], ["(self) -> self"], accessibility: :private
          assert_method_definition definition.methods[:initialize_dup], ["(self) -> self"], accessibility: :private
          assert_method_definition definition.methods[:respond_to_missing?], ["() -> bool"], accessibility: :private
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition
          assert_method_definition definition.methods[:new], ["(::String) -> ::Hello"], accessibility: :public
          assert_method_definition definition.methods[:initialize], ["(::String) -> void"], accessibility: :public
          assert_method_definition definition.methods[:initialize_copy], ["(self) -> self"], accessibility: :public
          assert_method_definition definition.methods[:initialize_clone], ["(self) -> self"], accessibility: :public
          assert_method_definition definition.methods[:initialize_dup], ["(self) -> self"], accessibility: :public
          assert_method_definition definition.methods[:respond_to_missing?], ["() -> bool"], accessibility: :public
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
  def initialize: [A] (A) { (A) -> void } -> void
end
EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          assert_method_definition definition.methods[:initialize], ["[A] (A) { (A) -> void } -> void"]
        end

        builder.build_singleton(type_name("::Hello")).yield_self do |definition|
          assert_instance_of Definition, definition

          definition.methods[:new].tap do |method|
            assert_instance_of Definition::Method, method

            assert_equal 1, method.method_types.size
            # [A, A@1] (A@1) { (A@1) -> void } -> ::Hello[A]
            assert_match(/\A\[A, A@(\d+)\] \(A@\1\) { \(A@\1\) -> void } -> ::Hello\[A\]\Z/, method.method_types[0].to_s)
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
            assert_equal ["hello", "world"], defn.each_annotation.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[1].tap do |defn|
            assert_equal parse_method_type("() -> ::String"), defn.type
            assert_equal "doc1\n", defn.comment.string
            assert_equal ["hello", "world"], defn.each_annotation.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[2].tap do |defn|
            assert_equal parse_method_type("(::Integer) -> ::String"), defn.type
            assert_equal "doc1\n", defn.comment.string
            assert_equal ["hello", "world"], defn.each_annotation.map(&:string)
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
            assert_equal ["_Hello#foo", "Hello#foo"], defn.each_annotation.map(&:string)
            assert_equal type_name("::Hello"), defn.defined_in
            assert_equal type_name("::Hello"), defn.implemented_in
          end

          foo.defs[1].tap do |defn|
            assert_equal parse_method_type("() -> ::String"), defn.type
            assert_equal "_Hello#foo\n", defn.comment.string
            assert_equal ["_Hello#foo", "Hello#foo"], defn.each_annotation.map(&:string)
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
        end.tap do |error|
          assert_equal error.detailed_message, <<~DETAILED_MESSAGE if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::InvalidOverloadMethodError)

                def foo: (Integer) -> String | ...
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
          DETAILED_MESSAGE
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
          initialize = definition.methods[:initialize]
          assert_equal ["(::String, ::Integer) -> void"], initialize.method_types.map(&:to_s)
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

  def test_duplicated_methods_from_interfaces
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def foo: () -> void
end

interface _I2
  def foo: () -> String
end

class Hello
  include _I1
  include _I2
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises RBS::DuplicatedInterfaceMethodDefinitionError do
          builder.build_instance(type_name("::Hello"))
        end.tap do |error|
          assert_equal error.detailed_message, <<~DETAILED_MESSAGE if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::DuplicatedInterfaceMethodDefinitionError)

                include _I2
                ^^^^^^^^^^^
          DETAILED_MESSAGE
        end
      end
    end
  end

  def test_duplicated_methods_from_interfaces2
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def foo: () -> void
end

class Hello
  include _I1

  def foo: () -> String
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises RBS::DuplicatedMethodDefinitionError do
          builder.build_instance(type_name("::Hello"))
        end.tap do |error|
          assert_equal error.detailed_message, <<~DETAILED_MESSAGE if Exception.method_defined?(:detailed_message)
            #{error.message} (RBS::DuplicatedMethodDefinitionError)

                def foo: () -> String
                ^^^^^^^^^^^^^^^^^^^^^
          DETAILED_MESSAGE
        end
      end
    end
  end

  def test_include_interface_super
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def foo: () -> void
end

class C0
  include _I1
end

class C1
  def foo: () -> void
end

class C2 < C1
  include _I1
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::C0")).tap do |defn|
          defn.methods[:foo].tap do |foo|
            assert_equal type_name("::_I1"), foo.defined_in
            assert_equal type_name("::C0"), foo.implemented_in
            assert_nil foo.super_method
          end
        end

        builder.build_instance(type_name("::C2")).tap do |defn|
          defn.methods[:foo].tap do |foo|
            assert_equal type_name("::_I1"), foo.defined_in
            assert_equal type_name("::C2"), foo.implemented_in
            assert_equal type_name("::C1"), foo.super_method.defined_in
          end
        end
      end
    end
  end

  def test_interface_alias
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def foo: () -> void
end

class C0
  include _I1

  alias bar foo
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::C0")).tap do |defn|
          defn.methods[:bar].tap do |bar|
            assert_equal defn.methods[:foo], bar.alias_of
            assert_equal type_name("::C0"), bar.defined_in
            assert_equal type_name("::C0"), bar.implemented_in
            assert_nil bar.super_method
          end
        end
      end
    end
  end

  def test_self_type_interface_methods
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def a: () -> void
end

module M0 : _I1
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M0")).tap do |defn|
          defn.methods[:a].tap do |a|
            assert_equal type_name("::_I1"), a.defined_in
            assert_nil a.implemented_in
            assert_nil a.super_method
          end
        end
      end
    end
  end

  def test_self_type_interface_methods_error
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def a: () -> void
end

module M0 : _I1
  def a: (Integer) -> String
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M0")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_equal type_name("::M0"), a.defined_in
            assert_equal type_name("::M0"), a.implemented_in
            assert_equal type_name("::_I1"), a.super_method.defined_in
          end
        end
      end
    end
  end

  def test_self_type_interface_methods_error2
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def a: () -> void
end

interface _I2
  def a: () -> Integer
end

module M0 : _I1, _I2
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M0")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_equal type_name("::_I2"), a.defined_in
            assert_nil a.implemented_in
            assert_nil a.super_method
            assert_method_definition a, ["() -> ::Integer"]
          end
        end
      end
    end
  end

  def test_self_type_interface_methods_overload
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
interface _I1
  def a: () -> void
end

module M0 : _I1
  def a: (Integer) -> String | ...
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M0")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_equal [type_name("::M0"), type_name("::_I1")], a.defs.map(&:defined_in)
            assert_equal [type_name("::M0"), type_name("::M0")], a.defs.map(&:implemented_in)
            assert_equal type_name("::_I1"), a.super_method.defined_in
          end
        end
      end
    end
  end

  def test_mixed_module_methods_building
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Foo
  def foo: () -> void
end

module M0 : Foo
  def bar: () -> void
end

class Bar
  include M0   # Broken include, but RBS cannot detect it.
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M0")).tap do |definition|
          assert_operator definition.methods, :key?, :foo
          assert_operator definition.methods, :key?, :bar
        end

        builder.build_instance(type_name("::Bar")).tap do |definition|
          refute_operator definition.methods, :key?, :foo    # foo is not defined in M0
          assert_operator definition.methods, :key?, :bar
        end
      end
    end
  end

  def test_generic_class_open
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Foo[A]
  def foo: () -> A
end

class Foo[B]
  def bar: () -> B
  attr_reader Bar: B
  @bar: B
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:foo].method_types
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:bar].method_types
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:Bar].method_types

          assert_equal Types::Variable.build(:A),
                       definition.instance_variables[:@bar].type
          assert_equal Types::Variable.build(:A),
                       definition.instance_variables[:@Bar].type
        end
      end
    end
  end

  def test_generic_class_interface
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Foo[A]
  def foo: () -> A
end

interface _Baz[Y]
  def baz: () -> Y
end

class Foo[C]
  include _Baz[C]
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:foo].method_types
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:baz].method_types
        end
      end
    end
  end

  def test_generic_class_module
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class Foo[A]
  def foo: () -> A
end

class Foo[B]
  include Bar[B]
end

module Bar[Y]
  def bar: () -> Y

  @bar: Y
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:foo].method_types
          assert_equal [parse_method_type("() -> A", variables: [:A])],
                       definition.methods[:bar].method_types

          assert_equal Types::Variable.build(:A),
                       definition.instance_variables[:@bar].type
        end
      end
    end
  end

  def test_expand_alias2
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
type opt[T] = T | nil
type pair[S, T] = [S, T]
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_equal(
          parse_type("::Integer | nil"),
          builder.expand_alias2(type_name("::opt"), [parse_type("::Integer")])
        )

        assert_equal(
          parse_type("[::String, bool]"),
          builder.expand_alias2(type_name("::pair"), [parse_type("::String"), parse_type("bool")])
        )

        assert_raises do
          builder.expand_alias2(type_name("::opt"), [])
        end

        assert_raises do
          builder.expand_alias2(type_name("::opt"), [parse_type("bool"), parse_type("top")])
        end
end
    end
  end

  def test_singleton_public_private
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  private
  def self.a: () -> void
end

module M
  private
  def self.b: () -> void
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :public?
          end
        end

        builder.build_singleton(type_name("::M")).tap do |definition|
          definition.methods[:b].tap do |b|
            assert_predicate b, :public?
          end
        end
      end
    end
  end

  def test_module_function
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  def self?.a: () -> void
end

module M
  def self?.b: () -> void
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :public?
          end
        end

        builder.build_instance(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :private?
          end
        end

        builder.build_singleton(type_name("::M")).tap do |definition|
          definition.methods[:b].tap do |b|
            assert_predicate b, :public?
          end
        end

        builder.build_instance(type_name("::M")).tap do |definition|
          definition.methods[:b].tap do |b|
            assert_predicate b, :private?
          end
        end
      end
    end
  end

  def test_alias_visibility
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  def self?.a: () -> void

  public

  alias b a
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :private?
          end

          definition.methods[:b].tap do |b|
            assert_predicate b, :private?
          end
        end
      end
    end
  end

  def test_def_with_visibility_modifier
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  private def self.a: () -> void
end

module M
  private
  public def b: () -> void
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :private?
          end
        end

        builder.build_instance(type_name("::M")).tap do |definition|
          definition.methods[:b].tap do |b|
            assert_predicate b, :public?
          end
        end
      end
    end
  end

  def test_attribute_with_visibility_modifier
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  private attr_reader self.a: String
end

module M
  private
  public attr_accessor b: String
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C")).tap do |definition|
          definition.methods[:a].tap do |a|
            assert_predicate a, :private?
          end
        end

        builder.build_instance(type_name("::M")).tap do |definition|
          definition.methods[:b].tap do |b|
            assert_predicate b, :public?
          end

          definition.methods[:b=].tap do |b|
            assert_predicate b, :public?
          end
        end
      end
    end
  end

  def test_new_alias
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<-EOF)
class C
  def initialize: (String) -> void

  alias self.compile self.new

  alias self.start self.compile
end
      EOF
      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::C")).tap do |definition|
          definition.methods[:new].tap do |a|
            assert_equal ["(::String) -> ::C"], a.method_types.map(&:to_s)
          end

          definition.methods[:compile].tap do |a|
            assert_equal ["(::String) -> ::C"], a.method_types.map(&:to_s)
          end

          definition.methods[:start].tap do |a|
            assert_equal ["(::String) -> ::C"], a.method_types.map(&:to_s)
          end
        end
      end
    end
  end

  def test_alias_in_module_from_self_constraints
    loader = RBS::EnvironmentLoader.new
    env = RBS::Environment.from_loader(loader)
      rbs = <<~DEF
module Mod
  alias request send
end

class Foo
  include Mod
end
      DEF
      RBS::Parser.parse_signature(rbs).tap do |buf, dirs, decls|
        env.add_source(RBS::Source::RBS.new(buf, dirs, decls))
      end
      definition_builder = RBS::DefinitionBuilder.new(env: env.resolve_type_names)
      definition_builder.build_instance(RBS::TypeName.parse("::Foo")).tap do |defn|
        defn.methods[:request].tap do |m|
          assert_equal ["(::interned name, *untyped, **untyped) ?{ (?) -> untyped } -> untyped"], m.method_types.map(&:to_s)
        end
      end
      definition_builder.build_instance(RBS::TypeName.parse("::Mod")).tap do |defn|
        defn.methods[:request].tap do |m|
          assert_equal ["(::interned name, *untyped, **untyped) ?{ (?) -> untyped } -> untyped"], m.method_types.map(&:to_s)
        end
      end
  end

  def test_class_definition_inheriting_module
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<~EOF)
        module Mod
        end

        class Foo < Mod
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises(RBS::InheritModuleError) { builder.build_instance(type_name("::Foo")) }
        assert_raises(RBS::InheritModuleError) { builder.build_singleton(type_name("::Foo")) }
      end
    end
  end

  def test_prepend_initialize
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<~EOF)
        module M1
        end

        class Foo
          prepend M1

          def initialize: (String) -> void
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |instance|
          assert_equal [parse_method_type("(::String) -> void")], instance.methods[:initialize].defs.map(&:type)
        end

        builder.build_singleton(type_name("::Foo")).tap do |singleton|
          assert_equal [parse_method_type("(::String) -> ::Foo")], singleton.methods[:new].defs.map(&:type)
        end
      end
    end
  end

  def test_include_super_overload
    SignatureManager.new do |manager|
      manager.files.merge!(Pathname("foo.rbs") => <<~EOF)
        interface _WithFoo
          def foo: () -> void
        end

        module M1 : _WithFoo
          def foo: (String) -> void
                 | ...
        end

        class Foo1
          def foo: () -> void
                 | (Integer) -> void
        end

        class Foo < Foo1
          include M1
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::M1")).tap do |definition|
          assert_equal(
            [
              parse_method_type("(::String) -> void"),
              parse_method_type("() -> void"),
            ],
            definition.methods[:foo].defs.map(&:type)
          )
        end

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_equal(
            [
              parse_method_type("(::String) -> void"),
              parse_method_type("() -> void"),
              parse_method_type("(::Integer) -> void")
            ],
            definition.methods[:foo].defs.map(&:type)
          )
        end
      end
    end
  end

  def test_build_instance_alias
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        class A
        end

        class B = A

        module K = Kernel
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::B")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::A"), definition.type_name
        end

        builder.build_instance(type_name("::K")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::Kernel"), definition.type_name
        end
      end
    end
  end

  def test_build_singleton_alias
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        class A
          def initialize: (String) -> void
        end

        class B = A

        module K = Kernel
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::B")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::A"), definition.type_name

          assert_equal [parse_method_type("(::String) -> ::A")], definition.methods[:new].defs.map(&:type)
        end

        builder.build_singleton(type_name("::K")).tap do |definition|
          assert_instance_of Definition, definition
          assert_equal type_name("::Kernel"), definition.type_name
        end
      end
    end
  end

  def test_build_instance_interface_mixin_transitive
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        interface _X
          def x: () -> void

          include _Y
        end

        interface _Y
          def y: () -> void

          include _Z
        end

        interface _Z
          def z: () -> void
        end

        class A
          include _X
          extend _X
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          assert_instance_of Definition, definition

          assert_operator Set[:x, :y, :z], :<=, Set.new(definition.methods.keys)
        end
      end

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::A")).tap do |definition|
          assert_instance_of Definition, definition

          assert_operator Set[:x, :y, :z], :<=, Set.new(definition.methods.keys)
        end
      end

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_interface(type_name("::_X")).tap do |definition|
          assert_instance_of Definition, definition

          assert_operator Set[:x, :y, :z], :<=, Set.new(definition.methods.keys)
        end
      end
    end
  end

  def test_mixin_method_owners
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        class A
          include B
        end

        module B
          def b: () -> void

          attr_reader c: String

          alias d b

          def __id__: () -> void
                    | ...
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          assert_instance_of Definition, definition

          definition.methods[:b].tap do |method|
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:defined_in)
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:implemented_in)
          end

          definition.methods[:c].tap do |method|
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:defined_in)
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:implemented_in)
          end

          definition.methods[:d].tap do |method|
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:defined_in)
            assert_equal [RBS::TypeName.parse("::B")], method.defs.map(&:implemented_in)
          end

          definition.methods[:__id__].tap do |method|
            assert_equal [RBS::TypeName.parse("::B"), RBS::TypeName.parse("::Object")], method.defs.map(&:defined_in)
            assert_equal [RBS::TypeName.parse("::B"), RBS::TypeName.parse("::B")], method.defs.map(&:implemented_in)
          end
        end
      end
    end
  end

  def test_extend_overload
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~EOF
        module M
          def f: () -> Integer
        end
        class A
          extend M
          def self.f: () -> String | ...
        end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::A")).tap do |definition|
          assert_instance_of Definition, definition

          definition.methods[:f].tap do |method|
            assert_equal [RBS::TypeName.parse("::A"), RBS::TypeName.parse("::M")], method.defs.map(&:defined_in)
            assert_equal [RBS::TypeName.parse("::A"), RBS::TypeName.parse("::A")], method.defs.map(&:implemented_in)
          end
        end
      end
    end
  end

  def test_module_alias__superclass
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
  class Bar
  end
end

module Baz = Foo

class Hoge < Baz::Bar
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Hoge"))
        builder.build_singleton(type_name("::Hoge"))
      end
    end
  end

  def test_module_alias__mixin
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Foo
end

module Bar = Foo

class Baz
  include Bar
  include Bar
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Baz"))
        builder.build_singleton(type_name("::Baz"))
      end
    end
  end

  def test_module_alias__module_self
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
class Foo = Integer

module Bar : Foo
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Bar"))
        builder.build_singleton(type_name("::Bar"))
      end
    end
  end

  def test_alias__to_module_self_indirect_method
    SignatureManager.new(system_builtin: false) do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module Kernel
  alias foo __id__
end

module Foo
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo"))
      end
    end
  end

  def test_class_var__mixin__include_defines_class_var
    SignatureManager.new() do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module M1
  @@m1: Integer
end

class Foo
  include M1
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          definition.class_variables[:@@m1].tap do |var|
            assert_instance_of Definition::Variable, var
            assert_equal type_name("::M1"), var.declared_in
            assert_nil var.parent_variable
            assert_equal "@@m1: Integer", var.source.location.source
          end
        end

        builder.build_singleton(type_name("::Foo")).tap do |definition|
          definition.class_variables[:@@m1].tap do |var|
            assert_instance_of Definition::Variable, var
            assert_equal type_name("::M1"), var.declared_in
            assert_nil var.parent_variable
            assert_equal "@@m1: Integer", var.source.location.source
          end
        end
      end
    end
  end

  def test_class_var__mixin__extend_no_class_var
    SignatureManager.new() do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module M1
  @@m1: Integer
end

class Foo
  extend M1
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          assert_nil definition.class_variables[:@@m1]
        end

        builder.build_singleton(type_name("::Foo")).tap do |definition|
          assert_nil definition.class_variables[:@@m1]
        end
      end
    end
  end

  def test_class_var__mixin__prepend_class_var
    SignatureManager.new() do |manager|
      manager.add_file("foo.rbs", <<-EOF)
module M1
  @@m1: Integer
end

class Foo
  prepend M1
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::Foo")).tap do |definition|
          definition.class_variables[:@@m1].tap do |var|
            assert_instance_of Definition::Variable, var
            assert_equal type_name("::M1"), var.declared_in
            assert_nil var.parent_variable
            assert_equal "@@m1: Integer", var.source.location.source
          end
        end

        builder.build_singleton(type_name("::Foo")).tap do |definition|
          definition.class_variables[:@@m1].tap do |var|
            assert_instance_of Definition::Variable, var
            assert_equal type_name("::M1"), var.declared_in
            assert_nil var.parent_variable
            assert_equal "@@m1: Integer", var.source.location.source
          end
        end
      end
    end
  end

  def test_duplicated_variable
    SignatureManager.new do |manager|
      manager.add_file("instance.rbs", <<-EOF)
class InstanceVariable
  @instance: Integer
  @instance: Integer
end

class AttrInstanceVariable
  attr_accessor instance: Integer
  @instance: Integer
end

class InstanceVariableAttr
  @instance: Integer
  attr_accessor instance: Integer
end

class InstanceVariableAttrInstanceVariable
  @instance: Integer
  attr_accessor instance: Integer
  @instance: Integer
end

class ClassInstanceVariableSingletonAttrClassInstanceVariable
  self.@class_instance: Integer
  attr_accessor self.class_instance: Integer
  self.@class_instance: Integer
end

class ClassInstanceVariable
  self.@class_instance: Integer
  self.@class_instance: Integer
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        assert_raises(RBS::InstanceVariableDuplicationError) do
          builder.build_instance(type_name("::InstanceVariable"))
        end
        assert_nothing_raised do
          builder.build_instance(type_name("::AttrInstanceVariable"))
        end
        assert_nothing_raised do
          builder.build_instance(type_name("::InstanceVariableAttr"))
        end
        assert_raises(RBS::InstanceVariableDuplicationError) do
          builder.build_instance(type_name("::InstanceVariableAttrInstanceVariable"))
        end
        assert_raises(RBS::ClassInstanceVariableDuplicationError) do
          builder.build_singleton(type_name("::ClassInstanceVariableSingletonAttrClassInstanceVariable"))
        end
        assert_raises(RBS::ClassInstanceVariableDuplicationError) do
          builder.build_singleton(type_name("::ClassInstanceVariable"))
        end
      end
    end
  end

  def test_annotations__method_def
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{method} def foo: %a{overload1} () -> void
                    | %a{overload2} (Integer) -> String
end

class B < A
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload1"], overload.each_annotation.map(&:string)
            end
            method.defs[1].tap do |overload|
              assert_equal ["overload2"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload2"], overload.each_annotation.map(&:string)
            end
          end
        end

        builder.build_instance(type_name("::B")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload1"], overload.each_annotation.map(&:string)
            end
            method.defs[1].tap do |overload|
              assert_equal ["overload2"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload2"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_annotations__method_attribute
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{attribute} attr_accessor foo: String
end

class B < A
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["attribute"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal [], overload.overload_annotations.map(&:string)
              assert_equal ["attribute"], overload.each_annotation.map(&:string)
            end
          end
          definition.methods[:foo=].tap do |method|
            assert_equal ["attribute"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal [], overload.overload_annotations.map(&:string)
              assert_equal ["attribute"], overload.each_annotation.map(&:string)
            end
          end
        end

        builder.build_instance(type_name("::B")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["attribute"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal [], overload.overload_annotations.map(&:string)
              assert_equal ["attribute"], overload.each_annotation.map(&:string)
            end
          end
          definition.methods[:foo=].tap do |method|
            assert_equal ["attribute"], method.annotations.map(&:string)
            method.defs[0].tap do |overload|
              assert_equal [], overload.overload_annotations.map(&:string)
              assert_equal ["attribute"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_annotations__method_def_overloading
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{method1} def foo: %a{overload1} () -> void

  %a{method2} def foo: %a{overload2} (Integer) -> void
                     | ...
end

class B < A
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method1", "method2"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload2"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload2"], overload.each_annotation.map(&:string)
            end
            method.defs[1].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload1"], overload.each_annotation.map(&:string)
            end
          end
        end

        builder.build_instance(type_name("::B")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method1", "method2"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload2"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload2"], overload.each_annotation.map(&:string)
            end
            method.defs[1].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload1"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_annotations__method_def_overloading_super
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{method1} def foo: %a{overload1} () -> void
end

class B < A
  %a{method2} def foo: %a{overload2} () -> void
                     | ...
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method1"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "overload1"], overload.each_annotation.map(&:string)
            end
          end
        end

        builder.build_instance(type_name("::B")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method1", "method2"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload2"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload2"], overload.each_annotation.map(&:string)
            end
            method.defs[1].tap do |overload|
              assert_equal ["overload1"], overload.overload_annotations.map(&:string)
              assert_equal ["method1", "method2", "overload1"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_annotations__method_alias
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{method} def foo: %a{overload} () -> void

  %a{alias1} alias bar foo
end

class B < A
  %a{alias2} alias baz bar
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload"], overload.each_annotation.map(&:string)
            end
          end

          definition.methods[:bar].tap do |method|
            assert_equal ["alias1"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["alias1", "overload"], overload.each_annotation.map(&:string)
            end
          end
        end

        builder.build_instance(type_name("::B")).tap do |definition|
          definition.methods[:foo].tap do |method|
            assert_equal ["method"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["method", "overload"], overload.each_annotation.map(&:string)
            end
          end

          definition.methods[:bar].tap do |method|
            assert_equal ["alias1"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["alias1", "overload"], overload.each_annotation.map(&:string)
            end
          end

          definition.methods[:baz].tap do |method|
            assert_equal ["alias2"], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["alias2", "overload"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_annotations__new_method
    SignatureManager.new do |manager|
      manager.add_file("inherited.rbs", <<-EOF)
class A
  %a{method} def initialize: %a{overload} () -> void
end
      EOF

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_singleton(type_name("::A")).tap do |definition|
          definition.methods[:new].tap do |method|
            assert_equal [], method.annotations.map(&:string)

            method.defs[0].tap do |overload|
              assert_equal ["overload"], overload.overload_annotations.map(&:string)
              assert_equal ["overload"], overload.each_annotation.map(&:string)
            end
          end
        end
      end
    end
  end

  def test_inline_decl__class
    SignatureManager.new do |manager|
      manager.add_ruby_file("inherited.rbs", <<~RUBY)
        class A
        end
      RUBY

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:__id__].tap do |method|
            assert_equal type_name("::Object"), method.defined_in
          end
        end

        builder.build_singleton(type_name("::A")).tap do |definition|
          definition.methods[:new].tap do |method|
            assert_equal type_name("::BasicObject"), method.defined_in
          end
        end
      end
    end
  end

  def test_inline_decl__module
    SignatureManager.new do |manager|
      manager.add_ruby_file("inherited.rbs", <<~RUBY)
        module A
        end
      RUBY

      manager.build do |env|
        builder = DefinitionBuilder.new(env: env)

        builder.build_instance(type_name("::A")).tap do |definition|
          definition.methods[:__id__].tap do |method|
            assert_equal type_name("::Object"), method.defined_in
          end
        end

        builder.build_singleton(type_name("::A")).tap do |definition|
          definition.methods[:__id__].tap do |method|
            assert_equal type_name("::Object"), method.defined_in
          end
        end
      end
    end
  end
end

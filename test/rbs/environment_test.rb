require "test_helper"

class RBS::EnvironmentTest < Minitest::Test
  include TestHelper

  Environment = RBS::Environment
  Namespace = RBS::Namespace
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError

  def test_entry_context
    decls = RBS::Parser.parse_signature(<<EOF)
class Foo
  module Bar
    module Baz
    end
  end
end
EOF

    entry = Environment::SingleEntry.new(
      name: type_name("::Foo::Bar::Baz"),
      decl: decls[0].members[0].members[0],
      outer: [
        decls[0],
        decls[0].members[0],
      ]
    )

    assert_equal [
                   type_name("::Foo::Bar::Baz").to_namespace,
                   type_name("::Foo::Bar").to_namespace,
                   type_name("::Foo").to_namespace,
                   Namespace.root
                 ],
                 entry.context
  end

  def test_insert_decl_nested_modules
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
class Foo
  module Bar
  end

  module ::Baz
  end
end
EOF

    env << decls[0]

    assert_operator env.class_decls, :key?, type_name("::Foo")
    assert_operator env.class_decls, :key?, type_name("::Foo::Bar")
    assert_operator env.class_decls, :key?, type_name("::Baz")
  end

  def test_insert_decl_open_class
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
class Foo
  module Bar
  end
end

class Foo < String
  module Bar
  end
end
EOF

    env << decls[0]
    env << decls[1]

    env.class_decls[type_name("::Foo")].tap do |entry|
      assert_instance_of Environment::ClassEntry, entry
      assert_equal 2, entry.decls.size
      assert_equal type_name("String"), entry.primary.decl.super_class.name
    end

    env.class_decls[type_name("::Foo::Bar")].tap do |entry|
      assert_instance_of Environment::ModuleEntry, entry
      assert_equal 2, entry.decls.size
    end
  end

  def test_insert_decl_const_duplication_error
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
module Foo
end

Bar: ::Integer

Foo: String

class Bar
end
EOF

    env << decls[0]
    env << decls[1]

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[2]
    end

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[3]
    end
  end

  def test_class_module_mix
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
module Foo
end

class Foo
end
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[0]
      env << decls[1]
    end
  end

  def test_const_twice_duplication_error
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
Foo: String
Foo: String
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[0]
      env << decls[1]
    end
  end

  def test_generic_class
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
module Foo[A, out B]
end

module Foo[X, out Y]     # ok
end

module Foo[A]            # # of params mismatch
end

module Foo[X, in Y]      # Variance mismatch
end
EOF

    # The GenericParameterMismatchError raises on #type_params call
    env << decls[0]
    env << decls[1]
    env << decls[2]
    env << decls[3]
  end

  def test_generic_class_error
    decls = RBS::Parser.parse_signature(<<EOF)
module Foo[A, out B]
end

module Foo[X, out Y]
end

module Foo[A]
end

module Foo[X, in Y]
end
EOF

    Environment::ModuleEntry.new(name: type_name("::Foo")).tap do |entry|
      entry.insert(decl: decls[0], outer: [])
      entry.insert(decl: decls[1], outer: [])

      assert_instance_of RBS::AST::Declarations::ModuleTypeParams, entry.type_params
    end

    Environment::ModuleEntry.new(name: type_name("::Foo")).tap do |entry|
      entry.insert(decl: decls[0], outer: [])
      entry.insert(decl: decls[2], outer: [])

      assert_raises RBS::GenericParameterMismatchError do
        entry.type_params
      end
    end

    Environment::ModuleEntry.new(name: type_name("::Foo")).tap do |entry|
      entry.insert(decl: decls[0], outer: [])
      entry.insert(decl: decls[3], outer: [])

      assert_raises RBS::GenericParameterMismatchError do
        entry.type_params
      end
    end
  end

  def test_insert_global
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
$VERSION: String
EOF

    env << decls[0]

    assert_operator env.global_decls, :key?, :$VERSION
  end

  def test_module_self_type
    decls = RBS::Parser.parse_signature(<<EOF)
interface _Animal
  def bark: () -> void
end

module Foo : _Animal
  def foo: () -> void
end

module Foo : Object
  def bar: () -> void
end

module Bar : _Animal
end

module Bar : _Animal
end
EOF

    Environment.new.tap do |env|
      env << decls[0]
      env << decls[1]
      env << decls[2]

      foo = env.class_decls[type_name("::Foo")]

      assert_equal decls[1], foo.primary.decl
      assert_equal [
                     RBS::AST::Declarations::Module::Self.new(
                       name: type_name("_Animal"),
                       args: [],
                       location: nil
                     ),
                     RBS::AST::Declarations::Module::Self.new(
                       name: type_name("Object"),
                       args: [],
                       location: nil
                     ),
                   ], foo.self_types
    end

    Environment.new.tap do |env|
      env << decls[0]
      env << decls[3]
      env << decls[4]

      foo = env.class_decls[type_name("::Bar")]

      assert_equal decls[3], foo.primary.decl
    end
  end

  def test_absolute_type
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
# Integer is undefined and the type is left relative.
# (Will be an error afterward.)
#
class Hello < String
  def hello: (String) -> Integer
end

module Foo : _Each[String]
  attr_reader name: String
  attr_accessor size: Integer
  attr_writer email (@foo): ::String

  @created_at: Time
  self.@last_timestamp: Time?
  @@max_size: Integer

  include Enumerable[Integer]

  extend _Each[untyped]

  prepend Operator

  VERSION: ::String

  type t = ::String | String

  $size: Integer

  class String
  end

  interface _Each[A]
    def each: () { (A) -> void } -> void
  end

  module Operator
  end
end

class String end
class Time end
module Enumerable[A] end
EOF

    decls.each do |decl|
      env << decl
    end

    env_ = env.resolve_type_names

    writer = RBS::Writer.new(out: StringIO.new)

    writer.write(env_.declarations)

    assert_equal <<RBS, writer.out.string
# Integer is undefined and the type is left relative.
# (Will be an error afterward.)
#
class ::Hello < ::String
  def hello: (::String) -> Integer
end

module ::Foo : ::Foo::_Each[::Foo::String]
  attr_reader name: ::Foo::String

  attr_accessor size: Integer

  attr_writer email(@foo): ::String

  @created_at: ::Time

  self.@last_timestamp: ::Time?

  @@max_size: Integer

  include ::Enumerable[Integer]

  extend ::Foo::_Each[untyped]

  prepend ::Foo::Operator

  ::Foo::VERSION: ::String

  type ::Foo::t = ::String | ::Foo::String

  $size: Integer

  class ::Foo::String
  end

  interface ::Foo::_Each[A]
    def each: () { (A) -> void } -> void
  end

  module ::Foo::Operator
  end
end

class ::String
end
class ::Time
end
module ::Enumerable[A]
end
RBS
  end

  def test_absolute_type_unknown
    env = Environment.new

    decls = RBS::Parser.parse_signature(<<EOF)
# Integer is undefined and the type is translated to untyped.
# Super classes and mixin modules are exception.
#
class Hello < Integer
  def hello: (String) -> Integer
end

module Foo : _Each[Integer]
  attr_accessor size: Integer
  @created_at: Integer

  include Enumerable[Integer]
  include Integer
  prepend Integer

  module Operator : Integer
  end
end

class String end
class Time end
module Enumerable[A] end
EOF

    decls.each do |decl|
      env << decl
    end

    env_ = env.resolve_type_names(unknown_to_untyped: Set[])

    writer = RBS::Writer.new(out: StringIO.new)

    writer.write(env_.declarations)

    assert_equal <<RBS, writer.out.string
# Integer is undefined and the type is translated to untyped.
# Super classes and mixin modules are exception.
#
class ::Hello < Integer
  def hello: (::String) -> untyped
end

module ::Foo : _Each[untyped]
  attr_accessor size: untyped

  @created_at: untyped

  include ::Enumerable[untyped]

  include Integer

  prepend Integer

  module ::Foo::Operator : Integer
  end
end

class ::String
end
class ::Time
end
module ::Enumerable[A]
end
RBS
  end
end

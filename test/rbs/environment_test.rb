require "test_helper"

class RBS::EnvironmentTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  Namespace = RBS::Namespace
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError

  def test_entry_context
    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

    assert_equal [[nil, type_name("::Foo")], type_name("::Foo::Bar")],
                 entry.context
  end

  def test_insert_decl_nested_modules
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

  def test_insert_class_module_alias
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
module RBS
  module Kernel = ::Kernel

  class RbObject = Object
end
EOF

    decls.each do |decl|
      env << decl
    end

    env.class_alias_decls[TypeName("::RBS::Kernel")].tap do |decl|
      assert_instance_of Environment::ModuleAliasEntry, decl
    end
  end

  def test_class_alias_open
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<~EOF)
      module Foo = Kernel

      module Foo
      end
    EOF

    env << decls[0]

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[1]
    end
  end

  def test_insert_decl_open_class
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
Foo: String
Foo: String
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[0]
      env << decls[1]
    end
  end

  def test_type_alias_twice_duplication_error
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
type foo = String
type foo = Integer
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[0]
      env << decls[1]
    end
  end

  def test_interface_twice_duplication_error
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
interface _I
end
interface _I
end
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env << decls[0]
      env << decls[1]
    end
  end

  def test_generic_class
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
module Foo[A, out B]
end

module Foo[X, out Y]     # ok
end

module Foo[A]            # # of params mismatch
end

module Foo[X, in Y]      # Variance mismatch
end
EOF

    env << decls[0]
    env << decls[1]
    env << decls[2]
    env << decls[3]

    assert_raises RBS::GenericParameterMismatchError do
      env.validate_type_params()
    end
  end

  def test_generic_class_error
    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

      assert_instance_of Array, entry.type_params
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

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
$VERSION: String
EOF

    env << decls[0]

    assert_operator env.global_decls, :key?, :$VERSION
  end

  def test_module_self_type
    _, _, decls = RBS::Parser.parse_signature(<<EOF)
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

    buf, dirs, decls = RBS::Parser.parse_signature(<<EOF)
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

    env.add_signature(buffer: buf, directives: dirs, decls: decls)

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

  def test_absolute_type_super
    env = Environment.new

    buf, dirs, decls = RBS::Parser.parse_signature(<<-RBS)
module A
  class C
  end

  class B < C
    class C
    end
  end
end
    RBS

    env.add_signature(buffer: buf, directives: dirs, decls: decls)

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[TypeName("::A::B")]
      assert_equal TypeName("::A::C"), class_decl.primary.decl.super_class.name
    end
  end

  def test_absolute_type_generics_upper_bound
    env = Environment.new

    buf, dirs, decls = RBS::Parser.parse_signature(<<RBS)
interface _Equatable
  def ==: (untyped) -> bool
end

module Bar[A]
end

class Foo[A < _Equatable]
  def test: [B < Bar[_Equatable]] (A, B) -> bool
end
RBS

    env.add_signature(buffer: buf, directives: dirs, decls: decls)

    env_ = env.resolve_type_names

    writer = RBS::Writer.new(out: StringIO.new)

    writer.write(env_.declarations)

    assert_equal(<<RBS, writer.out.string)
interface ::_Equatable
  def ==: (untyped) -> bool
end

module ::Bar[A]
end

class ::Foo[A < ::_Equatable]
  def test: [B < ::Bar[::_Equatable]] (A, B) -> bool
end
RBS
  end

  def test_normalize_module_name
    buf, dirs, decls = RBS::Parser.parse_signature(<<~EOF)
      class Foo
        module Bar
          module Baz
          end
        end
      end

      module M = Foo::Bar
      module N = M::Baz
    EOF


    env = Environment.new()
    env.add_signature(buffer: buf, directives: dirs, decls: decls)

    env = env.resolve_type_names

    assert_equal type_name("::Foo::Bar"), env.normalize_module_name(type_name("::M"))
    assert_equal type_name("::Foo::Bar::Baz"), env.normalize_module_name(type_name("::N"))
  end

  def test_use_resolve
    buf, dirs, decls = RBS::Parser.parse_signature(<<-RBS)
use Object as OB

class Foo < OB
end

class OB
end
    RBS

    env = Environment.new
    env.add_signature(buffer: buf, directives: dirs, decls: decls)

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[TypeName("::Foo")]
      assert_equal TypeName("::Object"), class_decl.primary.decl.super_class.name

      assert_operator env.class_decls, :key?, TypeName("::OB")
    end
  end
end

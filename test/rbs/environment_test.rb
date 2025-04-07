require "test_helper"

class RBS::EnvironmentTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  Namespace = RBS::Namespace
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError

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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)

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
      env.insert_rbs_decl(decl, context: nil, namespace: RBS::Namespace.root)
    end

    env.class_alias_decls[RBS::TypeName.parse("::RBS::Kernel")].tap do |decl|
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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)

    assert_raises RBS::DuplicatedDeclarationError do
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
    env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)

    env.class_decls[type_name("::Foo")].tap do |entry|
      assert_instance_of Environment::ClassEntry, entry
      assert_equal 2, entry.each_decl.count
      assert_equal type_name("String"), entry.primary_decl.super_class.name
    end

    env.class_decls[type_name("::Foo::Bar")].tap do |entry|
      assert_instance_of Environment::ModuleEntry, entry
      assert_equal 2, entry.each_decl.count
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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
    env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)

    assert_raises RBS::DuplicatedDeclarationError do
      env.insert_rbs_decl(decls[2], context: nil, namespace: RBS::Namespace.root)
    end

    assert_raises RBS::DuplicatedDeclarationError do
      env.insert_rbs_decl(decls[3], context: nil, namespace: RBS::Namespace.root)
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
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
    end
  end

  def test_const_twice_duplication_error
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
Foo: String
Foo: String
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
    end
  end

  def test_type_alias_twice_duplication_error
    env = Environment.new

    _, _, decls = RBS::Parser.parse_signature(<<EOF)
type foo = String
type foo = Integer
EOF

    assert_raises RBS::DuplicatedDeclarationError do
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
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
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
    env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
    env.insert_rbs_decl(decls[2], context: nil, namespace: RBS::Namespace.root)
    env.insert_rbs_decl(decls[3], context: nil, namespace: RBS::Namespace.root)

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
      entry << [nil, decls[0]]
      entry << [nil, decls[1]]

      assert_instance_of Array, entry.type_params
    end

    Environment::ModuleEntry.new(name: type_name("::Foo")).tap do |entry|
      entry << [nil, decls[0]]
      entry << [nil, decls[2]]

      assert_raises RBS::GenericParameterMismatchError do
        entry.type_params
      end
    end

    Environment::ModuleEntry.new(name: type_name("::Foo")).tap do |entry|
      entry << [nil, decls[0]]
      entry << [nil, decls[3]]

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

    env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)

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
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[1], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[2], context: nil, namespace: RBS::Namespace.root)

      foo = env.class_decls[type_name("::Foo")]

      assert_equal decls[1], foo.primary_decl
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
      env.insert_rbs_decl(decls[0], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[3], context: nil, namespace: RBS::Namespace.root)
      env.insert_rbs_decl(decls[4], context: nil, namespace: RBS::Namespace.root)

      foo = env.class_decls[type_name("::Bar")]

      assert_equal decls[3], foo.primary_decl
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

    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env_ = env.resolve_type_names

    writer = RBS::Writer.new(out: StringIO.new)

    writer.write(env_.each_rbs_source.flat_map { _1.declarations })

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

    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[RBS::TypeName.parse("::A::B")]
      assert_equal RBS::TypeName.parse("::A::C"), class_decl.primary_decl.super_class.name
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

    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env_ = env.resolve_type_names

    writer = RBS::Writer.new(out: StringIO.new)

    writer.write(env_.each_rbs_source.flat_map { _1.declarations })

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
    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

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
    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[RBS::TypeName.parse("::Foo")]
      assert_equal RBS::TypeName.parse("::Object"), class_decl.primary_decl.super_class.name

      assert_operator env.class_decls, :key?, RBS::TypeName.parse("::OB")
    end
  end

  def test_resolve_type_names_magic_comment
    buf, dirs, decls = RBS::Parser.parse_signature(<<-RBS)
# resolve-type-names: false

type t = s

type s = untyped
    RBS

    env = Environment.new
    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env.resolve_type_names.tap do |env|
      alias_decl = env.type_alias_decls[RBS::TypeName.parse("::t")]
      assert_equal "s", alias_decl.decl.type.to_s
    end
  end

  def test_resolve_type_names_magic_comment__true
    buf, dirs, decls = RBS::Parser.parse_signature(<<-RBS)
# resolve-type-names: true

type t = s

type s = untyped
    RBS

    env = Environment.new
    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env.resolve_type_names.tap do |env|
      alias_decl = env.type_alias_decls[RBS::TypeName.parse("::t")]
      assert_equal "::s", alias_decl.decl.type.to_s
    end
  end

  def parse_inline(src)
    buffer = RBS::Buffer.new(name: Pathname("a.rb"), content: src)
    prism = Prism.parse(src)

    RBS::InlineParser.parse(buffer, prism)
  end

  def test__ruby__insert_decl_class
    result = parse_inline(<<~RUBY)
      class Hello
        module World
        end
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))

    assert_operator env.class_decls, :key?, type_name("::Hello")
    assert_operator env.class_decls, :key?, type_name("::Hello::World")
  end

  def test__ruby__absolute_class_module_name
    result = parse_inline(<<~RUBY)
      class Hello
        module World
        end
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[RBS::TypeName.parse("::Hello")]
      class_decl.each_decl do |decl|
        assert_equal RBS::TypeName.parse("::Hello"), decl.class_name
      end

      module_decl = env.class_decls[RBS::TypeName.parse("::Hello::World")]
      module_decl.each_decl do |decl|
        assert_equal RBS::TypeName.parse("::Hello::World"), decl.module_name
      end
    end
  end
end

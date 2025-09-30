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

  def test_absolute_type_generics_lower_bound
    env = Environment.new

    buf, dirs, decls = RBS::Parser.parse_signature(<<RBS)
interface _Equatable
  def ==: (untyped) -> bool
end

module Bar[A]
end

class Foo[A > _Equatable]
  def test: [B > Bar[_Equatable]] (A, B) -> bool
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

class ::Foo[A > ::_Equatable]
  def test: [B > ::Bar[::_Equatable]] (A, B) -> bool
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

  def test_resolve_type_names_module_alias
    buf, dirs, decls = RBS::Parser.parse_signature(<<-RBS)
module M
  module N
  end

  module N2 = N
end

class C
  include M::N2
end
    RBS

    env = Environment.new
    env.add_source(RBS::Source::RBS.new(buf, dirs, decls))

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[RBS::TypeName.parse("::C")]
      class_decl.each_decl do |decl|
        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::Include, member
          assert_equal RBS::TypeName.parse("::M::N"), member.name
        end
      end
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

  def test__ruby__resolve_type_names_mixin_members
    result = parse_inline(<<~RUBY)
      module M
      end

      class String
      end

      class Integer
      end

      class A
        include M #[String]
      end

      class B
        extend M #[String, Integer]
      end

      class C
        prepend M #[Integer]
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))

    env.resolve_type_names.tap do |env|
      # Test A include
      a_decl = env.class_decls[RBS::TypeName.parse("::A")]
      a_decl.each_decl do |decl|
        decl.members.each do |member|
          case member
          when RBS::AST::Ruby::Members::IncludeMember
            assert_equal RBS::TypeName.parse("::M"), member.module_name
            assert_equal 1, member.type_args.size
            # Type argument should be resolved to absolute TypeName
            assert_equal RBS::TypeName.parse("::String"), member.type_args[0].name
          end
        end
      end

      # Test B extend
      b_decl = env.class_decls[RBS::TypeName.parse("::B")]
      b_decl.each_decl do |decl|
        decl.members.each do |member|
          case member
          when RBS::AST::Ruby::Members::ExtendMember
            assert_equal RBS::TypeName.parse("::M"), member.module_name
            assert_equal 2, member.type_args.size
            # Both type arguments should be resolved to absolute TypeNames
            assert_equal RBS::TypeName.parse("::String"), member.type_args[0].name
            assert_equal RBS::TypeName.parse("::Integer"), member.type_args[1].name
          end
        end
      end

      # Test C prepend
      c_decl = env.class_decls[RBS::TypeName.parse("::C")]
      c_decl.each_decl do |decl|
        decl.members.each do |member|
          case member
          when RBS::AST::Ruby::Members::PrependMember
            assert_equal RBS::TypeName.parse("::M"), member.module_name
            assert_equal 1, member.type_args.size
            # Type argument should be resolved to absolute TypeName
            assert_equal RBS::TypeName.parse("::Integer"), member.type_args[0].name
          end
        end
      end
    end
  end

  def test__ruby__multiple_decls
    result = parse_inline(<<~RUBY)
      class Hello
      end

      class Hello
      end

      module World
      end

      module World
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))

    env.resolve_type_names.tap do |env|
      class_decl = env.class_decls[RBS::TypeName.parse("::Hello")]
      assert_equal 2, class_decl.context_decls.size

      module_decl = env.class_decls[RBS::TypeName.parse("::World")]
      assert_equal 2, module_decl.context_decls.size
    end
  end

  def test__ruby__constant_declarations
    result = parse_inline(<<~RUBY)
      A = "123"
      B = [1, 2] #: Object
      Object::FOO = :FOO

      class Object
        BAR = "BAR"
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))
    resolved_env = env.resolve_type_names

    # Check top-level constant A with inferred type
    assert_operator resolved_env.constant_decls, :key?, type_name("::A")
    resolved_env.constant_decls[type_name("::A")].tap do |entry|
      assert_equal type_name("::A"), entry.name
      assert_equal "::String", entry.decl.type.to_s
    end

    # Check top-level constant B with type annotation
    assert_operator resolved_env.constant_decls, :key?, type_name("::B")
    resolved_env.constant_decls[type_name("::B")].tap do |entry|
      assert_equal type_name("::B"), entry.name
      assert_equal "::Object", entry.decl.type.to_s
    end

    # Check constant path Object::FOO
    assert_operator resolved_env.constant_decls, :key?, type_name("::Object::FOO")
    resolved_env.constant_decls[type_name("::Object::FOO")].tap do |entry|
      assert_equal type_name("::Object::FOO"), entry.name
      assert_equal "::Symbol", entry.decl.type.to_s
    end

    # Check constant inside class Object
    assert_operator resolved_env.constant_decls, :key?, type_name("::Object::BAR")
    resolved_env.constant_decls[type_name("::Object::BAR")].tap do |entry|
      assert_equal type_name("::Object::BAR"), entry.name
      assert_equal "::String", entry.decl.type.to_s
    end

    # Verify that Object class is created
    assert_operator resolved_env.class_decls, :key?, type_name("::Object")
  end

  def test__ruby__class_alias_declarations
    result = parse_inline(<<~RUBY)
      class String
      end
      class Object
      end
      class Array
      end

      # Basic class alias without explicit type name
      MyString = String #: class-alias

      # Class alias with explicit type name
      MyObject = some_object_factory #: class-alias Object

      # Class alias with namespace
      MyArray = Array #: class-alias

      # Nested class alias
      module Container
        InnerString = String #: class-alias
      end
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))
    resolved_env = env.resolve_type_names

    # Check basic class alias without explicit type name
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::MyString")
    resolved_env.class_alias_decls[type_name("::MyString")].tap do |entry|
      assert_instance_of Environment::ClassAliasEntry, entry
      assert_equal type_name("::MyString"), entry.name
      assert_equal type_name("::String"), entry.decl.old_name
    end

    # Check class alias with explicit type name
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::MyObject")
    resolved_env.class_alias_decls[type_name("::MyObject")].tap do |entry|
      assert_instance_of Environment::ClassAliasEntry, entry
      assert_equal type_name("::MyObject"), entry.name
      assert_equal type_name("::Object"), entry.decl.old_name
    end

    # Check class alias with Array
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::MyArray")
    resolved_env.class_alias_decls[type_name("::MyArray")].tap do |entry|
      assert_instance_of Environment::ClassAliasEntry, entry
      assert_equal type_name("::MyArray"), entry.name
      assert_equal type_name("::Array"), entry.decl.old_name
    end

    # Check nested class alias
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::Container::InnerString")
    resolved_env.class_alias_decls[type_name("::Container::InnerString")].tap do |entry|
      assert_instance_of Environment::ClassAliasEntry, entry
      assert_equal type_name("::Container::InnerString"), entry.name
      assert_equal type_name("::String"), entry.decl.old_name
    end

    # Verify Container module is created
    assert_operator resolved_env.class_decls, :key?, type_name("::Container")
  end

  def test__ruby__module_alias_declarations
    result = parse_inline(<<~RUBY)
      module Kernel
      end

      module Enumerable
      end

      # Basic module alias without explicit type name
      MyKernel = Kernel #: module-alias

      # Module alias with explicit type name
      MyEnum = some_enumerable_factory #: module-alias Enumerable
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))
    resolved_env = env.resolve_type_names

    # Check basic module alias without explicit type name
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::MyKernel")
    resolved_env.class_alias_decls[type_name("::MyKernel")].tap do |entry|
      assert_instance_of Environment::ModuleAliasEntry, entry
      assert_equal type_name("::MyKernel"), entry.name
      assert_equal type_name("::Kernel"), entry.decl.old_name
    end

    # Check module alias with explicit type name
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::MyEnum")
    resolved_env.class_alias_decls[type_name("::MyEnum")].tap do |entry|
      assert_instance_of Environment::ModuleAliasEntry, entry
      assert_equal type_name("::MyEnum"), entry.name
      assert_equal type_name("::Enumerable"), entry.decl.old_name
    end
  end

  def test__ruby__class_module_alias_with_skip_annotation
    result = parse_inline(<<~RUBY)
      # @rbs skip
      SkippedString = String #: class-alias

      # This should be processed
      ProcessedString = String #: class-alias

      # @rbs skip
      SkippedKernel = Kernel #: module-alias

      # This should be processed
      ProcessedKernel = Kernel #: module-alias
    RUBY

    env = Environment.new
    env.add_source(RBS::Source::Ruby.new(result.buffer, result.prism_result, result.declarations, result.diagnostics))
    resolved_env = env.resolve_type_names

    # Check that skipped aliases are not present
    refute_operator resolved_env.class_alias_decls, :key?, type_name("::SkippedString")
    refute_operator resolved_env.class_alias_decls, :key?, type_name("::SkippedKernel")

    # Check that non-skipped aliases are present
    assert_operator resolved_env.class_alias_decls, :key?, type_name("::ProcessedString")
    assert_instance_of Environment::ClassAliasEntry, resolved_env.class_alias_decls[type_name("::ProcessedString")]

    assert_operator resolved_env.class_alias_decls, :key?, type_name("::ProcessedKernel")
    assert_instance_of Environment::ModuleAliasEntry, resolved_env.class_alias_decls[type_name("::ProcessedKernel")]
  end
end

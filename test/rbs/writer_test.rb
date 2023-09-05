require "test_helper"

class RBS::WriterTest < Test::Unit::TestCase
  include TestHelper

  Parser = RBS::Parser
  Writer = RBS::Writer

  def format(sig, preserve: false)
    Parser.parse_signature(sig).then do |_, dirs, decls|
      writer = Writer.new(out: StringIO.new).preserve!(preserve: preserve)
      writer.write(dirs + decls)

      writer.out.string
    end
  end

  def assert_writer(sig, preserve: false)
    assert_equal sig, format(sig, preserve: preserve)
  end

  def test_const_decl
    assert_writer <<-SIG
# World to world.
# This is a ruby code?
Hello::World: Integer
    SIG
  end

  def test_global_decl
    assert_writer <<-SIG
$name: String
    SIG
  end

  def test_alias_decl
    assert_writer <<-SIG
type ::Module::foo = String | Integer
class A = B
module C = D
    SIG
  end

  def test_class_decl
    assert_writer <<-SIG
class Foo::Bar[X] < Array[String]
  %a{This is enumerable}
  include Enumerable[Integer, void]

  extend _World

  prepend Hello

  attr_accessor name: String

  attr_reader age(): Integer

  attr_writer email(@foo): String?

  attr_accessor self.name: String

  attr_reader self.age(): Integer

  attr_writer self.email(@foo): String?

  public

  private

  alias self.id self.identifier

  alias to_s to_str

  @alias: Foo

  self.@hello: "world"

  @@size: 100

  def to_s: () -> String
          | (padding: Integer) -> String

  def self.hello: () -> Integer

  def self?.world: () -> :sym
end
    SIG
  end

  def test_module_decl
    assert_writer <<-SIG
module X : Foo
end
    SIG
  end

  def test_interface_decl
    assert_writer <<-SIG
interface _Each[X, Y]
  def each: () { (X) -> void } -> Y
end
    SIG
  end

  def test_escape
    assert_writer <<-SIG
module XYZZY[X, Y]
  def []: () -> void

  def []=: () -> void

  def !: () -> void

  def __id__: () -> Integer

  def def: () -> Symbol

  def self: () -> void

  def self?: () -> void

  def timeout: () -> Integer

  def `foo!=`: () -> Integer

  def `: (String) -> untyped

  attr_accessor `a-b`: String

  attr_reader `a-b`: String

  attr_writer `a-b`: String

  attr_accessor self.`a-b`: String

  attr_reader self.`a-b`: String

  attr_writer self.`a-b`: String

  alias `b-a` `a-b`

  alias self.`b-a` self.`a-b`
end
    SIG
  end

  def test_variance
    assert_writer <<-SIG
class Foo[out A, unchecked B, in C] < Bar[A, C, B]
end
    SIG
  end

  def test_generic_alias
    assert_writer <<-SIG
type foo[Bar] = Baz
    SIG
  end

  def test_overload
    assert_writer <<-SIG
class Foo
  def foo: (Integer) -> String
         | ...

  def foo: () -> String
end
    SIG
  end

  def test_nested
    assert_writer <<-SIG
module RBS
  VERSION: String

  class TypeName
    type t = interned
  end
end
    SIG
  end

  def test_preserve_empty_line
    assert_writer <<-SIG
class Foo
  def initialize: () -> void
  def foo: () -> void

  def bar: () -> void
  # comment
  def self.foo: () -> void

  # comment
  def baz: () -> void
end
module Bar
end

class OneEmptyLine
end

# comment
class C
end
# comment
class D
end
    SIG
  end

  def test_remove_double_empty_lines
    src = <<-SIG
class Foo

  def foo: () -> void


  def bar: () -> void
end


module Bar


  def foo: () -> void
end
    SIG

    expected = <<-SIG
class Foo
  def foo: () -> void

  def bar: () -> void
end

module Bar
  def foo: () -> void
end
    SIG

    assert_equal expected, format(src)
  end

  def test_generic_method
    assert_writer(<<-SIG)
class Foo[unchecked out T < String]
  def foo: [A < _Each[Foo], B < singleton(::Bar)] () -> A
end
    SIG
  end

  def test_smoke
    Pathname.glob('{stdlib,core,sig}/**/*.rbs').each do |path|
      _, _, orig_decls = RBS::Parser.parse_signature(
        RBS::Buffer.new(name: path, content: path.read)
      )

      io = StringIO.new
      w = RBS::Writer.new(out: io)
      w.write(orig_decls)
      _, _, decls = RBS::Parser.parse_signature(RBS::Buffer.new(name: path, content: io.string))

      assert_equal orig_decls, decls, "(#{path})"
    end
  end

  def test_alias
    assert_writer <<-SIG, preserve: true
class Foo
  type t = Integer
         | String
         | [Foo, Bar]
end
    SIG
  end

  def test_record_type
    assert_writer <<-SIG, preserve: false
class Foo
  type t = { m1: ::Message::init? }
end
    SIG
  end

  def test_write_method_def
    assert_writer <<-SIG, preserve: true
class Foo
  def foo: () -> String
         | () {
             () -> void
           } -> bool
          | (
              *String,
              id: Integer?,
              name: String,
              email: String, **untyped
            ) -> void
end
    SIG
  end

  def test_write_visibility_modifier
    assert_writer <<-SIG, preserve: true
class Foo
  private def foo: () -> String

  public def bar: () -> String

  def baz: () -> String

  private attr_reader name: String
end
    SIG
  end

  def test_use
    assert_writer(<<~SIG)
      use Foo::Bar
      use Foo::Bar as FB, Baz::*

      $hoge: Foo
    SIG
  end
end

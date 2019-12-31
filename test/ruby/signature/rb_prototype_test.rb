require "test_helper"

class Ruby::Signature::RbPrototypeTest < Minitest::Test
  RB = Ruby::Signature::Prototype::RB

  include TestHelper

  def test_class_module
    parser = RB.new

    rb = <<-EOR
class Hello
end

class World < Hello
end

module Foo
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class Hello
end

class World < Hello
end

module Foo
end
    EOF
  end

  def test_defs
    parser = RB.new

    rb = <<-EOR
class Hello
  def hello(a, b = 3, *c, d, e:, f: 3, **g, &h)
  end

  def self.world
    yield
    yield 1, x: 3
    yield 1, 2, x: 3, y: 2
    yield 1, 2, 'hello' => world 
  end
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class Hello
  def hello: (untyped a, ?::Integer b, *untyped c, untyped d, e: untyped e, ?f: ::Integer f, **untyped g) { () -> untyped } -> untyped

  def self.world: () { (untyped, untyped, untyped, x: untyped, y: untyped) -> untyped } -> untyped
end
    EOF
  end

  def test_sclass
    parser = RB.new

    rb = <<-EOR
class Hello
  class << self
    def hello() end
  end
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class Hello
  def self.hello: () -> untyped
end
    EOF
  end

  def test_meta_programming
    parser = RB.new

    rb = <<-EOR
class Hello
  include Foo
  extend ::Bar, baz

  attr_reader :x
  attr_accessor :y, :z
  attr_writer foo, :a
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class Hello
  include Foo

  extend ::Bar

  attr_reader x: untyped

  attr_accessor y: untyped

  attr_accessor z: untyped

  attr_writer a: untyped
end
    EOF
  end

  def test_comments
    parser = RB.new

    rb = <<-EOR
# Comments for class.
# This is a comment.
class Hello
  # Comment for include.
  include Foo

  # Comment to be ignored

  # Comment for extend
  extend ::Bar, baz

  # Comment for hello
  def hello()
  end

  # Comment for world
  def self.world
  end

  # Comment for attr_reader
  attr_reader :x

  # Comment for attr_accessor
  attr_accessor :y, :z

  # Comment for attr_writer
  attr_writer foo, :a
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
# Comments for class.
# This is a comment.
class Hello
  # Comment for include.
  include Foo

  # Comment for extend
  extend ::Bar

  # Comment for hello
  def hello: () -> untyped

  # Comment for world
  def self.world: () -> untyped

  # Comment for attr_reader
  attr_reader x: untyped

  # Comment for attr_accessor
  attr_accessor y: untyped

  # Comment for attr_accessor
  attr_accessor z: untyped

  # Comment for attr_writer
  attr_writer a: untyped
end
    EOF
  end

  def test_toplevel
    parser = RB.new

    rb = <<-EOR
def hello
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
extension Object (Toplevel)
  def hello: () -> untyped
end
    EOF
  end

  def test_const
    parser = RB.new

    rb = <<-EOR
module Foo
  VERSION = '0.1.1'
  ::Hello::World = :foo
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
module Foo
end

Foo::VERSION: ::String

Hello::World: ::Symbol
    EOF
  end

  def test_literal_types
    parser = RB.new

    rb = <<-'EOR'
A = 1
B = 1.0
C = "hello#{21}"
D = :hello
E = nil
F = false
G = [1,2,3]
H = { id: 123 }
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
A: ::Integer

B: ::Float

C: ::String

D: ::Symbol

E: untyped?

F: bool

G: ::Array[untyped]

H: ::Hash[untyped, untyped]
    EOF
  end

  def test_argumentless_fcall
    parser = RB.new

    rb = <<-'EOR'
class C
  included do
    do_something
  end
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class C
end
    EOF
  end
end

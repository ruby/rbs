require "test_helper"

class Ruby::Signature::RbScaffoldTest < Minitest::Test
  RB = Ruby::Signature::Scaffold::RB

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
    yield 1, x: 3
    yield 1, 2, x: 3, y: 2
    yield 1, 2, 'hello' => world 
  end
end
    EOR

    parser.parse(rb)

    assert_write parser.decls, <<-EOF
class Hello
  def hello: (untyped a, ?untyped b, *untyped c, untyped d, e: untyped e, ?f: untyped f, **untyped g) { () -> untyped } -> untyped

  def self.world: () { (untyped, untyped, untyped, x: untyped, y: untyped) -> untyped } -> untyped
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
end

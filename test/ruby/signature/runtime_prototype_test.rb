require "test_helper"

class Ruby::Signature::RuntimePrototypeTest < Minitest::Test
  Runtime = Ruby::Signature::Prototype::Runtime

  include TestHelper

  module Foo
    include Enumerable
  end

  class Test < String
    include Foo

    NAME = "Hello"

    def foo(foo, bar=1, *baz, a, b:, c: nil, **d)
    end

    alias bar foo

    private

    def a()
    end

    def self.baz(&block)
    end
  end

  def test_1
    p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::*"])

    assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::Test < String
  include Foo

  def self.baz: () { (*untyped) -> untyped } -> untyped

  public

  alias bar foo

  def foo: (untyped foo, ?untyped bar, *untyped baz, untyped a, b: untyped, ?c: untyped, **untyped) -> untyped

  private

  def a: () -> untyped
end

Ruby::Signature::RuntimePrototypeTest::Test::NAME: String
    EOF
  end
end
